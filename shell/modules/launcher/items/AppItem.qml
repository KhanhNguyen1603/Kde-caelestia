import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.effects
import qs.services
import qs.utils
import qs.modules.launcher.services

Item {
    id: root

    required property DesktopEntry modelData
    required property DrawerVisibilities visibilities

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        id: stateLayer

        radius: Tokens.rounding.large
        acceptedButtons: Qt.LeftButton
        onClicked: {
            Apps.launch(root.modelData);
            root.visibilities.launcher = false;
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        anchors.margins: Tokens.padding.small

        IconImage {
            id: icon

            asynchronous: false
            source: Quickshell.iconPath(root.modelData?.icon, "image-missing")
            implicitSize: Math.max(1, parent.height * 0.8)

            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.verticalCenter: icon.verticalCenter

            implicitWidth: parent.width - icon.width - 90
            implicitHeight: name.implicitHeight + comment.implicitHeight

            StyledText {
                id: name

                text: root.modelData?.name ?? ""
                font: Tokens.font.body.medium
            }

            StyledText {
                id: comment

                text: (root.modelData?.comment || root.modelData?.genericName || root.modelData?.name) ?? ""
                font: Tokens.font.body.small
                color: Colours.palette.m3outline

                elide: Text.ElideRight
                width: root.width - icon.width - 90 - Tokens.rounding.extraLargeIncreased

                anchors.top: name.bottom
            }
        }

        MouseArea {
            id: favIcon

            width: 32
            height: 32
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            hoverEnabled: true
            onClicked: {
                const appId = root.modelData?.id;
                if (!appId)
                    return;
                const favApps = GlobalConfig.launcher.favouriteApps ? [...GlobalConfig.launcher.favouriteApps] : [];
                if (Strings.testRegexList(favApps, appId)) {
                    const idx = favApps.indexOf(appId);
                    if (idx !== -1)
                        favApps.splice(idx, 1);
                } else {
                    favApps.push(appId);
                }
                GlobalConfig.launcher.favouriteApps = favApps;
            }

            MaterialIcon {
                anchors.centerIn: parent
                text: Strings.testRegexList(GlobalConfig.launcher.favouriteApps, root.modelData?.id) ? "favorite" : "favorite_border"
                fill: Strings.testRegexList(GlobalConfig.launcher.favouriteApps, root.modelData?.id) ? 1 : 0
                color: favIcon.containsMouse ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            }
        }

        MouseArea {
            id: pinIcon

            width: 32
            height: 32
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: favIcon.left
            anchors.rightMargin: Tokens.padding.small
            hoverEnabled: true

            property bool isPinned: false

            // Detect trạng thái pin bằng cách check symlink hoặc file trên Desktop
            Process {
                id: checkPinnedProc
                command: [
                    "sh", "-c",
                    "DESKTOP_DIR=$(xdg-user-dir DESKTOP 2>/dev/null || echo ~/Desktop); " +
                    "test -L \"$DESKTOP_DIR/$1\" || test -L \"$DESKTOP_DIR/$1.desktop\" || " +
                    "test -f \"$DESKTOP_DIR/$1\" || test -f \"$DESKTOP_DIR/$1.desktop\"",
                    "--", root.modelData?.id ?? ""
                ]
                running: true
                onExited: code => {
                    pinIcon.isPinned = (code === 0);
                }
            }

            onClicked: {
                const entryFile = root.modelData?.file || "";
                const entryId = root.modelData?.id || "";
                if (!entryId)
                    return;

                if (isPinned) {
                    // Unpin: xóa symlink hoặc file ra khỏi Desktop
                    Quickshell.execDetached([
                        "sh", "-c",
                        "DESKTOP_DIR=$(xdg-user-dir DESKTOP 2>/dev/null || echo ~/Desktop); " +
                        "rm -f \"$DESKTOP_DIR/$1\" \"$DESKTOP_DIR/$1.desktop\"",
                        "--", entryId
                    ]);
                    isPinned = false;
                } else {
                    // Pin: tạo symlink ln -sf ra Desktop (giữ nguyên file gốc, không tốn dung lượng)
                    Quickshell.execDetached([
                        "sh", "-c",
                        `FILE_PATH="${entryFile}"; ` +
                        `if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then ` +
                        `FILE_PATH=$(find /usr/share/applications /usr/local/share/applications ~/.local/share/applications ` +
                        `-name "${entryId}" -o -name "${entryId}.desktop" -print -quit 2>/dev/null); fi; ` +
                        `if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then ` +
                        `DESKTOP_DIR=$(xdg-user-dir DESKTOP 2>/dev/null || echo ~/Desktop); ` +
                        `ln -sf "$FILE_PATH" "$DESKTOP_DIR/"; fi`
                    ]);
                    isPinned = true;
                }
            }

            MaterialIcon {
                anchors.centerIn: parent
                text: "push_pin"
                fill: pinIcon.isPinned ? 1 : 0
                color: pinIcon.isPinned ? Colours.palette.m3primary : (pinIcon.containsMouse ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant)
            }
        }
    }
}
