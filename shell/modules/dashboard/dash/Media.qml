pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Caelestia.Components
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.components.widgets
import qs.services
import qs.utils

Item {
    id: root

    property real playerProgress: {
        const active = Players.active;
        return active?.length ? (active.position % active.length) / active.length : 0;
    }

    readonly property real arcCoverGap: Tokens.spacing.extraSmall

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    implicitWidth: Tokens.sizes.dashboard.mediaWidth

    Behavior on playerProgress {
        Anim {
            type: Anim.StandardLarge
        }
    }

    Timer {
        running: Players.active?.isPlaying ?? false
        interval: GlobalConfig.dashboard.mediaUpdateInterval
        triggeredOnStart: true
        repeat: true
        onTriggered: Players.active?.positionChanged()
    }

    ServiceRef {
        service: Audio.beatTracker
    }

    Column {
        id: contentBox

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Tokens.spacing.small

        Item {
            id: coverContainer

            width: parent.width
            height: cover.implicitHeight + root.arcCoverGap * 2 + prog.thickness * 2

            CircularProgress {
                id: prog

                anchors.centerIn: cover
                implicitSize: cover.width + root.arcCoverGap + thickness * 2

                fgColour: Colours.palette.m3primary
                strokeWidth: Tokens.sizes.dashboard.mediaProgressThickness
                startAngle: -90 - sweepAngle / 2
                sweepAngle: Tokens.sizes.dashboard.mediaProgressSweep
                value: root.playerProgress

                wavy: true
                waveFrequency: 8
                waveDuration: 2000
                wavePaused: !Players.active?.isPlaying
            }

            CoverArt {
                id: cover

                anchors.centerIn: parent
                width: parent.width - (Tokens.padding.medium + root.arcCoverGap + prog.thickness) * 2
                implicitHeight: width
            }
        }

        StyledText {
            id: title

            anchors.horizontalCenter: parent.horizontalCenter

            animate: true
            horizontalAlignment: Text.AlignHCenter
            text: (Players.active?.trackTitle ?? qsTr("No media")) || qsTr("Unknown title")
            color: Colours.palette.m3primary
            font: Tokens.font.title.small

            width: parent.width - Tokens.padding.large * 2
            maximumLineCount: 2
            wrapMode: Text.Wrap
            elide: Text.ElideRight
        }

        StyledText {
            id: album

            anchors.horizontalCenter: parent.horizontalCenter

            animate: true
            horizontalAlignment: Text.AlignHCenter
            text: (Players.active?.trackAlbum ?? qsTr("No media")) || qsTr("Unknown album")
            color: Colours.palette.m3outline
            font: Tokens.font.body.small

            width: parent.width - Tokens.padding.large * 2
            elide: Text.ElideRight
        }

        StyledText {
            id: artist

            anchors.horizontalCenter: parent.horizontalCenter

            animate: true
            horizontalAlignment: Text.AlignHCenter
            text: (Players.active?.trackArtist ?? qsTr("No media")) || qsTr("Unknown artist")
            color: Colours.palette.m3secondary

            width: parent.width - Tokens.padding.large * 2
            elide: Text.ElideRight
        }

        ButtonRow {
            id: controls

            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - Tokens.padding.medium * 2

            spacing: Tokens.spacing.extraSmall

            IconButton {
                type: IconButton.Tonal
                icon: "skip_previous"
                isRound: true
                shapeMorph: true
                disabled: !Players.active?.canGoPrevious
                onClicked: Players.active?.previous()
            }

            IconButton {
                fillWidth: true
                icon: Players.active?.isPlaying ? "pause" : "play_arrow"
                isRound: true
                shapeMorph: true
                checked: Players.active?.isPlaying ?? false
                disabled: !Players.active?.canTogglePlaying
                onClicked: Players.active?.togglePlaying()
            }

            IconButton {
                type: IconButton.Tonal
                icon: "skip_next"
                isRound: true
                shapeMorph: true
                disabled: !Players.active?.canGoNext
                onClicked: Players.active?.next()
            }
        }
    }
}
