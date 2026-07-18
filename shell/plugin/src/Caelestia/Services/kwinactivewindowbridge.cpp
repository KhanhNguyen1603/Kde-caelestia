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
            arr.push({
                address: w.internalId ? String(w.internalId) : "",
                title: w.caption || "",
                class: w.resourceClass || ""
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

void KWinActiveWindowBridge::updateWindowList(const QString &windowsJson) {
    // Optionally update a file for backwards compatibility with hyprlandstate.cpp
    QString runtimeDir = qEnvironmentVariable("XDG_RUNTIME_DIR", "/tmp");
    QFile f(runtimeDir + "/qs_kwin_windows.json");
    if (f.open(QIODevice::WriteOnly)) {
        f.write(windowsJson.toUtf8());
        f.close();
    }
}

void KWinActiveWindowBridge::injectKWinScript() {
    QTemporaryFile tempFile(QDir::tempPath() + "/caelestia-kwin-XXXXXX.js");
    tempFile.setAutoRemove(false);
    if (!tempFile.open()) return;
    tempFile.write(kScriptSource.toUtf8());
    QString fileName = tempFile.fileName();
    tempFile.close();
    
    m_scriptName = "caelestia-active-window-" + QString::number(QCoreApplication::applicationPid()) + "-" + QString::number(QDateTime::currentMSecsSinceEpoch());
    
    QDBusConnection bus = QDBusConnection::sessionBus();
    QDBusMessage loadMsg = QDBusMessage::createMethodCall("org.kde.KWin", "/Scripting", "org.kde.kwin.Scripting", "loadScript");
    loadMsg << fileName << m_scriptName;
    
    QDBusReply<int> reply = bus.call(loadMsg);
    if (reply.isValid()) {
        QDBusMessage startMsg = QDBusMessage::createMethodCall("org.kde.KWin", "/Scripting", "org.kde.kwin.Scripting", "start");
        startMsg << m_scriptName;
        bus.call(startMsg);
    } else {
        qWarning() << "Failed to inject KWin active window script:" << reply.error().message();
    }
}

} // namespace caelestia::services
