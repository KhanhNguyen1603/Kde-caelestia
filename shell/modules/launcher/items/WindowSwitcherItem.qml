import QtQuick
import Quickshell
import Quickshell.Widgets
import org.kde.pipewire as Pipewire
import Caelestia.Services
import Caelestia
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.components.images
import qs.components.controls
import qs.services

Item {
    id: root

    required property var modelData
    required property var list

    function clicked(): void {
        KWinActiveWindowBridge.focusWindow(root.modelData.address);
        root.list.visibilities.launcher = false;
    }

    Component.onCompleted: {
        scale = Qt.binding(() => PathView.isCurrentItem ? 1 : PathView.onPath ? 0.8 : 0);
        opacity = Qt.binding(() => PathView.onPath ? 1 : 0);
    }

    scale: 0.5
    opacity: 0
    z: PathView.z ?? 0

    implicitWidth: previewBox.width + Tokens.padding.largeIncreased * 2
    implicitHeight: previewBox.height + label.height + Tokens.spacing.small / 2 + Tokens.padding.large + Tokens.padding.medium

    StateLayer {
        radius: Tokens.rounding.medium
        onClicked: root.clicked()
    }

    StyledRect {
        id: shadowRect

        anchors.fill: previewBox
        radius: previewBox.radius
        color: Colours.layer(Colours.palette.m3surfaceContainerHighest, root.PathView.isCurrentItem ? 1 : 0)
        opacity: root.PathView.isCurrentItem ? 1 : 0

        Behavior on opacity {
            Anim {}
        }
    }

    StyledClippingRect {
        id: previewBox

        anchors.horizontalCenter: parent.horizontalCenter
        y: Tokens.padding.large
        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.medium

        readonly property real windowAspect: {
            const size = root.modelData?.size;
            if (size && size.length >= 2) {
                const w = size[0];
                const h = size[1];
                if (w > 0 && h > 0) return w / h;
            }
            return 16.0 / 9.0;
        }

        implicitWidth: Tokens.sizes.launcher.windowSwitcherWidth
        implicitHeight: implicitWidth / 16 * 9

        // Asking KWin for a live PipeWire feed is the expensive part of showing the
        // switcher, and it used to happen for every window at once, 20ms after the
        // list was built — which is exactly when the machine is busiest, and the
        // reason the switcher stutters on first open while a game is running.
        // Only previews actually on the path ask for a feed, and only once they
        // have settled, so cycling quickly past a window no longer starts a stream
        // that is dropped a frame later.
        readonly property bool previewWanted: root.PathView.onPath

        Timer {
            id: settleTimer
            property bool settled: false
            interval: 120
            running: previewBox.previewWanted && !settled
            repeat: false
            onTriggered: settled = true
        }

        Loader {
            id: screencastLoader
            active: previewBox.previewWanted && settleTimer.settled
            sourceComponent: WindowScreencastRequest {
                uuid: root.modelData?.address ?? ""
            }
        }

        readonly property int serial: screencastLoader.item ? screencastLoader.item.objectSerial : 0

        IconImage {
            anchors.centerIn: parent
            implicitSize: previewBox.height * 0.5
            asynchronous: true
            visible: previewBox.serial === 0
            source: root.modelData?.iconName ? Icons.getAppIcon(root.modelData.iconName, "image-missing") : ""
        }

        Pipewire.PipeWireSourceItem {
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height * previewBox.windowAspect)
            height: Math.min(parent.height, parent.width / previewBox.windowAspect)
            visible: previewBox.serial !== 0
            objectSerial: previewBox.serial
        }
    }

    StyledText {
        id: label

        anchors.top: previewBox.bottom
        anchors.topMargin: Tokens.spacing.small / 2
        anchors.horizontalCenter: parent.horizontalCenter

        width: previewBox.width - Tokens.padding.medium * 2
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        renderType: Text.QtRendering
        text: root.modelData?.title ?? ""
        font: Tokens.font.body.medium
    }

    Behavior on scale {
        Anim {}
    }

    Behavior on opacity {
        Anim {}
    }
}
