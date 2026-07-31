pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.modules.nexus.common

PageBase {
    id: root
    
    title: qsTr("Plugins")

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Tokens.spacing.medium

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "🧩"
            font: Tokens.font.icon.extraExtraLarge
            color: Colours.palette.m3onSurfaceVariant
            animate: true
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Plugins are coming soon")
            font: Tokens.font.headline.small
            color: Colours.palette.m3onSurface
            animate: true
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("A plugin framework is planned for v2.3.0.\nStay tuned for the ability to extend your shell with community plugins.")
            font: Tokens.font.body.medium
            color: Colours.palette.m3onSurfaceVariant
            horizontalAlignment: Text.AlignHCenter
            animate: true
        }
    }
}
