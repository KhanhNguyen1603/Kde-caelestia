pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components.controls as Controls
import qs.services
import qs.modules.nexus

Controls.Menu {
    id: root

    attachSideX: Controls.Menu.Right
    attachSideY: Controls.Menu.Bottom
    thisSideX: Controls.Menu.Left
    thisSideY: Controls.Menu.Top
    property string screenName: ""
    property var itemPool: ({})
    property var entryByKey: ({})
    property real perfMenuOpenStartedAt: 0

    Component {
        id: menuItemComp
        Controls.MenuItem {}
    }

    function defaultEntries() {
        return [
            { id: "toggle_desktop_icons", label: qsTr("Desktop Icons"), icon: "desktop_windows", action: "ToggleDesktopIcons", enabled: true, type: "default" },
            { id: "next_wallpaper", label: qsTr("Next Wallpaper"), icon: "skip_next", action: "Wallpapers.next()", enabled: true, type: "default" },
            { id: "wallpaper_style", label: qsTr("Wallpaper & style"), icon: "wallpaper", action: "WindowFactory.create()", enabled: true, type: "default" },
            { id: "system_settings", label: qsTr("System Settings"), icon: "settings", command: "systemsettings", enabled: true, type: "default" },
            { id: "open_terminal", label: qsTr("Open Terminal"), icon: "terminal", command: "terminal", enabled: true, type: "default" },
            { id: "add_shortcut", label: qsTr("Add Shortcut..."), icon: "add", action: "OpenRightClickMenu", enabled: true, type: "default" }
        ];
    }

    function cloneEntries(entries) {
        return JSON.parse(JSON.stringify(entries));
    }

    function executeEntryByKey(key) {
        let entry = root.entryByKey[key];
        if (!entry) return;

        if (entry.action) {
            if (entry.action === "Wallpapers.next()") Wallpapers.next();
            else if (entry.action === "Quickshell.reload()") Quickshell.reload();
            else if (entry.action === "WindowFactory.create()") WindowFactory.create();
            else if (entry.action === "ToggleDesktopIcons") {
                let newState = !GlobalConfig.background.desktopIconsEnabled;
                GlobalConfig.background.desktopIconsEnabled = newState;
                for (let i = 0; i < Quickshell.screens.length; i++) {
                    let sConf = GlobalConfig.forScreen(Quickshell.screens[i].name);
                    if (sConf) sConf.background.resetOption("desktopIconsEnabled");
                }
                GlobalConfig.save();
            } else if (entry.action === "OpenRightClickMenu") {
                let win = WindowFactory.create();
                win.nexus.nState.currentPageIdx = 0; // Wallpaper & Style
                win.nexus.nState.openSubPage(9); // Right Click Menu is index 9
            } else if (entry.action === "OpenTerminal") {
                Quickshell.execDetached([...GlobalConfig.general.apps.terminal]);
            }
        } else if (entry.command) {
            if (entry.command === "terminal") {
                Quickshell.execDetached([...GlobalConfig.general.apps.terminal]);
            } else {
                Quickshell.execDetached(typeof entry.command === "string" ? entry.command.split(" ") : entry.command);
            }
        }
    }

    function applyEntries(entries, sourceName) {
        const buildStartedAt = Date.now();
        const normalized = (!entries || entries.length === 0) ? defaultEntries() : cloneEntries(entries);
        const newArr = [];
        const nextEntryByKey = {};

        for (let i = 0; i < normalized.length; i++) {
            let entry = normalized[i];
            if (!entry.enabled) continue;

            let key = (entry.id && entry.id.length > 0) ? entry.id : ("idx_" + i);
            nextEntryByKey[key] = entry;

            let item = root.itemPool[key];
            if (!item) {
                item = menuItemComp.createObject(root);
                item.clicked.connect(() => root.executeEntryByKey(key));
                root.itemPool[key] = item;
            }

            item.text = entry.label;
            item.icon = entry.icon || "application-x-executable";
            newArr.push(item);
        }

        root.entryByKey = nextEntryByKey;
        root.dynamicModel = newArr;

        const buildMs = Date.now() - buildStartedAt;
        console.log("[perf][DesktopContextMenu] build model source=" + sourceName + " items=" + newArr.length + " ms=" + buildMs);

        if (root.perfMenuOpenStartedAt > 0) {
            const openMs = Date.now() - root.perfMenuOpenStartedAt;
            console.log("[perf][DesktopContextMenu] open latency ms=" + openMs + " source=" + sourceName);
            root.perfMenuOpenStartedAt = 0;
        }
    }

    function reloadMenu(forceDisk) {
        ContextMenuStore.ensureLoaded(forceDisk === true);
        if (ContextMenuStore.loaded) {
            root.applyEntries(ContextMenuStore.entries, forceDisk === true ? "store_disk" : "store_cache");
        }
    }

    Connections {
        target: ContextMenuStore

        function onEntriesChanged() {
            root.applyEntries(ContextMenuStore.entries, "store_update");
        }
    }

    onExpandedChanged: {
        if (expanded) {
            root.perfMenuOpenStartedAt = Date.now();
            reloadMenu(false);
        }
    }

    Component.onCompleted: reloadMenu(true)
}
