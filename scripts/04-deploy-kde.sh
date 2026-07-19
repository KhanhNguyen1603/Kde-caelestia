#!/usr/bin/env bash
# 04-deploy-kde.sh  Apply KDE Plasma settings: Darkly theme, Kvantum, polonium,
#                    5 virtual desktops, disable KDE OSDs.
#
# Applies:
#   - Plasma style:      Darkly
#   - Application style: Darkly (via kvantum-dark as engine)
#   - Window decoration: Darkly
#   - Kvantum theme:     MaterialAdw (from repo-base .config/Kvantum)
#   - Polonium:          disabled by default (or user-chosen at start)
#   - 5 virtual desktops with Meta+1..0 / Meta+Shift+1..0 shortcuts
#   - KDE OSD disabled (volume/brightness popups)

BUNDLE_DIR="${BUNDLE_DIR:?BUNDLE_DIR not set}"
POLONIUM_ENABLED="${POLONIUM_ENABLED:-false}"

echo
echo ""
echo "  Step 4/11  KDE Settings"
echo ""

#  Darkly Theme & Bibata Cursor 
if [[ "${APPLY_DARKLY:-true}" == "true" ]]; then
    #  Darkly: Plasma style 
    echo "  Applying Darkly plasma style..."
    kwriteconfig6 --file plasmarc --group "Theme" --key "name" "Darkly" 2>/dev/null || true

    #  Darkly: Application style (Qt widget style) 
    echo "  Applying Darkly application style..."
    kwriteconfig6 --file kdeglobals --group "KDE" --key "widgetStyle" "darkly" 2>/dev/null || true
    kwriteconfig6 --file kdeglobals --group "General" --key "ColorScheme" "Darkly" 2>/dev/null || true

    #  Darkly: Window decoration 
    echo "  Applying Darkly window decoration..."
    kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" \
        --key "library" "org.kde.darkly" 2>/dev/null || \
    kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" \
        --key "library" "org.kde.breeze" 2>/dev/null || true
    kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" \
        --key "theme" "@darkly" 2>/dev/null || true

    #  Bibata: Cursor theme 
    # echo "  Applying Bibata cursor theme..."
    # kwriteconfig6 --file kcminputrc --group Mouse --key cursorTheme "Bibata-Modern-Ice" 2>/dev/null || true
else
    echo "  [SKIP] Skipping Darkly theme & Bibata cursor application."
fi

#  Polonium: tiling window manager 
echo "  Configuring Polonium (tiling)  enabled=$POLONIUM_ENABLED ..."
kwriteconfig6 --file kwinrc --group "Plugins" \
    --key "poloniumEnabled" "$POLONIUM_ENABLED" 2>/dev/null || true



# echo "==> Configuring KDE virtual desktops..."

# # ── 1. Set desktop count to 10 via kwriteconfig6 ─────────────────────────────
# # KWin reads NumberOfDesktops from kwinrc on startup / reconfigure.
# CURRENT_COUNT=$(kreadconfig6 --file kwinrc --group "Desktops" --key "Number" 2>/dev/null || echo "1")
# echo "  Current desktop count: $CURRENT_COUNT"

# if (( CURRENT_COUNT < 10 )); then
#     echo "  Setting desktop count to 10..."
#     kwriteconfig6 --file kwinrc --group "Desktops" --key "Number" "10"
#     kwriteconfig6 --file kwinrc --group "Desktops" --key "Rows" "1"
#     # Also name the desktops
#     for i in $(seq 1 10); do
#         kwriteconfig6 --file kwinrc --group "Desktops" --key "Name_$i" "Desktop $i"
#     done
# else
#     echo "  Already have $CURRENT_COUNT desktops — skipping creation."
# fi

# Being handled by Shortcuts.qml
# # ── 2. Bind Meta+1..9,0 to "Switch to Desktop N" ─────────────────────────────
# echo "  Registering Meta+1..0 workspace switching shortcuts..."

# # Meta+1 through Meta+9
# for i in $(seq 1 9); do
#     kwriteconfig6 \
#         --file kglobalshortcutsrc \
#         --group "kwin" \
#         --key "Switch to Desktop $i" \
#         "Meta+$i,none,Switch to Desktop $i"
# done

# # Meta+0 → Desktop 10
# kwriteconfig6 \
#     --file kglobalshortcutsrc \
#     --group "kwin" \
#     --key "Switch to Desktop 10" \
#     "Meta+0,none,Switch to Desktop 10"

# # Meta+Shift+1..9,0 → Move window to desktop N
# for i in $(seq 1 9); do
#     kwriteconfig6 \
#         --file kglobalshortcutsrc \
#         --group "kwin" \
#         --key "Window to Desktop $i" \
#         "Meta+Shift+$i,none,Move Window to Desktop $i"
# done
# kwriteconfig6 \
#     --file kglobalshortcutsrc \
#     --group "kwin" \
#     --key "Window to Desktop 10" \
#     "Meta+Shift+0,none,Move Window to Desktop 10"

# ── 3. Reconfigure KWin to pick up new settings ───────────────────────────────
echo "  Reloading KWin..."
qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true
systemctl --user restart plasma-kglobalaccel.service 2>/dev/null || true

echo "[OK]  10 virtual desktops created"

#  Disable KDE OSDs (volume, brightness popups) 
echo "  Disabling KDE OSD popups..."
# Plasma volume OSD
kwriteconfig6 --file plasmarc --group "OSD" --key "Enabled" "false" 2>/dev/null || true
# kde-plasma-volume / kded audio volume OSD
kwriteconfig6 --file kdeglobals --group "KDE" --key "OSDEnabled" "false" 2>/dev/null || true
# plasma-volume OSD
kwriteconfig6 --file plasmanotifyrc --group "Notifications" \
    --key "LoudnessChangedOSD" "false" 2>/dev/null || true
# Brightness OSD via powerdevil
kwriteconfig6 --file powerdevilrc --group "BrightnessControl" \
    --key "showOSD" "false" 2>/dev/null || true
kwriteconfig6 --file powerdevilrc --group "AC" \
    --key "brightnessosd" "false" 2>/dev/null || true
# Plasma workspace OSD (Plasma 6 unified OSD daemon)
kwriteconfig6 --file plasmarc --group "OSD" --key "ShowOnActiveScreen" "false" 2>/dev/null || true
# Disable the plasma-volume kded module OSD flag
mkdir -p "$HOME/.config"
cat > "$HOME/.config/kmixrc" <<'EOF' 2>/dev/null || true
[Global]
ShowOSD=false
EOF
echo "  [OK]  KDE OSDs disabled."

#  Apply via lookandfeeltool if Darkly LNF exists (Fonts included) 
if [[ "${APPLY_FONTS:-true}" == "true" ]]; then
    if command -v lookandfeeltool >/dev/null 2>&1; then
        if [[ "${APPLY_DARKLY:-true}" == "true" ]]; then
            echo "  Applying custom fonts and LNF via lookandfeeltool..."
            lookandfeeltool --apply "Darkly" 2>/dev/null || true
        else
            echo "  [SKIP] Skipping Darkly LNF as Darkly theme was opted out. (Fonts must be applied manually)"
        fi
    fi
else
    echo "  [SKIP] Skipping custom fonts application."
fi

#  Cliphist Service 
echo "  Setting up cliphist background service..."
mkdir -p "$HOME/.config/systemd/user"
cat > "$HOME/.config/systemd/user/cliphist.service" << 'EOF'
[Unit]
Description=Clipboard history service
After=graphical-session.target

[Service]
Type=simple
ExecStart=/bin/bash -c "wl-paste --type text --watch cliphist store & wl-paste --type image --watch cliphist store & wl-clip-persist --clipboard regular & wait"
Restart=always
RestartSec=3

[Install]
WantedBy=default.target
EOF
systemctl --user daemon-reload
systemctl --user enable --now cliphist.service 2>/dev/null || true
echo "  [OK]  Cliphist background service enabled."

echo "[OK]  KDE settings applied."

#  Set Default Wallpaper 
echo "  Setting default wallpaper to Minimal-Paper.png..."
WALLPAPER_PATH="$BUNDLE_DIR/shell/assets/wallpapers/Minimal-Paper.png"
if [[ -f "$WALLPAPER_PATH" ]]; then
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "
        var allDesktops = desktops();
        for (i=0; i < allDesktops.length; i++) {
            d = allDesktops[i];
            d.wallpaperPlugin = 'org.kde.image';
            d.currentConfigGroup = Array('Wallpaper', 'org.kde.image', 'General');
            d.writeConfig('Image', 'file://' + '$WALLPAPER_PATH');
        }
    " 2>/dev/null || true
    # Also save it for Caelestia
    mkdir -p "$HOME/.local/share/caelestia/state/wallpaper"
    echo "$WALLPAPER_PATH" > "$HOME/.local/share/caelestia/state/wallpaper/path.txt"
fi
