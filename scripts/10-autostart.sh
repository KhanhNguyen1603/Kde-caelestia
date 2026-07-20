#!/usr/bin/env bash
# 06-autostart.sh  Set up autostart entries for Quickshell and kde-material-you-colors.
# Idempotent: overwrites .desktop files with correct content each run.

AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"
mkdir -p "$HOME/.local/bin"

echo
echo ""
echo "  Step 10/11  Autostart Setup"
echo ""

SHELL_CONFIG="$HOME/.config/quickshell/caelestia/shell.qml"

if [[ ! -f "$SHELL_CONFIG" ]]; then
    echo "  [ERR]  Caelestia Shell entrypoint not found: $SHELL_CONFIG" >&2
    echo "         Run scripts/08-build-shell.sh before configuring autostart." >&2
    exit 1
fi

# Determine the path of quickshell to avoid PATH differences at login.
if command -v quickshell >/dev/null 2>&1; then
    QUICKSHELL_PATH="$(command -v quickshell)"
elif command -v qs >/dev/null 2>&1; then
    QUICKSHELL_PATH="$(command -v qs)"
elif [ -x "/usr/bin/quickshell" ]; then
    QUICKSHELL_PATH="/usr/bin/quickshell"
elif [ -x "/usr/local/bin/quickshell" ]; then
    QUICKSHELL_PATH="/usr/local/bin/quickshell"
else
    echo "  [ERR]  Quickshell is not installed or is not available in PATH." >&2
    exit 127
fi

# Caelestia Shell autostart
# Launch the shell built by 08-build-shell.sh directly. This avoids depending
# on the distro's caelestia-cli version or its config-directory resolution.
echo "  Creating Caelestia Shell autostart entry..."
cat > "$HOME/.local/bin/caelestia-autostart.sh" << EOF
#!/bin/bash
export QML2_IMPORT_PATH="\$HOME/.local/lib/qt6/qml"
export CAELESTIA_LIB_DIR="\$HOME/.local/lib/caelestia"
exec env __NV_PRIME_RENDER_OFFLOAD=0 DRI_PRIME=0 "$QUICKSHELL_PATH" -d -n -p "\$HOME/.config/quickshell/caelestia/shell.qml"
EOF
chmod +x "$HOME/.local/bin/caelestia-autostart.sh"

cat > "$AUTOSTART_DIR/caelestiashell.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Caelestia Shell
Comment=Start Caelestia Shell
Exec=$HOME/.local/bin/caelestia-autostart.sh
Icon=quickshell
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
X-KDE-AutostartPhase=2
EOF
echo "  [OK]  Quickshell autostart created."

#  kde-material-you-colors systemd service 
# Creates and enables a systemd user service for kde-material-you-colors.
echo "  Deploying systemd service for KDE Material You Colors..."

if [[ "${APPLY_MATERIAL_YOU:-true}" == "true" ]]; then
    # Clean up old desktop autostart entry if it exists
    rm -f "$AUTOSTART_DIR/kde-material-you-colors.desktop" 2>/dev/null || true

    # Clean up old Material You color schemes to prevent them from multiplying
    rm -f "$HOME/.local/share/color-schemes/MaterialYou"*.colors 2>/dev/null || true

    mkdir -p "$HOME/.config/systemd/user"
    # Determine the path of kde-material-you-colors
    if command -v kde-material-you-colors >/dev/null 2>&1; then
        KMYC_PATH=$(command -v kde-material-you-colors)
    elif [ -f "$HOME/.local/bin/kde-material-you-colors" ]; then
        KMYC_PATH="$HOME/.local/bin/kde-material-you-colors"
    elif [ -f "/usr/bin/kde-material-you-colors" ]; then
        KMYC_PATH="/usr/bin/kde-material-you-colors"
    else
        KMYC_PATH="$HOME/.local/bin/kde-material-you-colors"
    fi

    cat > "$HOME/.config/systemd/user/kde-material-you-colors.service" << EOF
[Unit]
Description=KDE Material You Colors
PartOf=graphical-session.target
After=graphical-session.target

[Service]
Type=simple
ExecStart=$KMYC_PATH
Restart=on-failure
RestartSec=3

[Install]
WantedBy=graphical-session.target
EOF

    systemctl --user daemon-reload
    systemctl --user enable --now kde-material-you-colors.service 2>/dev/null || true
    echo "  [OK]  kde-material-you-colors systemd service enabled."
else
    echo "  [SKIP] Skipping kde-material-you-colors systemd service."
fi

echo "[OK]  Autostart entries configured."
