pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.components
import qs.components.effects
import qs.services
import qs.modules.drawers.blur

Window {
    id: root

    color: "black"

    readonly property real lockHeight: Math.min(root.screen?.width ?? 0, root.screen?.height ?? 0)
    readonly property bool isPortrait: (root.screen?.width ?? 0) < (root.screen?.height ?? 0)

    contentItem.Config.screen: screen.name
    contentItem.Tokens.screen: screen.name

    width: root.screen?.width ?? 1920
    height: root.screen?.height ?? 1080
    visibility: Window.FullScreen



    Loader {
        id: wallpaperLoader
        anchors.fill: parent
        asynchronous: true
        active: true

        source: "../background/Wallpaper.qml"
        
        onLoaded: {
            item.screen = root.screen;
        }
    }

    Item {
        id: lockContent

        readonly property int size: lockIcon.implicitHeight + Tokens.padding.large * 4
        readonly property int radius: size / 4 * Tokens.rounding.scale

        readonly property real lockLong: root.lockHeight * Tokens.sizes.lock.heightMult * Tokens.sizes.lock.ratio
        readonly property real lockShort: root.lockHeight * Tokens.sizes.lock.heightMult

        anchors.centerIn: parent
        implicitWidth: root.isPortrait ? lockShort : lockLong
        implicitHeight: root.isPortrait ? lockLong : lockShort

        Elevation {
            anchors.fill: lockBg
            radius: lockBg.radius
            level: 2
        }

        ShaderEffectSource {
            id: bgSource
            anchors.fill: lockBg
            sourceItem: wallpaperLoader
            sourceRect: Qt.rect(lockContent.x, lockContent.y, lockContent.width, lockContent.height)
            
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blurMax: 64
                blur: 1.0
                maskEnabled: true
                maskSource: ShaderEffectSource {
                    sourceItem: Rectangle {
                        width: lockBg.width
                        height: lockBg.height
                        radius: lockBg.radius
                    }
                }
            }
        }

        StyledRect {
            id: lockBg

            anchors.fill: parent
            color: Colours.palette.m3surface
            radius: lockContent.Tokens.rounding.extraLarge * 1.5
            opacity: Colours.transparency.enabled ? Colours.transparency.base : 1
        }

        MaterialIcon {
            id: lockIcon

            anchors.centerIn: parent
            text: "lock"
            fontStyle: Tokens.font.icon.builders.extraLarge.scale(4).weight(Font.Bold).build()
            opacity: 0 // Hide lock icon since KDE has its own
        }

        BackgroundContent {
            id: content

            isPortrait: root.isPortrait
            lockHeight: root.lockHeight

            anchors.centerIn: parent
            width: lockContent.implicitWidth - Tokens.padding.extraLargeIncreased
            height: lockContent.implicitHeight - Tokens.padding.extraLargeIncreased

            // We mock the lock object because Content expects it.
            // Since we don't have WlSessionLock, we just pass an empty stub.
            lock: QtObject {
                property bool locked: true
            }
        }
    }
}
