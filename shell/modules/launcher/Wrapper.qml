pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.modules.launcher.services

Item {
    id: root

    required property ShellScreen screen
    required property DrawerVisibilities visibilities
    required property var panels

    readonly property bool shouldBeActive: visibilities.launcher && Config.launcher.enabled

    // Building the launcher's content is the expensive part of opening it, and it
    // used to happen on every open — noticeably slow the first time and while a
    // game has the CPU busy. Worse, the window switcher commits on the Alt release
    // delivered to the search field, so anything that delays the field appearing
    // is a window in which a quick Alt+Tab leaves the switcher stuck open.
    //
    // Build it once and keep it: after the first open, and pre-emptively a few
    // seconds into the session so even that first Alt+Tab is instant.
    property bool contentBuilt: false

    Timer {
        interval: 5000
        running: !root.contentBuilt && Config.launcher.enabled
        repeat: false
        onTriggered: root.contentBuilt = true
    }

    readonly property real maxHeight: {
        let max = screen.height - Config.border.thickness * 2 + Tokens.padding.extraLarge;
        if (visibilities.dashboard)
            max -= panels.dashboard.nonAnimHeight;
        return max;
    }

    property real offsetScale: shouldBeActive ? 0 : 1

    onShouldBeActiveChanged: {
        if (shouldBeActive) {
            contentBuilt = true;
            implicitHeight = Qt.binding(() => content.implicitHeight);
        } else
            implicitHeight = implicitHeight; // Break binding during close anim
    }

    clip: Config.bar.position === "bottom"
    visible: offsetScale < 1
    anchors.bottomMargin: (Config.bar.position === "bottom" ? 0 : -implicitHeight - 5) * offsetScale
    height: Config.bar.position === "bottom" ? implicitHeight * (1 - offsetScale) : implicitHeight
    implicitHeight: content.implicitHeight
    implicitWidth: content.implicitWidth || 630 // Hard coded fallback for first open
    opacity: 1 - offsetScale

    Component.onCompleted: Qt.callLater(() => Apps) // Load apps on init

    Behavior on offsetScale {
        Anim {}
    }

    Loader {
        id: content

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        active: root.shouldBeActive || root.visible || root.contentBuilt
        asynchronous: !root.shouldBeActive

        sourceComponent: Component {
            Content {
                visibilities: root.visibilities
                panels: root.panels
                maxHeight: root.maxHeight
            }
        }
    }
}
