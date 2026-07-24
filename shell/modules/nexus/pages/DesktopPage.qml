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
                        # Map meta+arrows to change focus to the app in respective direction
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key KrohnkiteFocusUp "Meta+Up,none,Krohnkite: Focus Up" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key KrohnkiteFocusDown "Meta+Down,none,Krohnkite: Focus Down" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key KrohnkiteFocusLeft "Meta+Left,none,Krohnkite: Focus Left" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key KrohnkiteFocusRight "Meta+Right,none,Krohnkite: Focus Right" 2>/dev/null || true
                        # Unbind conflicting native shortcuts
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window Quick Tile Top" "none,none,Window Quick Tile Top" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window Quick Tile Bottom" "none,none,Window Quick Tile Bottom" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window Quick Tile Left" "none,none,Window Quick Tile Left" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window Quick Tile Right" "none,none,Window Quick Tile Right" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Tiling Focus Up" "none,none,Tiling Focus Up" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Tiling Focus Down" "none,none,Tiling Focus Down" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Tiling Focus Left" "none,none,Tiling Focus Left" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Tiling Focus Right" "none,none,Tiling Focus Right" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key KrohnkiteShiftUp "Meta+Shift+Up,none,Krohnkite: Move Up/Prev" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key KrohnkiteShiftDown "Meta+Shift+Down,none,Krohnkite: Move Down/Next" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key KrohnkiteShiftLeft "Meta+Shift+Left,none,Krohnkite: Move Left" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key KrohnkiteShiftRight "Meta+Shift+Right,none,Krohnkite: Move Right" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Next Screen" "none,none,Move Window to Next Screen" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Previous Screen" "none,none,Move Window to Previous Screen" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Tiling Move Window Next" "none,none,Tiling Move Window Next" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Tiling Move Window Previous" "none,none,Tiling Move Window Previous" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window Close" "Meta+Q,Alt+F4,Close Window" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "manage activities" "none,Meta+Q,Show Activity Switcher" 2>/dev/null || true
                        qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
                    else
                        qdbus6 org.kde.kglobalaccel /component/kwin org.kde.kglobalaccel.Component.invokeShortcut "KrohnkiteFloatAll" 2>/dev/null || true
                        sleep 0.1
                        qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript "krohnkite" 2>/dev/null || true
                        kwriteconfig6 --file kwinrc --group "Plugins" --key "krohnkiteEnabled" "false" 2>/dev/null || true
                        # Unmap Krohnkite focus shortcuts
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key KrohnkiteFocusUp "none,none,Krohnkite: Focus Up" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key KrohnkiteFocusDown "none,none,Krohnkite: Focus Down" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key KrohnkiteFocusLeft "none,none,Krohnkite: Focus Left" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key KrohnkiteFocusRight "none,none,Krohnkite: Focus Right" 2>/dev/null || true
                        # Restore native shortcuts
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window Quick Tile Top" "Meta+Up,Meta+Up,Quick Tile Window to the Top" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window Quick Tile Bottom" "Meta+Down,Meta+Down,Quick Tile Window to the Bottom" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window Quick Tile Left" "Meta+Left,Meta+Left,Quick Tile Window to the Left" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window Quick Tile Right" "Meta+Right,Meta+Right,Quick Tile Window to the Right" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Tiling Focus Up" "Meta+Up,Meta+Up,Tiling Focus Up" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Tiling Focus Down" "Meta+Down,Meta+Down,Tiling Focus Down" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Tiling Focus Left" "Meta+Left,Meta+Left,Tiling Focus Left" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Tiling Focus Right" "Meta+Right,Meta+Right,Tiling Focus Right" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key KrohnkiteShiftUp "none,none,Krohnkite: Move Up/Prev" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key KrohnkiteShiftDown "none,none,Krohnkite: Move Down/Next" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key KrohnkiteShiftLeft "none,none,Krohnkite: Move Left" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key KrohnkiteShiftRight "none,none,Krohnkite: Move Right" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Next Screen" "Meta+Shift+Right,Meta+Shift+Right,Move Window to Next Screen" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window to Previous Screen" "Meta+Shift+Left,Meta+Shift+Left,Move Window to Previous Screen" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Tiling Move Window Next" "Meta+Shift+Right,Meta+Shift+Right,Tiling Move Window Next" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Tiling Move Window Previous" "Meta+Shift+Left,Meta+Shift+Left,Tiling Move Window Previous" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group kwin --key "Window Close" "Alt+F4,Alt+F4,Close Window" 2>/dev/null || true
                        kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key "manage activities" "Meta+Q,Meta+Q,Show Activity Switcher" 2>/dev/null || true
                        qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
                    fi
                `]);
            }
        }

        NavRow {
            visible: parent.showTilingLogout
            icon: "logout"
            label: parent.isTilingEnabled ? qsTr("Log out to enable custom shortcuts") : qsTr("Log out to fully disable tiling")
            status: parent.isTilingEnabled ? qsTr("Meta+Arrows, Meta+Shift+Arrows, Meta+Q for complete experience.") : qsTr("KWin requires a restart to clear window tiling rules")
            onClicked: Quickshell.execDetached(["sh", "-c", "qdbus6 org.kde.Shutdown /Shutdown org.kde.Shutdown.logout 2>/dev/null || true"])
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
