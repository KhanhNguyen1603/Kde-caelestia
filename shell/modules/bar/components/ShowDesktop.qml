pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    implicitWidth: icon.implicitHeight + Tokens.padding.small
    implicitHeight: icon.implicitHeight

    property bool showingDesktop: false

    property var minimizedWindowIds: []

    function runKwinScript(script: string): void {
        Quickshell.execDetached(["bash", "-c",
            "echo " + JSON.stringify(script) + " > /tmp/qs-kwin.js && " +
            "qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript /tmp/qs-kwin.js >/dev/null 2>&1 && " +
            "qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.start"
        ]);
    }

    StateLayer {
        anchors.fill: undefined
        anchors.centerIn: parent
        implicitWidth: implicitHeight
        implicitHeight: icon.implicitHeight + Tokens.padding.small
        radius: Tokens.rounding.full
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!root.showingDesktop) {
                const toRestore = [];
                const wins = HyprlandData.windowList;
                for (let i = 0; i < wins.length; i++) {
                    const w = wins[i];
                    if (!w.minimized && !w.skipTaskbar) {
                        toRestore.push(w.address);
                    }
                }
                root.minimizedWindowIds = toRestore;

                let script = "var wins = (typeof workspace.windowList === 'function') ? workspace.windowList() : workspace.clientList();" +
                    "wins.forEach(function(w) { if (!w.skipTaskbar && !w.desktopWindow && !w.minimized) { w.minimized = true; } });";
                root.runKwinScript(script);
                root.showingDesktop = true;
            } else {
                let targets = JSON.stringify(root.minimizedWindowIds);
                let script = "var targets = " + targets + ";" +
                    "var wins = (typeof workspace.windowList === 'function') ? workspace.windowList() : workspace.clientList();" +
                    "wins.forEach(function(w) { " +
                    "  if (w.minimized && !w.skipTaskbar && w.internalId && targets.indexOf(w.internalId.toString()) !== -1) { " +
                    "    w.minimized = false; " +
                    "  } " +
                    "});";
                root.runKwinScript(script);
                root.minimizedWindowIds = [];
                root.showingDesktop = false;
            }
        }
    }

    MaterialIcon {
        id: icon

        anchors.centerIn: parent

        text: root.showingDesktop ? "flip_to_front" : "crop_din"
        color: root.showingDesktop ? Colours.palette.m3primary : Colours.palette.m3tertiary
        fontStyle: Tokens.font.icon.builders.small.weight(Font.Bold).build()
    }
}
