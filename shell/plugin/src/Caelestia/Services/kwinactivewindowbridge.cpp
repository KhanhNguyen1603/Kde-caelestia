#include "kwinactivewindowbridge.hpp"
#include <QCoreApplication>
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QTemporaryFile>
#include <QProcess>
#include <QtDBus/QDBusConnection>
#include <QtDBus/QDBusMessage>
#include <QtDBus/QDBusReply>

namespace caelestia::services {

KWinActiveWindowBridgeAdaptor::KWinActiveWindowBridgeAdaptor(QObject* parent)
    : QDBusAbstractAdaptor(parent) {}

void KWinActiveWindowBridgeAdaptor::notifyActiveWindow(
    const QString& uuid, const QString& title, const QString& appClass, const QString& activeOutputName, bool isFullscreen, bool isMaximized) {
    if (auto* bridge = qobject_cast<KWinActiveWindowBridge*>(parent())) {
        bridge->updateActiveWindow(uuid, title, appClass, activeOutputName, isFullscreen, isMaximized);
    }
}

void KWinActiveWindowBridgeAdaptor::notifyWindowList(const QString& windowsJson) {
    if (auto* bridge = qobject_cast<KWinActiveWindowBridge*>(parent())) {
        bridge->updateWindowList(windowsJson);
    }
}

static const QString kScriptSource = R"js(
const BUS = "dev.caelestia.KWinActiveWindow";
const PATH = "/dev/caelestia/KWinActiveWindow";
const IFACE = "dev.caelestia.KWinActiveWindow";

let currentActiveWindow = null;
let lastActiveUuid = null;
let lastFullscreen = null;
let lastMaximized = null;
let lastOut = null;
let lastTitle = null;

function notifyActiveWindowReal() {
    let window = workspace.activeWindow;
    let cursorScreen = workspace.screenAt(workspace.cursorPos);
    let out = cursorScreen ? cursorScreen.name : "";
    if (window && (window.resourceClass === "quickshell" || window.resourceClass === "plasmashell")) {
        return; // Ignore shell panels taking focus
    }
    
    if (!window) {
        if (lastActiveUuid !== null) {
            lastActiveUuid = null;
            callDBus(BUS, PATH, IFACE, "notifyActiveWindow", "", "", "", out, false, false);
        }
        return;
    }

    let uuid = window.internalId ? String(window.internalId) : "";
    let title = window.caption || "";
    let appClass = window.resourceClass || "";
    let isFullscreen = window.fullScreen ? true : false;
    let isMaximized = (window.maximizeMode === 3) ? true : false;

    if (lastActiveUuid === uuid && lastFullscreen === isFullscreen && lastMaximized === isMaximized && lastOut === out && lastTitle === title) {
        return;
    }

    lastActiveUuid = uuid;
    lastFullscreen = isFullscreen;
    lastMaximized = isMaximized;
    lastOut = out;
    lastTitle = title;

    callDBus(BUS, PATH, IFACE, "notifyActiveWindow", uuid, title, appClass, out, isFullscreen, isMaximized);
}

function onActiveWindowChanged() {
    let window = workspace.activeWindow;
    if (currentActiveWindow !== window) {
        if (currentActiveWindow) {
            try { currentActiveWindow.frameGeometryChanged.disconnect(notifyActiveWindowReal); } catch(e){}
            try { currentActiveWindow.fullScreenChanged.disconnect(notifyActiveWindowReal); } catch(e){}
            try { currentActiveWindow.maximizedChanged.disconnect(notifyActiveWindowReal); } catch(e){}
        }
        currentActiveWindow = window;
        if (currentActiveWindow) {
            try { currentActiveWindow.frameGeometryChanged.connect(notifyActiveWindowReal); } catch(e){}
            try { currentActiveWindow.fullScreenChanged.connect(notifyActiveWindowReal); } catch(e){}
            try { currentActiveWindow.maximizedChanged.connect(notifyActiveWindowReal); } catch(e){}
        }
    }
    notifyActiveWindowReal();
}

function notifyWindowList() {
    let wins = workspace.windowList();
    let arr = [];
    for (let i = 0; i < wins.length; ++i) {
        let w = wins[i];
        if (w.normalWindow) {
            let deskId = "";
            if (w.resourceClass === "quickshell") continue;
            if (w.desktops && w.desktops.length > 0) {
                let d = w.desktops[0];
                deskId = String(d.id || d.name || d);
            }
            arr.push({
                address: w.internalId ? String(w.internalId) : "",
                pid: w.pid || 0,
                title: w.caption || "",
                class: w.resourceClass || "",
                x: w.frameGeometry ? w.frameGeometry.x : w.x,
                y: w.frameGeometry ? w.frameGeometry.y : w.y,
                width: w.frameGeometry ? w.frameGeometry.width : w.width,
                height: w.frameGeometry ? w.frameGeometry.height : w.height,
                fullscreen: w.fullScreen ? true : false,
                minimized: w.minimized ? true : false,
                floating: !w.tile,
                workspace: { id: deskId }
            });
        }
    }
    callDBus(BUS, PATH, IFACE, "notifyWindowList", JSON.stringify(arr));
}

workspace.windowActivated.connect(onActiveWindowChanged);

function onWindowAdded(window) {
    if (window && window.normalWindow) {
        try { window.minimizedChanged.connect(notifyWindowList); } catch(e){}
    }
    notifyWindowList();
}

workspace.windowAdded.connect(onWindowAdded);
workspace.windowRemoved.connect(notifyWindowList);

// Initial push
let initialWins = workspace.windowList();
for (let i = 0; i < initialWins.length; ++i) {
    if (initialWins[i].normalWindow) {
        try { initialWins[i].minimizedChanged.connect(notifyWindowList); } catch(e){}
    }
}
onActiveWindowChanged();
notifyWindowList();
)js";

KWinActiveWindowBridge::KWinActiveWindowBridge(QObject* parent)
    : QObject(parent) {
    new KWinActiveWindowBridgeAdaptor(this);

    QDBusConnection bus = QDBusConnection::sessionBus();
    bus.registerObject("/dev/caelestia/KWinActiveWindow", this,
        QDBusConnection::ExportAllSlots | QDBusConnection::ExportAllSignals | QDBusConnection::ExportAllProperties |
            QDBusConnection::ExportAdaptors);
    bus.registerService("dev.caelestia.KWinActiveWindow");

    injectKWinScript();
}

KWinActiveWindowBridge::~KWinActiveWindowBridge() {
    if (!m_scriptName.isEmpty()) {
        QDBusMessage msg =
            QDBusMessage::createMethodCall("org.kde.KWin", "/Scripting", "org.kde.kwin.Scripting", "unloadScript");
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

void KWinActiveWindowBridge::setActiveOutputName(const QString& outputName) {
    if (m_activeOutputName != outputName) {
        m_activeOutputName = outputName;
        emit activeWindowChanged();

        QString runtimeDir = qEnvironmentVariable("XDG_RUNTIME_DIR", "/tmp");
        QFile f(runtimeDir + "/qs_kwin_active_output.txt");
        if (f.open(QIODevice::WriteOnly)) {
            f.write(outputName.toUtf8());
            f.close();
        }
    }
}

void KWinActiveWindowBridge::updateActiveWindow(
    const QString& uuid, const QString& title, const QString& appClass, const QString& activeOutputName, bool isFullscreen, bool isMaximized) {
    m_activeWindow = QVariantMap{ { "address", uuid }, { "title", title }, { "class", appClass }, { "fullscreen", isFullscreen }, { "maximized", isMaximized } };
    if (m_activeOutputName != activeOutputName) {
        m_activeOutputName = activeOutputName;
        QString runtimeDir = qEnvironmentVariable("XDG_RUNTIME_DIR", "/tmp");
        QFile f(runtimeDir + "/qs_kwin_active_output.txt");
        if (f.open(QIODevice::WriteOnly)) {
            f.write(activeOutputName.toUtf8());
            f.close();
        }
    }
    emit activeWindowChanged();
}

QVariantList KWinActiveWindowBridge::windowList() const {
    return m_windowList;
}

void KWinActiveWindowBridge::executeKWinScriptAction(const QString& scriptBody) {
    QString scriptName = "caelestia-kwin-action-" + QString::number(QCoreApplication::applicationPid()) + "-" +
                         QString::number(QDateTime::currentMSecsSinceEpoch());
    QString fileName = QDir::tempPath() + "/" + scriptName + ".js";
    QFile tempFile(fileName);
    if (!tempFile.open(QIODevice::WriteOnly)) {
        return;
    }
    tempFile.write(scriptBody.toUtf8());
    tempFile.close();

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
        bus.call(unloadMsg, QDBus::NoBlock);
    } else {
        qWarning() << "Failed to load script:" << reply.error().message();
    }
    
    QFile::remove(fileName);
}

void KWinActiveWindowBridge::runArbitraryScript(const QString& script) {
    executeKWinScriptAction(script);
}

void KWinActiveWindowBridge::focusWindow(const QString& address) {
    QString script = QString(R"(
        let wins = workspace.windowList();
        for (let i = 0; i < wins.length; ++i) {
            if (wins[i].internalId && String(wins[i].internalId) === "%1") {
                wins[i].minimized = false;
                workspace.activeWindow = wins[i];
                break;
            }
        }
    )").arg(address);
    executeKWinScriptAction(script);
}

void KWinActiveWindowBridge::closeWindow(const QString& address) {
    QString script = QString(R"(
        let wins = workspace.windowList();
        for (let i = 0; i < wins.length; ++i) {
            if (wins[i].internalId && String(wins[i].internalId) === "%1") {
                wins[i].closeWindow();
                break;
            }
        }
    )").arg(address);
    executeKWinScriptAction(script);
}

void KWinActiveWindowBridge::minimizeWindow(const QString& address) {
    QString script = QString(R"(
        let wins = workspace.windowList();
        for (let i = 0; i < wins.length; ++i) {
            if (wins[i].internalId && String(wins[i].internalId) === "%1") {
                wins[i].minimized = true;
                break;
            }
        }
    )").arg(address);
    executeKWinScriptAction(script);
}

void KWinActiveWindowBridge::maximizeWindow(const QString& address, bool horz, bool vert) {
    QString script = QString(R"(
        let wins = workspace.windowList();
        for (let i = 0; i < wins.length; ++i) {
            if (wins[i].internalId && String(wins[i].internalId) === "%1") {
                wins[i].setMaximize(%2, %3);
                break;
            }
        }
    )").arg(address).arg(vert ? "true" : "false").arg(horz ? "true" : "false");
    executeKWinScriptAction(script);
}

void KWinActiveWindowBridge::raiseWindow(const QString& address) {
    QString script = QString(R"(
        let wins = workspace.windowList();
        for (let i = 0; i < wins.length; ++i) {
            if (wins[i].internalId && String(wins[i].internalId) === "%1") {
                workspace.raiseWindow(wins[i]);
                break;
            }
        }
    )").arg(address);
    executeKWinScriptAction(script);
}

void KWinActiveWindowBridge::moveWindow(const QString& address, int x, int y) {
    QString script = QString(R"(
        let wins = workspace.windowList();
        for (let i = 0; i < wins.length; ++i) {
            if (wins[i].internalId && String(wins[i].internalId) === "%1") {
                let q = Object.assign({}, wins[i].frameGeometry);
                q.x = %2;
                q.y = %3;
                wins[i].frameGeometry = q;
                break;
            }
        }
    )").arg(address).arg(x).arg(y);
    executeKWinScriptAction(script);
}

void KWinActiveWindowBridge::resizeWindow(const QString& address, int width, int height) {
    QString script = QString(R"(
        let wins = workspace.windowList();
        for (let i = 0; i < wins.length; ++i) {
            if (wins[i].internalId && String(wins[i].internalId) === "%1") {
                let q = Object.assign({}, wins[i].frameGeometry);
                q.width = %2;
                q.height = %3;
                wins[i].frameGeometry = q;
                break;
            }
        }
    )").arg(address).arg(width).arg(height);
    executeKWinScriptAction(script);
}

void KWinActiveWindowBridge::setWindowProperty(const QString& address, const QString& property, bool enable) {
    QString kwinProp;
    if (property == "above") kwinProp = "keepAbove";
    else if (property == "below") kwinProp = "keepBelow";
    else if (property == "skip_taskbar") kwinProp = "skipTaskbar";
    else if (property == "skip_pager") kwinProp = "skipPager";
    else if (property == "fullscreen") kwinProp = "fullScreen";
    else if (property == "shaded") kwinProp = "shade";
    else if (property == "demands_attention") kwinProp = "demandsAttention";
    else if (property == "no_border") kwinProp = "noBorder";
    else if (property == "minimized") kwinProp = "minimized";
    else return;

    QString script = QString(R"(
        let wins = workspace.windowList();
        for (let i = 0; i < wins.length; ++i) {
            if (wins[i].internalId && String(wins[i].internalId) === "%1") {
                wins[i].%2 = %3;
                break;
            }
        }
    )").arg(address).arg(kwinProp).arg(enable ? "true" : "false");
    executeKWinScriptAction(script);
}

void KWinActiveWindowBridge::setWindowDesktop(const QString& address, int desktopId) {
    QString script = QString(R"(
        let wins = workspace.windowList();
        for (let i = 0; i < wins.length; ++i) {
            if (wins[i].internalId && String(wins[i].internalId) === "%1") {
                let id = %2;
                if (id == -1) {
                    wins[i].desktops = [workspace.currentDesktop];
                } else if (id == -2) {
                    wins[i].onAllDesktops = true;
                } else {
                    let d = workspace.desktops.find((d) => d.x11DesktopNumber == id);
                    if (d) wins[i].desktops = [d];
                }
                break;
            }
        }
    )").arg(address).arg(desktopId);
    executeKWinScriptAction(script);
}

void KWinActiveWindowBridge::setDesktop(int desktopId) {
    QString script = QString(R"(
        let id = %1;
        let d = workspace.desktops.find((d) => d.x11DesktopNumber == id);
        if (d) workspace.currentDesktop = d;
    )").arg(desktopId);
    executeKWinScriptAction(script);
}

void KWinActiveWindowBridge::updateWindowList(const QString& windowsJson) {
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
    m_scriptName = "caelestia-active-window-" + QString::number(QCoreApplication::applicationPid()) + "-" +
                   QString::number(QDateTime::currentMSecsSinceEpoch());

    QString scriptPath = QDir::tempPath() + "/caelestia-kwin-bridge.js";
    QFile f(scriptPath);
    if (f.open(QIODevice::WriteOnly)) {
        f.write(kScriptSource.toUtf8());
        f.close();
    }

    QDBusConnection bus = QDBusConnection::sessionBus();

    QDBusMessage loadMsg =
        QDBusMessage::createMethodCall("org.kde.KWin", "/Scripting", "org.kde.kwin.Scripting", "loadScript");
    loadMsg << scriptPath << m_scriptName;

    QDBusReply<int> reply = bus.call(loadMsg);
    if (reply.isValid()) {
        int scriptId = reply.value();
        QDBusMessage runMsg = QDBusMessage::createMethodCall(
            "org.kde.KWin", QString("/Scripting/Script%1").arg(scriptId), "org.kde.kwin.Script", "run");
        bus.call(runMsg);
    } else {
        qWarning() << "Failed to inject KWin active window script:" << reply.error().message();
    }
}

} // namespace caelestia::services
