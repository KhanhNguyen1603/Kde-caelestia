pragma Singleton

import QtQuick
import Quickshell

// Icons pulled straight out of a window's own _NET_WM_ICON (XWayland) for apps
// that have no resolvable desktop entry or themed icon — Minecraft, most Steam
// games, launcher-spawned windows and so on.
//
// This lives in a singleton rather than on the Dock because the Dock is
// instantiated more than once (one per bar/screen) and the popouts are built
// separately again: a per-Dock map meant whichever instance synced last won,
// and an instance that never ran the extractor would clobber the populated map
// with an empty one. A singleton gives every Dock tile and every hover popup
// the same map and the same "already tried" bookkeeping.
Singleton {
    id: root

    // appClass -> extracted png path
    property var paths: ({})

    // appClass -> extraction already attempted (don't re-spawn the helper)
    property var tried: ({})

    // Kick off an extraction for a window class, at most once per class.
    function request(appClass: string, title: string): void {
        if (!appClass || root.tried[appClass])
            return;

        const t = root.tried;
        t[appClass] = true;
        root.tried = t;

        const helper = (Quickshell.env("HOME") || "") + "/.local/bin/caelestia-winicon.py";
        const cmd = ["sh", "-c", 'DISPLAY="${DISPLAY:-:0}" python3 "$0" --class "$1" --title "$2"', helper, appClass, title || ""];
        const qmlStr =
            "import QtQuick\n" +
            "import Quickshell.Io\n" +
            "Process {\n" +
            "    id: wp\n" +
            "    command: " + JSON.stringify(cmd) + "\n" +
            "    stdout: StdioCollector { onStreamFinished: root.register(" + JSON.stringify(appClass) + ", (text || \"\").trim(), wp); }\n" +
            "    onExited: code => { if (code !== 0) wp.destroy(); }\n" +
            "}";
        try {
            const o = Qt.createQmlObject(qmlStr, root, "winIconProc");
            o.running = true;
        } catch (e) {}
    }

    // Record a freshly extracted icon. Reassigning a copy is what notifies the
    // bindings that read paths[...] — mutating in place would not.
    function register(appClass: string, path: string, proc: var): void {
        if (path && path !== "") {
            const m = root.paths;
            m[appClass] = path;
            root.paths = Object.assign({}, m);
        }
        if (proc)
            proc.destroy();
    }

    // Resolve an icon for a dock entry, in the order the taskbar tile and the
    // hover popup must agree on: desktop entry icon, then extracted window
    // icon, then the window class as a themed-icon name.
    function sourceFor(entry: var, appClass: string, iconName: string): string {
        if (entry && entry.icon)
            return Quickshell.iconPath(entry.icon, "application-x-executable");
        const wp = root.paths[appClass];
        if (wp)
            return "file://" + wp;
        return Quickshell.iconPath(iconName, "application-x-executable");
    }
}
