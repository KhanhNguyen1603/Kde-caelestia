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

    implicitWidth: isHorizontal ? Math.round(barThickness * widthFactor) : barThickness
    implicitHeight: isHorizontal ? barThickness : Math.max(contentCol.implicitHeight + vPadding * 2 + trackThickness + Tokens.spacing.extraSmall, barThickness)

    RowLayout {
        id: contentRow

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: root.hPadding
        anchors.rightMargin: root.hPadding
        anchors.topMargin: root.vPadding
        anchors.bottomMargin: root.vPadding + root.trackThickness + Tokens.spacing.extraSmall
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
            text: root.valueText
            color: root.textColor
            font: Tokens.font.body.builders.small.weight(Font.DemiBold).build()
            elide: Text.ElideRight
            maximumLineCount: 1
            animate: true
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
        anchors.bottomMargin: root.vPadding + root.trackThickness + Tokens.spacing.extraSmall
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
            animate: true
        }
    }

    StyledRect {
        id: progressTrack

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.trackInset

        implicitHeight: root.trackThickness
        color: Qt.alpha(Colours.palette.m3outlineVariant, 0.55)
        radius: Tokens.rounding.full

        StyledRect {
            id: progressFill

            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom

            width: Math.max(root.progress > 0 ? root.trackThickness : 0, parent.width * root.progress)
            color: root.accent
            radius: parent.radius

            Behavior on width {
                Anim {
                    type: Anim.FastSpatial
                }
            }
        }
    }
}
