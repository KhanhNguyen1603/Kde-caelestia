pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.modules.nexus.common

PageBase {
    id: root

    isSubPage: true
    title: qsTr("Slideshow & Order")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ToggleRow {
            first: true
            text: qsTr("Wallpaper slideshow")
            subtext: qsTr("Automatically change wallpaper on a timer")
            checked: Config.background.slideshowEnabled
            onToggled: GlobalConfig.background.slideshowEnabled = checked
            enabled: Config.background.wallpaperEnabled
        }

        SliderRow {
            icon: ""
            label: qsTr("Slideshow interval")
            valueLabel: Math.max(1, Math.round(value * 60)) + " min"
            value: Config.background.slideshowInterval
            enabled: Config.background.slideshowEnabled && Config.background.wallpaperEnabled
            onMoved: v => GlobalConfig.background.slideshowInterval = v
        }

        ToggleRow {
            last: true
            text: qsTr("Random order")
            checked: Config.background.slideshowRandom
            onToggled: GlobalConfig.background.slideshowRandom = checked
            enabled: Config.background.slideshowEnabled && Config.background.wallpaperEnabled
        }
    }
}
