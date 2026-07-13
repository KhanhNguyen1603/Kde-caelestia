pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components.controls
import qs.modules.nexus.common
import qs.utils

PageBase {
    id: root

    isSubPage: true
    title: qsTr("Wallpaper Settings")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ToggleRow {
            first: true
            text: qsTr("Display wallpaper")
            checked: Config.background.wallpaperEnabled
            onToggled: GlobalConfig.background.wallpaperEnabled = checked
        }

        ToggleRow {
            text: qsTr("Desktop icons")
            checked: Config.background.desktopIconsEnabled
            onToggled: GlobalConfig.background.desktopIconsEnabled = checked
            enabled: Config.background.wallpaperEnabled
        }

        ToggleRow {
            text: Strings.localizeEnglishSpelling(qsTr("Recolour wallpaper"))
            subtext: Strings.localizeEnglishSpelling(qsTr("Tint the wallpaper to match static colour schemes"))
            checked: Config.background.wallpaperRecolor
            onToggled: GlobalConfig.background.wallpaperRecolor = checked
            enabled: Config.background.wallpaperEnabled
        }

        SliderRow {
            last: true
            icon: ""
            label: Strings.localizeEnglishSpelling(qsTr("Recolour strength"))
            valueLabel: Math.round(value * 100) + "%"
            value: Config.background.wallpaperRecolorStrength
            enabled: Config.background.wallpaperRecolor && Config.background.wallpaperEnabled
            onMoved: v => GlobalConfig.background.wallpaperRecolorStrength = v
        }
    }
}
