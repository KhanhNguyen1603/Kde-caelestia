pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import qs.services

Singleton {
    id: root

    property alias enabled: props.enabled

    // Hyprland is not always the compositor this runs under. Everything below
    // branches on that rather than assuming it.
    // Quickshell.env returns undefined for an unset variable, not "", so compare
    // truthiness — !== "" was true everywhere and sent KDE down the Hyprland path.
    readonly property bool onHyprland: !!Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")

    // Video wallpapers keep a decoder and a GPU upload running for as long as
    // they play, which is exactly what game mode is trying to free up.
    property bool restoreVideoWallpaper: false

    function setDynamicConfs(): void {
        Hypr.extras.applyOptions({
            "animations:enabled": 0,
            "decoration:shadow:enabled": 0,
            "decoration:blur:enabled": 0,
            "general:gaps_in": 0,
            "general:gaps_out": 0,
            "general:border_size": 1,
            "decoration:rounding": 0,
            "general:allow_tearing": 1
        });
    }

    // KWin's equivalents of the Hyprland options above: window animations and the
    // blur effect. Both are read back before being changed so a user who already
    // had them off does not get them switched on when game mode ends.
    function applyKwin(enable: bool): void {
        const script = enable
            ? 'prevBlur="$(kreadconfig6 --file kwinrc --group Plugins --key blurEnabled --default true)"; ' +
              'prevAnim="$(kreadconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor --default 1)"; ' +
              'mkdir -p "$HOME/.cache/caelestia"; printf "%s\\n%s\\n" "$prevBlur" "$prevAnim" > "$HOME/.cache/caelestia/gamemode-prev"; ' +
              'kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled false; ' +
              'kwriteconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor 0; ' +
              'qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1'
            : 'p="$HOME/.cache/caelestia/gamemode-prev"; ' +
              'blur="$(sed -n 1p "$p" 2>/dev/null)"; anim="$(sed -n 2p "$p" 2>/dev/null)"; ' +
              '[ -n "$blur" ] || blur=true; [ -n "$anim" ] || anim=1; ' +
              'kwriteconfig6 --file kwinrc --group Plugins --key blurEnabled "$blur"; ' +
              'kwriteconfig6 --file kdeglobals --group KDE --key AnimationDurationFactor "$anim"; ' +
              'qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1';
        Quickshell.execDetached(["sh", "-c", script]);
    }

    onEnabledChanged: {
        if (enabled) {
            // Pause a playing video wallpaper, remembering whether it was paused
            // already so ending game mode does not start one the user had stopped.
            root.restoreVideoWallpaper = !GlobalConfig.background.videoWallpaperPaused;
            if (root.restoreVideoWallpaper)
                GlobalConfig.background.videoWallpaperPaused = true;

            if (root.onHyprland)
                setDynamicConfs();
            else
                applyKwin(true);

            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(qsTr("Game mode enabled"),
                    root.onHyprland ? qsTr("Disabled Hyprland animations, blur, gaps and shadows")
                                    : qsTr("Paused video wallpaper, disabled blur and animations"), "gamepad");
        } else {
            if (root.restoreVideoWallpaper) {
                GlobalConfig.background.videoWallpaperPaused = false;
                root.restoreVideoWallpaper = false;
            }

            if (root.onHyprland)
                Hypr.extras.message("reload");
            else
                applyKwin(false);

            if (GlobalConfig.utilities.toasts.gameModeChanged)
                Toaster.toast(qsTr("Game mode disabled"),
                    root.onHyprland ? qsTr("Hyprland settings restored") : qsTr("Desktop effects restored"), "gamepad");
        }
    }

    PersistentProperties {
        id: props

        // Plain state, not a binding. It used to read back from
        // Hypr.options["animations:enabled"], which off Hyprland evaluates
        // undefined === 0 — false — so game mode could never stay switched on
        // there. onConfigReloaded below re-applies the options on Hyprland, so
        // nothing needed the binding anyway.
        property bool enabled: false

        reloadableId: "gameMode"
    }

    Connections {
        function onConfigReloaded(): void {
            if (props.enabled)
                root.setDynamicConfs();
        }

        target: Hypr
    }

    IpcHandler {
        function isEnabled(): bool {
            return props.enabled;
        }

        function toggle(): void {
            props.enabled = !props.enabled;
        }

        function enable(): void {
            props.enabled = true;
        }

        function disable(): void {
            props.enabled = false;
        }

        target: "gameMode"
    }
}
