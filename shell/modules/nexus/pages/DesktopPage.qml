pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import Caelestia.Services
import Quickshell
import Quickshell.Io
import qs.modules.nexus.common

PageBase {
    id: root

    title: qsTr("Desktop")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        
        property bool showTilingLogout: false
        property bool isTilingEnabled: Config.general.krohnkiteEnabled
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        ToggleRow {
            Layout.fillWidth: true
            first: true
            text: qsTr("Show KDE Desktop")
            subtext: qsTr("Disable Caelestia desktop and use native Plasma 6 desktop instead")
            checked: !Config.background.wallpaperEnabled
            onToggled: { 
                GlobalConfig.background.wallpaperEnabled = !checked; 
                for (let i = 0; i < Quickshell.screens.length; i++) {
                    let sConf = GlobalConfig.forScreen(Quickshell.screens[i].name);
                    if (sConf) sConf.background.resetOption("wallpaperEnabled");
                }
                GlobalConfig.save(); 
            }
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            text: qsTr("Show Desktop Icons")
            subtext: qsTr("Enable icons for Caelestia desktop")
            checked: Config.background.desktopIconsEnabled
            onToggled: { 
                GlobalConfig.background.desktopIconsEnabled = checked; 
                for (let i = 0; i < Quickshell.screens.length; i++) {
                    let sConf = GlobalConfig.forScreen(Quickshell.screens[i].name);
                    if (sConf) sConf.background.resetOption("desktopIconsEnabled");
                }
                GlobalConfig.save(); 
            }
            enabled: Config.background.wallpaperEnabled
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            text: qsTr("Material You Icons")
            subtext: qsTr("Override the KDE icon theme for desktop icons only")
            checked: Config.background.materialYouIconsEnabled
            onToggled: {
                GlobalConfig.background.materialYouIconsEnabled = checked;
                for (let i = 0; i < Quickshell.screens.length; i++) {
                    let sConf = GlobalConfig.forScreen(Quickshell.screens[i].name);
                    if (sConf) sConf.background.resetOption("materialYouIconsEnabled");
                }
                GlobalConfig.save();
            }
            enabled: Config.background.wallpaperEnabled && Config.background.desktopIconsEnabled
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            text: qsTr("Vibrant Icons")
            subtext: qsTr("Boost saturation of Material You icons for extra vibrancy")
            checked: Config.background.materialYouIconsVibrant
            onToggled: {
                GlobalConfig.background.materialYouIconsVibrant = checked;
                for (let i = 0; i < Quickshell.screens.length; i++) {
                    let sConf = GlobalConfig.forScreen(Quickshell.screens[i].name);
                    if (sConf) sConf.background.resetOption("materialYouIconsVibrant");
                }
                GlobalConfig.save();
            }
            enabled: Config.background.wallpaperEnabled && Config.background.desktopIconsEnabled && Config.background.materialYouIconsEnabled
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            text: qsTr("Magic Lamp Minimize")
            subtext: qsTr("Enable the magic lamp effect when minimizing windows")
            checked: Config.general.magicLampEnabled
            onToggled: {
                GlobalConfig.general.magicLampEnabled = checked;
                GlobalConfig.save();
                Quickshell.execDetached(["bash", "-c", `
                    kwriteconfig6 --file kwinrc --group "Plugins" --key "magiclampEnabled" "${checked ? 'true' : 'false'}" 2>/dev/null || true
                    if [[ "${checked ? 'true' : 'false'}" == "true" ]]; then
                        kwriteconfig6 --file kwinrc --group "Plugins" --key "squashEnabled" "false" 2>/dev/null || true
                        qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.unloadEffect "squash" 2>/dev/null || true
                        qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.loadEffect "magiclamp" 2>/dev/null || true
                    else
                        qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.unloadEffect "magiclamp" 2>/dev/null || true
                    fi
                    qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
                `]);
            }
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing
            Layout.fillWidth: true
            text: qsTr("Window Tiling")
            subtext: qsTr("Automatically tile windows using Krohnkite")
            checked: Config.general.krohnkiteEnabled
            onToggled: {
                GlobalConfig.general.krohnkiteEnabled = checked;
                GlobalConfig.save();
                parent.isTilingEnabled = checked;
                parent.showTilingLogout = true;
                Quickshell.execDetached(["bash", "-c", `
                    if [[ "${checked ? 'true' : 'false'}" == "true" ]]; then
                        qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript "krohnkite" 2>/dev/null || true
                        if ! kpackagetool6 -t KWin/Script -s krohnkite >/dev/null 2>&1; then
                            if command -v kpackagetool6 >/dev/null 2>&1; then
                                notify-send "Installing Krohnkite..." "Please stay connected to internet.."
                                tmpdir="$(mktemp -d)"
                                kwinscript_url="$(curl -sL https://codeberg.org/api/v1/repos/anametologin/Krohnkite/releases/latest | grep -oP '"browser_download_url":\\s*"\\K[^"]+\\.kwinscript' | head -1)"
                                if [[ -n "$kwinscript_url" ]] && curl -sL "$kwinscript_url" -o "$tmpdir/krohnkite.kwinscript"; then
                                    kpackagetool6 -t KWin/Script -i "$tmpdir/krohnkite.kwinscript" 2>/dev/null || true
                                    notify-send "Installation Completed.." "Krohnkite has been installed successfully.."
                                else
                                    notify-send "Installation Failed.." "Krohnkite could not be downloaded. Please try again.."
                                fi
                                rm -rf "$tmpdir"
                            else
                                notify-send "Installation Failed.." "kpackagetool6 is not installed on this system."
                            fi
                        fi
                        kwriteconfig6 --file kwinrc --group "Plugins" --key "krohnkiteEnabled" "true" 2>/dev/null || true
                        # Shortcuts are now managed by Quickshell CustomShortcuts in Shortcuts.qml
                        qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
                    else
                        qdbus6 org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut "KrohnkiteFloatAll" 2>/dev/null || true
                        sleep 0.1
                        qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript "krohnkite" 2>/dev/null || true
                        kwriteconfig6 --file kwinrc --group "Plugins" --key "krohnkiteEnabled" "false" 2>/dev/null || true
                        # Shortcuts are now managed by Quickshell CustomShortcuts in Shortcuts.qml
                        qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
                    fi
                `]);
            }
        }

        NavRow {
            visible: parent.showTilingLogout
            icon: parent.isTilingEnabled ? "refresh" : "logout"
            label: parent.isTilingEnabled ? qsTr("Restart shell to enable custom shortcuts") : qsTr("Log out to fully disable tiling")
            status: parent.isTilingEnabled ? qsTr("Meta+Arrows, Meta+Shift+Arrows, Meta+Q for complete experience.") : qsTr("KWin requires a restart to clear window tiling rules")
            onClicked: parent.isTilingEnabled ? Quickshell.execDetached(["bash", "-c", "nohup bash -c 'caelestia shell -k; sleep 2; caelestia shell -d' >/dev/null 2>&1 & disown  || true"]) : Quickshell.execDetached(["sh", "-c", "qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logout 2>/dev/null || true"])
        }

        NavRow {
            icon: "extension"
            label: qsTr("Desktop Addons")
            status: qsTr("Clock, Lyrics, Visualiser, Shimeji")
            onClicked: root.nState.openSubPage(1)
        }

        NavRow {
            last: true
            icon: "menu_open"
            label: qsTr("Right Click Menu")
            status: qsTr("Configure desktop right click menu")
            onClicked: root.nState.openSubPage(2)
        }
    }
}
