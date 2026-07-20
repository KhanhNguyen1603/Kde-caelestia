import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Caelestia.Services
import Caelestia
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property DrawerVisibilities visibilities
    required property var panels
    required property real maxHeight

    readonly property int padding: Tokens.padding.large
    readonly property int rounding: Tokens.rounding.extraLarge
    readonly property bool isClipboardMode: search.text.startsWith(`${GlobalConfig.launcher.actionPrefix}clipboard `)

    function clearClipboardHistory(): void {
        Clipboard.clearHistory();
    }

    Connections {
        target: Clipboard

        function onClearHistoryFinished(success: bool): void {
            if (success)
                Toaster.toast(qsTr("Clipboard history cleared"), "", "delete");
            else
                Toaster.toast(qsTr("Failed to clear clipboard history"), "", "error");
        }
    }

    implicitWidth: listWrapper.width + padding * 2
    implicitHeight: searchWrapper.height + listWrapper.height + padding * 2 + Tokens.spacing.medium + launcherSessionRow.implicitHeight

    Item {
        id: listWrapper

        implicitWidth: list.implicitWidth
        implicitHeight: list.implicitHeight + root.padding

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: searchWrapper.top
        anchors.bottomMargin: root.padding

        ContentList {
            id: list

            content: root
            visibilities: root.visibilities
            panels: root.panels
            maxHeight: root.maxHeight - searchWrapper.implicitHeight - launcherSessionRow.implicitHeight - Tokens.spacing.medium - root.padding * 3
            search: search
            padding: root.padding
            rounding: root.rounding
        }
    }

    StyledRect {
        id: searchWrapper

        color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
        radius: Tokens.rounding.full

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: launcherSessionRow.top
        anchors.margins: root.padding
        anchors.bottomMargin: Tokens.spacing.medium

        implicitHeight: Math.max(searchIcon.implicitHeight, search.implicitHeight, clearClipboardIcon.implicitHeight, clearIcon.implicitHeight)

        MaterialIcon {
            id: searchIcon

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: root.padding

            text: "search"
            color: Colours.palette.m3onSurfaceVariant
        }

        StyledTextField {
            id: search

            anchors.left: searchIcon.right
            anchors.right: clearClipboardIcon.left
            anchors.leftMargin: Tokens.spacing.small
            anchors.rightMargin: Tokens.spacing.small

            topPadding: Tokens.padding.medium
            bottomPadding: Tokens.padding.medium

            placeholderText: qsTr("Type \"%1\" for commands").arg(GlobalConfig.launcher.actionPrefix)

            onAccepted: {
                const currentItem = list.currentList?.currentItem;
                if (currentItem) {
                    if (list.showWallpapers) {
                        if (Colours.scheme === "dynamic" && currentItem.modelData.path !== Wallpapers.actualCurrent)
                            Wallpapers.previewColourLock = true;
                        Wallpapers.setWallpaper(currentItem.modelData.path);
                        root.visibilities.launcher = false;
                    } else if (text.startsWith(GlobalConfig.launcher.actionPrefix)) {
                        if (text.startsWith(`${GlobalConfig.launcher.actionPrefix}calc `))
                            currentItem.onClicked();
                        else if (text.startsWith(`${GlobalConfig.launcher.actionPrefix}emoji `) || text.startsWith(`${GlobalConfig.launcher.actionPrefix}clipboard `) || text.startsWith(`${GlobalConfig.launcher.actionPrefix}windows `) || text.startsWith(`${GlobalConfig.launcher.actionPrefix}keybinds `) || text.startsWith(`${GlobalConfig.launcher.actionPrefix}animations `))
                            currentItem.clicked();
                        else
                            currentItem.modelData.onClicked(list.currentList);
                    } else {
                        Apps.launch(currentItem.modelData);
                        root.visibilities.launcher = false;
                    }
                }
            }

            Keys.onUpPressed: list.currentList?.decrementCurrentIndex()
            Keys.onDownPressed: list.currentList?.incrementCurrentIndex()

            Keys.onEscapePressed: root.visibilities.launcher = false

            Keys.onPressed: event => {
                if (!GlobalConfig.launcher.vimKeybinds)
                    return;

                if (event.modifiers & Qt.ControlModifier) {
                    if (event.key === Qt.Key_J || event.key === Qt.Key_N) {
                        list.currentList?.incrementCurrentIndex();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_K || event.key === Qt.Key_P) {
                        list.currentList?.decrementCurrentIndex();
                        event.accepted = true;
                    }
                } else if (event.key === Qt.Key_Tab) {
                    list.currentList?.incrementCurrentIndex();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                    list.currentList?.decrementCurrentIndex();
                    event.accepted = true;
                }
            }

            Component.onCompleted: {
                if (Visibilities.launcherInitialSearch) {
                    text = Visibilities.launcherInitialSearch;
                    Visibilities.launcherInitialSearch = "";
                }
                forceActiveFocus();
            }

            Connections {
                function onLauncherChanged(): void {
                    if (root.visibilities.launcher) {
                        if (Visibilities.launcherInitialSearch) {
                            search.text = Visibilities.launcherInitialSearch;
                            Visibilities.launcherInitialSearch = "";
                        }
                    }
                }

                function onSessionChanged(): void {
                    if (!root.visibilities.session)
                        search.forceActiveFocus();
                }

                target: root.visibilities
            }
        }

        MaterialIcon {
            id: clearClipboardIcon

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: clearIcon.left
            anchors.rightMargin: Tokens.spacing.small

            width: (root.isClipboardMode && Clipboard.items.length > 0) ? implicitWidth : implicitWidth / 2
            opacity: {
                if (!root.isClipboardMode || Clipboard.items.length === 0)
                    return 0;
                if (clipboardMouse.pressed)
                    return 0.7;
                if (clipboardMouse.containsMouse)
                    return 0.8;
                return 1;
            }

            text: "delete"
            color: Colours.palette.m3onSurfaceVariant

            MouseArea {
                id: clipboardMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: (root.isClipboardMode && Clipboard.items.length > 0) ? Qt.PointingHandCursor : undefined

                onClicked: {
                    if (!root.isClipboardMode || Clipboard.items.length === 0)
                        return;

                    if (GlobalConfig.launcher.confirmClearClipboard)
                        clearClipboardConfirmPopup.open();
                    else
                        root.clearClipboardHistory();
                }
            }

            Behavior on width {
                Anim {
                    type: Anim.StandardSmall
                }
            }

            Behavior on opacity {
                Anim {
                    type: Anim.StandardSmall
                }
            }
        }

        MaterialIcon {
            id: clearIcon

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: root.padding

            width: search.text ? implicitWidth : implicitWidth / 2
            opacity: {
                if (!search.text)
                    return 0;
                if (mouse.pressed)
                    return 0.7;
                if (mouse.containsMouse)
                    return 0.8;
                return 1;
            }

            text: "close"
            color: Colours.palette.m3onSurfaceVariant

            MouseArea {
                id: mouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: search.text ? Qt.PointingHandCursor : undefined

                onClicked: search.text = ""
            }

            Behavior on width {
                Anim {
                    type: Anim.StandardSmall
                }
            }

            Behavior on opacity {
                Anim {
                    type: Anim.StandardSmall
                }
            }
        }
    }

    Popup {
        id: clearClipboardConfirmPopup

        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        x: Math.round((root.width - width) / 2)
        y: Math.round((root.height - height) / 2)

        padding: Tokens.padding.large

        contentItem: Column {
            spacing: Tokens.spacing.medium

            StyledText {
                text: qsTr("Clear clipboard history?")
                font: Tokens.font.body.builders.large.weight(Font.Medium).build()
            }

            StyledText {
                text: qsTr("This removes all clipboard entries.")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
            }

            Row {
                spacing: Tokens.spacing.small

                TextButton {
                    text: qsTr("Cancel")
                    onClicked: clearClipboardConfirmPopup.close()
                }

                TextButton {
                    text: qsTr("Clear")
                    type: TextButton.Filled
                    onClicked: {
                        clearClipboardConfirmPopup.close();
                        root.clearClipboardHistory();
                    }
                }
            }
        }

        background: StyledRect {
            radius: Tokens.rounding.large
            color: Colours.palette.m3surfaceContainer
        }
    }

    RowLayout {
        id: launcherSessionRow

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.padding
        anchors.bottomMargin: CUtils.clamp(root.padding - Config.border.thickness, 0, root.padding)
        spacing: Tokens.spacing.small
        implicitHeight: 40

        LauncherSessionButton {
            iconText: "logout"
            labelText: qsTr("Log Out")
            command: ["sh", "-c", "qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logout 2>/dev/null"]
        }

        LauncherSessionButton {
            iconText: "bedtime"
            labelText: qsTr("Sleep")
            command: ["suspend"]
        }

        LauncherSessionButton {
            iconText: "refresh"
            labelText: qsTr("Restart")
            command: Config.session.commands.reboot
        }

        LauncherSessionButton {
            iconText: "power_settings_new"
            labelText: qsTr("Shut Down")
            command: Config.session.commands.shutdown
        }
    }

    component LauncherSessionButton: Item {
        id: btn
        required property string iconText
        required property string labelText
        required property list<string> command

        implicitWidth: 1
        Layout.fillWidth: true
        implicitHeight: parent.implicitHeight

        StyledRect {
            anchors.fill: parent
            radius: Tokens.rounding.medium
            color: mouseArea.containsMouse ? Colours.palette.m3surfaceContainerHigh : Colours.tPalette.m3surfaceContainerLow

            Behavior on color { ColorAnimation { duration: 150 } }

            RowLayout {
                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                MaterialIcon {
                    text: btn.iconText
                    color: Colours.palette.m3onSurface
                    fontStyle: Tokens.font.icon.builders.small.weight(Font.Medium).build()
                }

                StyledText {
                    text: btn.labelText
                    color: Colours.palette.m3onSurface
                    font: Tokens.font.body.small
                }
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (!SessionManager.exec(btn.command)) {
                    Quickshell.execDetached(btn.command);
                }
                root.visibilities.launcher = false;
            }
        }
    }
}
