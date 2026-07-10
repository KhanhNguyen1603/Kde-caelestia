#!/usr/bin/env bash
# register.sh - Helper script to deploy Quickshell keyboard shortcuts via swhkd.
#
# Strategy:
#   1. Assume install.sh has provided sudo privileges (keepalive).
#   2. Install keyd if missing.
#   3. Scan KDE's kglobalshortcutsrc and remove any bindings that collide 
#      with our custom swhkd mappings.
#   4. Deploy our /etc/keyd/quickshell.conf and set up systemd user services for keyd.

set -uo pipefail

CYAN="\033[0;36m"; GREEN="\033[0;32m"; YELLOW="\033[1;33m"; RED="\033[0;31m"; RST="\033[0m"
info() { echo -e "${CYAN}[INFO]  $*${RST}"; }
ok()   { echo -e "${GREEN}[OK]    $*${RST}"; }
warn() { echo -e "${RED}[WARN]  $*${RST}"; }
err()  { echo -e "${RED}[ERR]   $*${RST}"; }

CONFLICT_STATE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/caelestia-kde/disabled-remappers.txt"
SKIP_KEYD_SETUP="false"

ask_conflict_action() {
    local answer=""

    while true; do
        echo
        echo "Conflicting key remappers were detected. Choose how to proceed:"
        echo "  [d] Disable conflicting remappers and continue with keyd (recommended)"
        echo "  [s] Skip keyd setup for this install run"
        echo "  [a] Abort keyboard shortcut step"
        read -r -p "Enter choice [d/s/a] (default: d): " answer
        answer="${answer:-d}"

        case "${answer,,}" in
            d|disable)
                return 0
                ;;
            s|skip)
                SKIP_KEYD_SETUP="true"
                warn "Skipping keyd setup by user choice."
                return 0
                ;;
            a|abort)
                err "Aborting keyboard shortcut setup by user choice."
                exit 1
                ;;
            *)
                warn "Invalid choice. Please select d, s, or a."
                ;;
        esac
    done
}

disable_conflicting_remappers() {
    info "Step 0.5: Checking for conflicting key remapping services..."

    mkdir -p "$(dirname "$CONFLICT_STATE_FILE")"
    : > "$CONFLICT_STATE_FILE"

    local -a active_system_units=()
    local -a active_user_units=()
    local -a known_processes=(kanata kmonad xremap xkeysnail keymapperd keymapper input-remapper-service input-remapper udevmon ktrl)

    mapfile -t active_system_units < <(
        systemctl list-units --type=service --state=active --no-legend --plain 2>/dev/null |
            awk '{print $1}' |
            grep -E '^(kanata|kmonad|input-remapper|input-remapper-service|xremap|xkeysnail|keymapperd|keymapper|udevmon|ktrl)(@|\.service)' || true
    )

    mapfile -t enabled_system_units < <(
        systemctl list-unit-files --type=service --no-legend --plain 2>/dev/null |
            awk '$2=="enabled" {print $1}' |
            grep -E '^(kanata|kmonad|input-remapper|input-remapper-service|xremap|xkeysnail|keymapperd|keymapper|udevmon|ktrl)(@|\.service)' || true
    )

    if (( ${#enabled_system_units[@]} > 0 )); then
        active_system_units+=("${enabled_system_units[@]}")
    fi

    mapfile -t active_user_units < <(
        systemctl --user list-units --type=service --state=active --no-legend --plain 2>/dev/null |
            awk '{print $1}' |
            grep -E '^(kanata|kmonad|input-remapper|input-remapper-service|xremap|xkeysnail|keymapperd|keymapper|ktrl)(@|\.service)' || true
    )

    mapfile -t enabled_user_units < <(
        systemctl --user list-unit-files --type=service --no-legend --plain 2>/dev/null |
            awk '$2=="enabled" {print $1}' |
            grep -E '^(kanata|kmonad|input-remapper|input-remapper-service|xremap|xkeysnail|keymapperd|keymapper|ktrl)(@|\.service)' || true
    )

    if (( ${#enabled_user_units[@]} > 0 )); then
        active_user_units+=("${enabled_user_units[@]}")
    fi

    if (( ${#active_system_units[@]} > 0 )); then
        mapfile -t active_system_units < <(printf '%s\n' "${active_system_units[@]}" | awk '!seen[$0]++')
    fi

    if (( ${#active_user_units[@]} > 0 )); then
        mapfile -t active_user_units < <(printf '%s\n' "${active_user_units[@]}" | awk '!seen[$0]++')
    fi

    local -a detected_units=()
    local -a detected_processes=()

    if (( ${#active_system_units[@]} > 0 )); then
        detected_units+=("${active_system_units[@]}")
    fi

    if (( ${#active_user_units[@]} > 0 )); then
        detected_units+=("${active_user_units[@]}")
    fi

    for proc in "${known_processes[@]}"; do
        if pgrep -x "$proc" >/dev/null 2>&1; then
            detected_processes+=("$proc")
        fi
    done

    if (( ${#detected_units[@]} == 0 && ${#detected_processes[@]} == 0 )); then
        ok "No active conflicting remapper services detected."
        return 0
    fi

    warn "Detected potential conflicting remappers."
    if (( ${#detected_units[@]} > 0 )); then
        warn "Detected service units: ${detected_units[*]}"
    fi
    if (( ${#detected_processes[@]} > 0 )); then
        warn "Detected processes: ${detected_processes[*]}"
    fi

    ask_conflict_action

    if [[ "$SKIP_KEYD_SETUP" == "true" ]]; then
        return 0
    fi

    for unit in "${active_system_units[@]}"; do
        warn "Disabling conflicting system service: $unit"
        if sudo systemctl disable --now "$unit" 2>/dev/null; then
            echo "system:$unit" >> "$CONFLICT_STATE_FILE"
        else
            err "Failed to disable conflicting service: $unit"
        fi
    done

    for unit in "${active_user_units[@]}"; do
        warn "Disabling conflicting user service: $unit"
        if systemctl --user disable --now "$unit" 2>/dev/null; then
            echo "user:$unit" >> "$CONFLICT_STATE_FILE"
        else
            err "Failed to disable conflicting user service: $unit"
        fi
    done

    local -a still_running=()
    for proc in "${known_processes[@]}"; do
        if pgrep -x "$proc" >/dev/null 2>&1; then
            still_running+=("$proc")
        fi
    done

    if (( ${#still_running[@]} > 0 )); then
        warn "Attempting to terminate leftover remapper process(es): ${still_running[*]}"
        for proc in "${still_running[@]}"; do
            sudo pkill -x "$proc" 2>/dev/null || true
            pkill -x "$proc" 2>/dev/null || true
        done

        still_running=()
        for proc in "${known_processes[@]}"; do
            if pgrep -x "$proc" >/dev/null 2>&1; then
                still_running+=("$proc")
            fi
        done
    fi

    if (( ${#still_running[@]} > 0 )); then
        err "Detected active key remapper process(es) still running: ${still_running[*]}"
        warn "Disabling keyd as a safety guard to prevent keyboard lockups and sudo auth spam."
        sudo systemctl disable --now keyd 2>/dev/null || true
        err "To avoid keyboard lockups/conflicts, stop those remappers and rerun this step."
        exit 1
    fi

    if [[ -s "$CONFLICT_STATE_FILE" ]]; then
        ok "Conflicting remapper services were disabled (recorded at $CONFLICT_STATE_FILE)."
    fi
}

CONFIG_FILE="$HOME/.config/kglobalshortcutsrc"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE_DIR="${BUNDLE_DIR:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
BACKUP_DIR="$BUNDLE_DIR/backups"
BACKUP_FILE="$BACKUP_DIR/kglobalshortcutsrc_$(date +%Y%m%d_%H%M%S)"

SWHKDRC_FILE="$SCRIPT_DIR/shortcuts.md"

echo
echo "========================================================"
echo "  Quickshell Keyboard Shortcut Deployment (keyd)"
echo "========================================================"

# ----------------------------------------------------------------------------
# SUDO Setup (Inherited or Standalone)
# ----------------------------------------------------------------------------
sudo -v || exit 1
(while true; do sudo -n true; sleep 55; done) 2>/dev/null &
SUDO_LOOP_PID=$!
trap 'kill $SUDO_LOOP_PID 2>/dev/null || true' EXIT

# ----------------------------------------------------------------------------
# Step 0: Ensure keyd is installed and running
# ----------------------------------------------------------------------------
info "Step 0: Checking for keyd..."
if ! command -v keyd &> /dev/null; then
    if [[ "$BASE_DISTRO" == "arch" ]]; then
        warn "keyd not found. Attempting to install keyd via yay..."
        yay -S --noconfirm keyd || { err "Failed to install keyd."; exit 1; }
    elif [[ "$BASE_DISTRO" == "fedora" ]]; then
        warn "keyd not found. Attempting to install keyd via dnf from COPR..."
        sudo dnf copr enable alternateved/keyd -y || true
        sudo dnf install -y keyd || { err "Failed to install keyd."; exit 1; }
    fi
    ok "keyd installed."
else
    ok "keyd is already installed."
fi

KEYD_WAS_ACTIVE="false"
if systemctl is-active --quiet keyd 2>/dev/null; then
    KEYD_WAS_ACTIVE="true"
    info "Stopping keyd temporarily while checking other remappers..."
    sudo systemctl stop keyd 2>/dev/null || warn "Could not stop keyd before conflict checks (continuing)."
fi

disable_conflicting_remappers

if [[ "$SKIP_KEYD_SETUP" == "true" ]]; then
    if [[ "$KEYD_WAS_ACTIVE" == "true" ]]; then
        info "Restoring keyd (it was active before this step)..."
        sudo systemctl start keyd 2>/dev/null || warn "Could not restart keyd."
    fi
    warn "Keyd setup was skipped. Existing remapper setup was left unchanged."
    ok "Keyboard shortcut step completed without enabling keyd."
    exit 0
fi

# Clean up legacy swhkd if present
if systemctl is-active --quiet swhkd@$USER.service 2>/dev/null; then
    sudo systemctl disable --now swhkd@$USER.service 2>/dev/null || true
    systemctl --user disable --now swhks.service 2>/dev/null || true
    ok "Removed legacy swhkd services."
fi

# ----------------------------------------------------------------------------
# Step 1: Backup and resolve collisions in KDE kglobalshortcutsrc
# ----------------------------------------------------------------------------
info "Step 1: Resolving shortcut collisions in KDE..."
if [[ -f "$CONFIG_FILE" ]] && [[ -f "$SWHKDRC_FILE" ]]; then
    mkdir -p "$BACKUP_DIR"
    cp "$CONFIG_FILE" "$BACKUP_FILE"
    
    python3 - "$SWHKDRC_FILE" "$CONFIG_FILE" <<'PYEOF'
import sys
swhkdrc_file = sys.argv[1]
kglobal_file = sys.argv[2]

# 1. Parse markdown code blocks to find shortcut bindings
swhkd_keys = []
in_block = False
with open(swhkdrc_file, 'r') as f:
    for line in f:
        line = line.strip()
        if line.startswith("```"):
            in_block = not in_block
            continue
        if in_block and line and not line.startswith(" ") and not line.startswith("\t") and not line.startswith("#"):
            swhkd_keys.append(line)

# 2. Translate swhkd format to KDE format
kde_keys = []
for k in swhkd_keys:
    parts = k.replace(" ", "").split("+")
    new_parts = []
    for p in parts:
        if p == "super": new_parts.append("Meta")
        elif p == "ctrl": new_parts.append("Ctrl")
        elif p == "alt": new_parts.append("Alt")
        elif p == "shift": new_parts.append("Shift")
        elif p == "enter": new_parts.append("Return")
        elif p == "esc": new_parts.append("Escape")
        elif p == "sysrq": new_parts.append("Print")
        elif p == "period": new_parts.append("Period")
        elif p == "space": new_parts.append("Space")
        elif p == "tab": new_parts.append("Tab")
        elif p == "delete": new_parts.append("Delete")
        elif p == "slash": new_parts.append("Slash")
        elif p.startswith("XF86"): new_parts.append(p)
        else: new_parts.append(p.upper())
    kde_keys.append("+".join(new_parts))

# 3. Process kglobalshortcutsrc to unbind collisions
with open(kglobal_file, 'r') as f:
    lines = f.readlines()

out = []
changed = False
for line in lines:
    if "=" in line and not line.strip().startswith("["):
        k, v = line.split("=", 1)
        parts = v.split(",")
        if len(parts) >= 1:
            bindings = parts[0].split("\t")
            new_bindings = []
            for b in bindings:
                b_clean = b.strip()
                if b_clean in kde_keys:
                    print(f"    Unbinding collision: {b_clean} from '{k.strip()}'")
                    changed = True
                else:
                    new_bindings.append(b)
            
            if not new_bindings:
                parts[0] = "none"
            else:
                parts[0] = "\t".join(new_bindings)
            
            line = f"{k}={','.join(parts)}"
    out.append(line)

if changed:
    with open(kglobal_file, 'w') as f:
        f.writelines(out)
else:
    print("    No collisions found.")
PYEOF
    ok "KDE collision check complete."
else
    warn "kglobalshortcutsrc or configuration not found - skipping collision check."
fi

# ----------------------------------------------------------------------------
# Step 2: Deploy keyd configuration (native kernel level execution)
# ----------------------------------------------------------------------------
info "Step 2: Deploying keyd configuration..."

if [[ ! -f "$SWHKDRC_FILE" ]]; then
    err "swhkdrc not found at $SWHKDRC_FILE!"
    exit 1
fi


cat << 'EOF' > /tmp/convert_to_keyd.py
import sys, os
import shlex
import shutil

def parse_key(k):
    k = k.strip().lower()
    mapping = {
        'super': 'meta', 'ctrl': 'control', 'alt': 'alt', 'shift': 'shift',
        'return': 'enter', 'print': 'sysrq', 'xf86audioplay': 'playpause',
        'xf86audionext': 'nextsong', 'xf86audioprev': 'previoussong',
        'xf86audiomute': 'mute', 'xf86audiomicmute': 'micmute',
        'xf86audiolowervolume': 'volumedown', 'xf86audioraisevolume': 'volumeup',
        'xf86monbrightnessdown': 'brightnessdown', 'xf86monbrightnessup': 'brightnessup',
        'delete': 'delete', 'escape': 'esc', 'space': 'space', 'tab': 'tab',
        'period': 'dot', 'slash': 'slash'
    }
    parts = [mapping.get(p.strip(), p.strip()) for p in k.split('+')]
    mods = [p for p in parts if p in ['meta', 'control', 'alt', 'shift']]
    keys = [p for p in parts if p not in ['meta', 'control', 'alt', 'shift']]
    return mods, keys[0] if keys else ''

uid = os.environ.get('UID', '1000')
user = os.environ.get('USER', __import__('getpass').getuser())
wayland_display = os.environ.get('WAYLAND_DISPLAY', 'wayland-0')
display = os.environ.get('DISPLAY', ':0')
runuser_cmd = (
    shutil.which('runuser')
    or ('/usr/sbin/runuser' if os.path.exists('/usr/sbin/runuser') else None)
    or ('/usr/bin/runuser' if os.path.exists('/usr/bin/runuser') else None)
    or 'runuser'
)

lines = open(sys.argv[1]).read().strip().split('\n')
sections = {'main': []}

in_block = False
parsed_lines = []
for line in lines:
    line = line.strip()
    if line.startswith('```'):
        in_block = not in_block
        continue
    if in_block and line and not line.startswith('#'):
        parsed_lines.append(line)

i = 0
while i < len(parsed_lines):
    key = parsed_lines[i]
    i += 1
    if i >= len(parsed_lines): break
    cmd = parsed_lines[i]
    i += 1

    mods, k = parse_key(key)
    if not k: continue
    
    section = "+".join(mods) if mods else "main"
    if section not in sections:
        sections[section] = []
        
    cmd = cmd.replace("~", f"/home/{user}")
    wrapped = (
        f"{runuser_cmd} -u {user} -- env "
        f"WAYLAND_DISPLAY={wayland_display} "
        f"DISPLAY={display} "
        f"XDG_RUNTIME_DIR=/run/user/{uid} "
        f"DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/{uid}/bus "
        f"sh -lc {shlex.quote(cmd)}"
    )
    sections[section].append(f"{k} = command({wrapped})")

# Keep right shift as right shift for MangoHud and other keycode-sensitive apps.
if "rightshift = rightshift" not in sections["main"]:
    sections["main"].insert(0, "rightshift = rightshift")

out = ["[ids]", "*", ""]
for sec, items in sections.items():
    out.append(f"[{sec}]")
    out.extend(items)
    out.append("")

with open(sys.argv[2], 'w') as f:
    f.write('\n'.join(out))
EOF

python3 /tmp/convert_to_keyd.py "$SWHKDRC_FILE" /tmp/quickshell.conf
sudo mkdir -p /etc/keyd
sudo cp /tmp/quickshell.conf /etc/keyd/quickshell.conf
sudo systemctl enable keyd
sudo systemctl restart keyd

ok "keyd native configuration deployed."

info "Step 3: Reloading KDE shortcut daemon..."
kbuildsycoca6 --noincremental 2>/dev/null || true
systemctl --user restart plasma-kglobalaccel.service 2>/dev/null || true
ok "KDE reloaded."

echo
echo -e "${GREEN}========================================================${RST}"
echo -e "${GREEN}  Custom shortcuts deployed securely to kernel space.${RST}"
echo -e "${GREEN}  Native keyd is active and bypassing display servers.${RST}"
echo -e "${GREEN}========================================================${RST}"
echo
