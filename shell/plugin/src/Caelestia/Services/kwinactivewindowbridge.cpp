#include "kwinactivewindowbridge.hpp"
#include <QtDBus/QDBusConnection>
#include <QtDBus/QDBusMessage>
#include <QtDBus/QDBusReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QCoreApplication>
#include <QTemporaryFile>
#include <QDateTime>
#include <QDir>
#include <QDebug>

namespace caelestia::services {

KWinActiveWindowBridgeAdaptor::KWinActiveWindowBridgeAdaptor(QObject *parent)
    : QDBusAbstractAdaptor(parent)
{
}

void KWinActiveWindowBridgeAdaptor::notifyActiveWindow(const QString &uuid, const QString &title, const QString &appClass, const QString &activeOutputName) {
    if (auto* bridge = qobject_cast<KWinActiveWindowBridge*>(parent())) {
        bridge->updateActiveWindow(uuid, title, appClass, activeOutputName);
    }
}

void KWinActiveWindowBridgeAdaptor::notifyWindowList(const QString &windowsJson) {
    if (auto* bridge = qobject_cast<KWinActiveWindowBridge*>(parent())) {
        bridge->updateWindowList(windowsJson);
    }
}


static const QString kScriptSource = R"js(
const BUS = "dev.caelestia.KWinActiveWindow";
const PATH = "/dev/caelestia/KWinActiveWindow";
const IFACE = "dev.caelestia.KWinActiveWindow";

function notifyActiveWindow() {
    let window = workspace.activeWindow;
    let out = workspace.activeScreen ? workspace.activeScreen.name : "";
    if (!window) {
        callDBus(BUS, PATH, IFACE, "notifyActiveWindow", "", "", "", out);
        return;
    }
    
    let uuid = window.internalId ? String(window.internalId) : "";
    let title = window.caption || "";
    let appClass = window.resourceClass || "";
    callDBus(BUS, PATH, IFACE, "notifyActiveWindow", uuid, title, appClass, out);
}

function notifyWindowList() {
    let wins = workspace.windowList();
    let arr = [];
    for (let i = 0; i < wins.length; ++i) {
        let w = wins[i];
        if (w.normalWindow) {
            let deskId = "";
            if (w.desktops && w.desktops.length > 0) {
                let d = w.desktops[0];
                deskId = String(d.id || d.name || d);
            }
            arr.push({
                address: w.internalId ? String(w.internalId) : "",
                title: w.caption || "",
                class: w.resourceClass || "",
                x: w.frameGeometry ? w.frameGeometry.x : w.x,
                y: w.frameGeometry ? w.frameGeometry.y : w.y,
                width: w.frameGeometry ? w.frameGeometry.width : w.width,
                height: w.frameGeometry ? w.frameGeometry.height : w.height,
                fullscreen: w.fullScreen ? true : false,
                floating: !w.tile,
                workspace: { id: deskId }
            });
        }
    }
    callDBus(BUS, PATH, IFACE, "notifyWindowList", JSON.stringify(arr));
}

workspace.windowActivated.connect(notifyActiveWindow);
workspace.windowAdded.connect(notifyWindowList);
workspace.windowRemoved.connect(notifyWindowList);

// Initial push
notifyActiveWindow();
notifyWindowList();
)js";

KWinActiveWindowBridge::KWinActiveWindowBridge(QObject *parent) : QObject(parent) {
    new KWinActiveWindowBridgeAdaptor(this);
    
    QDBusConnection bus = QDBusConnection::sessionBus();
    bus.registerObject("/dev/caelestia/KWinActiveWindow", this);
    bus.registerService("dev.caelestia.KWinActiveWindow");
    
    injectKWinScript();
}

KWinActiveWindowBridge::~KWinActiveWindowBridge() {
    if (!m_scriptName.isEmpty()) {
        QDBusMessage msg = QDBusMessage::createMethodCall("org.kde.KWin", "/Scripting", "org.kde.kwin.Scripting", "unloadScript");
        msg << m_scriptName;
        QDBusConnection::sessionBus().call(msg, QDBus::NoBlock);
    }
}

QVariantMap KWinActiveWindowBridge::activeWindow() const {
    return m_activeWindow;
}

QString KWinActiveWindowBridge::activeOutputName() const {
    return m_activeOutputName;
}

void KWinActiveWindowBridge::updateActiveWindow(const QString &uuid, const QString &title, const QString &appClass, const QString &activeOutputName) {
    m_activeWindow = QVariantMap{
        {"address", uuid},
        {"title", title},
        {"class", appClass}
    };
    m_activeOutputName = activeOutputName;
    emit activeWindowChanged();
}

QVariantList KWinActiveWindowBridge::windowList() const {
    return m_windowList;
}

void KWinActiveWindowBridge::focusWindow(const QString &address) {
    QTemporaryFile *tempFile = new QTemporaryFile(QDir::tempPath() + "/caelestia-kwin-focus-XXXXXX.js", this);
    if (!tempFile->open()) {
        delete tempFile;
        return;
    }
    
    QString scriptSource = QString(R"(
        let wins = workspace.windowList();
        for (let i = 0; i < wins.length; ++i) {
            if (wins[i].internalId && String(wins[i].internalId) === "%1") {
                workspace.activeWindow = wins[i];
                break;
            }
        }
    )").arg(address);
    
    tempFile->write(scriptSource.toUtf8());
    QString fileName = tempFile->fileName();
    tempFile->close();

    QString scriptName = "caelestia-focus-" + QString::number(QCoreApplication::applicationPid()) + "-" + QString::number(QDateTime::currentMSecsSinceEpoch());
    
    QDBusConnection bus = QDBusConnection::sessionBus();
    QDBusMessage loadMsg = QDBusMessage::createMethodCall("org.kde.KWin", "/Scripting", "org.kde.kwin.Scripting", "loadScript");
    loadMsg << fileName << scriptName;
    
    QDBusReply<int> reply = bus.call(loadMsg);
    if (reply.isValid()) {
        int scriptId = reply.value();
        QDBusMessage runMsg = QDBusMessage::createMethodCall("org.kde.KWin", QString("/Scripting/Script%1").arg(scriptId), "org.kde.kwin.Script", "run");
        bus.call(runMsg);
        
        QDBusMessage unloadMsg = QDBusMessage::createMethodCall("org.kde.KWin", "/Scripting", "org.kde.kwin.Scripting", "unloadScript");
        unloadMsg << scriptName;
        bus.asyncCall(unloadMsg); // Clean up immediately after starting
    }
    
    tempFile->deleteLater();
}

void KWinActiveWindowBridge::updateWindowList(const QString &windowsJson) {
    QJsonDocument doc = QJsonDocument::fromJson(windowsJson.toUtf8());
    if (doc.isArray()) {
        m_windowList = doc.array().toVariantList();
        emit windowListChanged();
    }

    // Optionally update a file for backwards compatibility with hyprlandstate.cpp
    QString runtimeDir = qEnvironmentVariable("XDG_RUNTIME_DIR", "/tmp");
    QFile f(runtimeDir + "/qs_kwin_windows.json");
    if (f.open(QIODevice::WriteOnly)) {
        f.write(windowsJson.toUtf8());
        f.close();
    }
}

void KWinActiveWindowBridge::injectKWinScript() {
    m_scriptName = "caelestia-active-window-" + QString::number(QCoreApplication::applicationPid()) + "-" + QString::number(QDateTime::currentMSecsSinceEpoch());
    
    QString scriptPath = QDir::tempPath() + "/caelestia-kwin-bridge.js";
    QFile f(scriptPath);
    if (f.open(QIODevice::WriteOnly)) {
        f.write(kScriptSource.toUtf8());
        f.close();
    }
    
    QDBusConnection bus = QDBusConnection::sessionBus();
    
    QDBusMessage loadMsg = QDBusMessage::createMethodCall("org.kde.KWin", "/Scripting", "org.kde.kwin.Scripting", "loadScript");
    loadMsg << scriptPath << m_scriptName;
    
    QDBusReply<int> reply = bus.call(loadMsg);
    if (reply.isValid()) {
        int scriptId = reply.value();
        QDBusMessage runMsg = QDBusMessage::createMethodCall("org.kde.KWin", QString("/Scripting/Script%1").arg(scriptId), "org.kde.kwin.Script", "run");
        bus.call(runMsg);
    } else {
        qWarning() << "Failed to inject KWin active window script:" << reply.error().message();
    }
}

} // namespace caelestia::services
