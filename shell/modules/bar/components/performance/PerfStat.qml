import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services

StyledRect {
    id: root

    required property string icon
    required property string valueText
    property color accent: Colours.palette.m3primary
    property real value: NaN
    property color textColor: Colours.palette.m3onSurface
    property color iconColor: accent
    property real widthFactor: 2.35
    property string maxText: "100%"

    readonly property bool isHorizontal: Config.bar.position === "top" || Config.bar.position === "bottom"
    readonly property int barThickness: Math.round(Tokens.sizes.bar.innerWidth * Math.max(0.6, !isNaN(Config.bar.scale) ? Config.bar.scale : 1.0))
    readonly property real progress: isNaN(value) ? 0 : Math.max(0, Math.min(1, value))
    readonly property int hPadding: Tokens.padding.medium
    readonly property int vPadding: Tokens.padding.extraSmall
    readonly property int trackThickness: Math.max(4, Math.round(Tokens.padding.extraSmall * 0.8))
    readonly property int trackInset: Tokens.padding.medium

    color: Colours.tPalette.m3surfaceContainerHigh
    radius: Tokens.rounding.full
    clip: true

    StyledText {
        id: dummyText
        text: root.maxText
        font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
        visible: false
    }

    implicitWidth: isHorizontal ? Math.max(contentRow.implicitWidth + hPadding * 2, Math.round(barThickness * widthFactor)) : barThickness
    implicitHeight: isHorizontal ? barThickness : Math.max(contentCol.implicitHeight + vPadding * 2, barThickness)
    Item {
        id: progressTrack

        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.top: root.isHorizontal ? parent.top : undefined
        anchors.right: root.isHorizontal ? undefined : parent.right

        width: root.isHorizontal ? parent.width * root.progress : parent.width
        height: root.isHorizontal ? parent.height : parent.height * root.progress
        clip: true

        Behavior on width {
            Anim {
                type: Anim.FastSpatial
            }
        }

        Behavior on height {
            Anim {
                type: Anim.FastSpatial
            }
        }

        StyledRect {
            id: progressFill

            anchors.left: parent.left
            anchors.bottom: parent.bottom

            width: root.width
            height: root.height
            color: Qt.alpha(root.accent, 0.25)
            radius: root.radius
        }
    }

    RowLayout {
        id: contentRow

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.hPadding
        anchors.rightMargin: root.hPadding
        anchors.topMargin: root.vPadding
        anchors.bottomMargin: root.vPadding
        visible: root.isHorizontal
        spacing: Tokens.spacing.small

        Item {
            Layout.preferredWidth: 0
            Layout.fillWidth: true
        }

        MaterialIcon {
            text: root.icon
            color: root.iconColor
            fill: 1
        }

        StyledText {
            Layout.preferredWidth: dummyText.implicitWidth
            horizontalAlignment: Text.AlignHCenter
            text: root.valueText
            color: root.textColor
            font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Item {
            Layout.preferredWidth: 0
            Layout.fillWidth: true
        }
    }

    ColumnLayout {
        id: contentCol

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.vPadding
        anchors.rightMargin: root.vPadding
        anchors.topMargin: root.vPadding
        anchors.bottomMargin: root.vPadding
        visible: !root.isHorizontal
        spacing: Tokens.spacing.extraSmall

        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            text: root.icon
            color: root.iconColor
            fill: 1
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: root.valueText
            color: root.textColor
            font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
        }
    }
}
