pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.Internal
import Caelestia.Services
import qs.components.misc

Singleton {
    id: root

    readonly property var toplevels: ToplevelManager.toplevels
    // Workspaces mock: must support .values (used like a Map/iterable throughout the
    // codebase).  Provide sane defaults so optional-chaining paths do not crash.
    readonly property var workspaces: (() => {
        const ws = {
            "1": { id: 1, name: "1", windows: 0, lastIpcObject: null, monitor: 0,
                   toplevels: { values: [] }, workspace: { id: 1 } }
        };
        ws["1"].lastIpcObject = ws["1"];
        // Inject .values() and .values as both a function and a property for
        // compatibility — the codebase uses both forms.
        ws.values = Object.values(ws).filter(v => typeof v === "object" && v !== null && v.id !== undefined);
        ws.values.find = function(pred) { return Array.prototype.find.call(this, pred); };
        ws.values.filter = function(pred) { return Array.prototype.filter.call(this, pred); };
        ws.values.map = function(pred) { return Array.prototype.map.call(this, pred); };
        ws.values.some = function(pred) { return Array.prototype.some.call(this, pred); };
        return ws;
    })()
    property var monitorState: []
    property var _monitorCache: ({})

    // Referenced by focusedWorkspace/activeWsId below as the single mock
    // workspace id used throughout the KDE fallback bridge (there is no real
    // Hyprland workspace concept under KWin). This property was previously
    // never declared, so every read of root.mockActiveWs resolved to
    // undefined - causing "Cannot call method 'toString' of undefined" and
    // "Unable to assign [undefined] to ..." warnings wherever it was used.
    readonly property int mockActiveWs: 1
    
    readonly property var monitors: {
        let _ = root.monitorState;
        if (Object.keys(root._monitorCache).length === 0) {
            for (let i = 0; i < Quickshell.screens.length; i++) {
                let s = Quickshell.screens[i];
                let fallback = Qt.createQmlObject(`
                    import QtQuick
                    QtObject {
                        property int id: 0
                        property string name: ""
                        property bool focused: false
                        property real scale: 1.0
                        property real x: 0
                        property real y: 0
                        // activeWorkspace must include toplevels.values for
                        // optional-chaining code paths (e.g. hasFullscreen checks)
                        property var activeWorkspace: ({ id: 1, toplevels: { values: [] } })
                        property var specialWorkspace: ({ name: "", toplevels: { values: [] } })
                        property var lastIpcObject: null
                        Component.onCompleted: lastIpcObject = this
                    }
                `, root, "monitorMock");
                fallback.name = s.name;
                fallback.id = i;
                if (i === 0) fallback.focused = true;
                root._monitorCache[s.name] = fallback;
            }
        }
        // Inject .values so for-of loops and .some()/.find() on Hypr.monitors work.
        // The codebase expects monitors to behave like a Map/iterable.
        const cache = root._monitorCache;
        const vals = Object.values(cache).filter(v => typeof v === "object" && v !== null);
        cache.values = vals;
        cache.values.find = function(pred) { return Array.prototype.find.call(vals, pred); };
        cache.values.filter = function(pred) { return Array.prototype.filter.call(vals, pred); };
        cache.values.some = function(pred) { return Array.prototype.some.call(vals, pred); };
        cache.values.every = function(pred) { return Array.prototype.every.call(vals, pred); };
        return cache;
    }

    // Native Wayland/DBus state bindings are handled by Caelestia C++ services

    readonly property var activeToplevel: ToplevelManager.activeToplevel
    readonly property var focusedWorkspace: ({ id: root.mockActiveWs, name: root.mockActiveWs.toString() })
    readonly property var focusedMonitor: {
        let _ = root.monitorState;
        
        let targetName = "";
        if (typeof KWinActiveWindowBridge !== "undefined" && KWinActiveWindowBridge.activeOutputName) {
            targetName = KWinActiveWindowBridge.activeOutputName;
        }
        
        if (targetName !== "") {
            for (let key in root._monitorCache) {
                if (root._monitorCache[key].name === targetName) {
                    return root._monitorCache[key];
                }
            }
        }
        
        for (let key in root._monitorCache) {
            if (root._monitorCache[key].focused) {
                return root._monitorCache[key];
            }
        }
        
        let keys = Object.keys(root._monitorCache);
        if (keys.length > 0) return root._monitorCache[keys[0]];
        return null;
    }
    readonly property int activeWsId: focusedWorkspace?.id ?? root.mockActiveWs

    readonly property bool capsLock: false
    readonly property bool numLock: false
    readonly property string defaultKbLayout: "??"
    readonly property string kbLayoutFull: "Unknown"
    readonly property string kbLayout: "??"
    readonly property var kbMap: new Map()

    readonly property alias extras: extras
    readonly property alias options: extras.options
    readonly property alias devices: extras.devices

    property bool hadKeyboard
    property string lastSpecialWorkspace: ""

    signal configReloaded

    function dispatch(request: string): void {
        if (request.startsWith("workspace ")) {
            const ws = request.split(" ")[1];
            if (typeof KWinWorkspaceState !== "undefined") {
                KWinWorkspaceState.switchTo(ws);
            }
            return;
        }
        console.log("Unhandled dispatch: " + request);
    }

    function cycleSpecialWorkspace(direction: string): void {
        const openSpecials = workspaces.values.filter(w => w.name.startsWith("special:") && w.lastIpcObject.windows > 0);

        if (openSpecials.length === 0)
            return;

        const activeSpecial = focusedMonitor.lastIpcObject.specialWorkspace.name ?? "";

        if (!activeSpecial) {
            if (lastSpecialWorkspace) {
                const workspace = workspaces.values.find(w => w.name === lastSpecialWorkspace);
                if (workspace && workspace.lastIpcObject.windows > 0) {
                    dispatch(usingLua ? `hl.dsp.focus({ workspace = "${lastSpecialWorkspace}" })` : `workspace ${lastSpecialWorkspace}`);
                    return;
                }
            }
            dispatch(usingLua ? `hl.dsp.focus({ workspace = "${openSpecials[0].name}" })` : `workspace ${openSpecials[0].name}`);
            return;
        }

        const currentIndex = openSpecials.findIndex(w => w.name === activeSpecial);
        let nextIndex = 0;

        if (currentIndex !== -1) {
            if (direction === "next")
                nextIndex = (currentIndex + 1) % openSpecials.length;
            else
                nextIndex = (currentIndex - 1 + openSpecials.length) % openSpecials.length;
        }

        dispatch(usingLua ? `hl.dsp.focus({ workspace = "${openSpecials[nextIndex].name}" })` : `workspace ${openSpecials[nextIndex].name}`);
    }

    function monitorNames(): list<string> {
        let names = [];
        for (let key in root.monitors) {
            names.push(root.monitors[key].name);
        }
        return names;
    }

    function monitorFor(screen: ShellScreen): var {
        let cached = root._monitorCache[screen.name];
        if (!cached) {
            cached = Qt.createQmlObject(`
                import QtQuick
                QtObject {
                    property int id: 0
                    property string name: ""
                    property bool focused: false
                    property real scale: 1.0
                    property real x: 0
                    property real y: 0
                    property var activeWorkspace: ({ id: 1, toplevels: { values: [] } })
                    property var specialWorkspace: ({ name: "", toplevels: { values: [] } })
                    property var lastIpcObject: null
                    Component.onCompleted: lastIpcObject = this
                }
            `, root, "monitorMock");
            cached.name = screen.name;
            cached.id = Object.keys(root._monitorCache).length;
            cached.activeWorkspace = { id: root.mockActiveWs };
            cached.specialWorkspace = { name: "" };
            root._monitorCache[screen.name] = cached;
        }
        return cached;
    }

    function reloadDynamicConfs(): void {}

    Component.onCompleted: reloadDynamicConfs()

    onCapsLockChanged: {
        if (!GlobalConfig.utilities.toasts.capsLockChanged)
            return;

        if (capsLock)
            Toaster.toast(qsTr("Caps lock enabled"), qsTr("Caps lock is currently enabled"), "keyboard_capslock_badge");
        else
            Toaster.toast(qsTr("Caps lock disabled"), qsTr("Caps lock is currently disabled"), "keyboard_capslock");
    }

    onNumLockChanged: {
        if (!GlobalConfig.utilities.toasts.numLockChanged)
            return;

        if (numLock)
            Toaster.toast(qsTr("Num lock enabled"), qsTr("Num lock is currently enabled"), "looks_one");
        else
            Toaster.toast(qsTr("Num lock disabled"), qsTr("Num lock is currently disabled"), "timer_1");
    }

    onKbLayoutFullChanged: {
        if (hadKeyboard && GlobalConfig.utilities.toasts.kbLayoutChanged)
            Toaster.toast(qsTr("Keyboard layout changed"), qsTr("Layout changed to: %1").arg(kbLayoutFull), "keyboard");

        hadKeyboard = !!keyboard;
    }



    FileView {
        id: kbLayoutFile

        path: Quickshell.env("CAELESTIA_XKB_RULES_PATH") || "/usr/share/X11/xkb/rules/base.lst"
        onLoaded: {
            const layoutMatch = text().match(/! layout\n([\s\S]*?)\n\n/);
            if (layoutMatch) {
                const lines = layoutMatch[1].split("\n");
                for (const line of lines) {
                    if (!line.trim() || line.trim().startsWith("!"))
                        continue;

                    const match = line.match(/^\s*([a-z]{2,})\s+([a-zA-Z() ]+)$/);
                    if (match)
                        root.kbMap.set(match[2], match[1]);
                }
            }

            const variantMatch = text().match(/! variant\n([\s\S]*?)\n\n/);
            if (variantMatch) {
                const lines = variantMatch[1].split("\n");
                for (const line of lines) {
                    if (!line.trim() || line.trim().startsWith("!"))
                        continue;

                    const match = line.match(/^\s*([a-zA-Z0-9_-]+)\s+([a-z]{2,}): (.+)$/);
                    if (match)
                        root.kbMap.set(match[3], match[2]);
                }
            }
        }
    }

    IpcHandler {
        function refreshDevices(): void {
            extras.refreshDevices();
        }

        function cycleSpecialWorkspace(direction: string): void {
            root.cycleSpecialWorkspace(direction);
        }

        function listSpecialWorkspaces(): string {
            return root.workspaces.values.filter(w => w.name.startsWith("special:") && w.lastIpcObject.windows > 0).map(w => w.name).join("\n");
        }

        function getFocusedMonitor(): string {
            let m = root.focusedMonitor;
            if (!m) return "null";
            return JSON.stringify({
                id: m.id,
                name: m.name,
                focused: m.focused,
                activeWorkspace: m.activeWorkspace,
                specialWorkspace: m.specialWorkspace
            }, null, 2);
        }

        function listMonitors(): string {
            return root.monitorNames().join(", ");
        }

        target: "hypr"
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "refreshDevices"
        description: "Reload devices"
        onPressed: extras.refreshDevices()
        onReleased: extras.refreshDevices()
    }

    HyprExtras {
        id: extras
        usingLua: false
    }
}
