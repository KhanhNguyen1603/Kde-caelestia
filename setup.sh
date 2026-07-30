#!/usr/bin/env bash
# ==============================================================
#   Caelestia KDE Port - Unified Installer
#
#   Original Hyprland dots: Caelestia
#   KDE port and modifications: ladybug-me
#   Installer behavior: idempotent and safe for reruns
# ==============================================================

set -uo pipefail
export CAELESTIA_SETUP_RUNNING=1

# Hide cursor immediately for cleaner output
tput civis 2>/dev/null || true

# -- Paths ---------------------------------------------------------------------
BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$BUNDLE_DIR/scripts"
export BUNDLE_DIR
export INSTALL_START_EPOCH="$(date +%s)"

# Prevent concurrent setup runs from racing on git/CMake/config writes.
# Only the true outer (pre-tmux) invocation acquires this lock. The
# script re-execs itself inside a tmux session (CAELESTIA_TMUX_MASTER=1)
# to run the actual install, and that inner process is a *child* of the
# outer one, which is still alive (blocked on `tmux attach-session`) and
# still holding fd 9 — so if the inner process tried to flock the same
# file it would always fail against its own parent. Concurrency is
# already fully protected by the outer instance holding the lock for
# its entire lifetime.
if [[ "${CAELESTIA_TMUX_MASTER:-0}" == "0" ]]; then
    exec 9>"${XDG_RUNTIME_DIR:-/tmp}/caelestia-setup.lock"
    flock -n 9 || { echo "Another Caelestia setup is already running."; exit 1; }
fi

detect_base_distro() {
    local detected="unknown"

    if [[ -f /etc/os-release ]]; then
       # shellcheck disable=SC1091
        . /etc/os-release
        case "$ID" in
            arch|cachyos|endeavouros|manjaro|artix)
                detected="arch"
                ;;
            fedora|nobara|bazzite|rhel|centos|almalinux|rocky)
                detected="fedora"
                ;;
            *)
                if echo "${ID_LIKE:-}" | grep -iq "arch"; then
                    detected="arch"
                elif echo "${ID_LIKE:-}" | grep -iq "fedora"; then
                    detected="fedora"
                fi
                ;;
        esac
    fi

    if [[ "$detected" == "unknown" ]]; then
        if command -v pacman >/dev/null 2>&1; then
            detected="arch"
        elif command -v dnf >/dev/null 2>&1; then
            detected="fedora"
        fi
    fi

    echo "$detected"
}

silent_refresh_pacman_sources() {
    if [[ "$BASE_DISTRO" != "arch" ]]; then
        return 0
    fi

    local have_root=0
    if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
        have_root=1
    else
        # Ask for sudo up front (this prompts interactively if there's no
        # cached/NOPASSWD ticket) instead of silently skipping every step
        # below with `sudo -n`. A single successful `sudo -v` here caches
        # credentials for the rest of this function (and the real install
        # steps later), so the user is only prompted once.
        echo "[INFO]  Requesting sudo access to refresh/rank pacman mirrors..."
        if sudo -v; then
            have_root=1
        else
            echo "[WARN]  Skipping pacman mirror refresh/ranking (sudo access not available)."
        fi
    fi

    if (( have_root )); then
        # Use sudo -n (non-interactive) for all subsequent commands — the
        # upfront sudo -v above already cached the credential ticket, so
        # -n will succeed silently without re-prompting. If the ticket
        # expires, individual steps degrade gracefully via || true.
        as_root() {
            if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
                "$@"
            else
                sudo -n "$@"
            fi
        }

        # Reflector: rank pacman mirrors by speed. Install on-the-fly if
        # missing (single -Sy, not -Syy).
        if ! command -v reflector >/dev/null 2>&1; then
            as_root pacman -Sy --noconfirm reflector >/dev/null 2>&1 || true
        fi

        if command -v reflector >/dev/null 2>&1; then
            # Without a --country filter, reflector's candidate pool is every
            # mirror on earth (it only filters by "recently synced", not by
            # distance) - it then speed-ranks whatever it picked, but a mirror
            # halfway around the world can still "win" the rate test yet be
            # unreliable/overloaded/blocked in practice, leaving pacman to churn
            # through dead UK/AU/CN/etc. mirrors during the real download. Best-
            # effort geolocate to scope candidates to the local country; silently
            # fall back to the previous global behaviour if that lookup fails
            # (offline, API down, etc.) rather than hard-failing the install.
            local reflector_country
            reflector_country=$(curl -fsSL --max-time 3 https://ipapi.co/country_name/ 2>/dev/null || true)
            local -a reflector_args=(--latest 20 --protocol https --sort rate)
            if [[ -n "$reflector_country" ]]; then
                echo "[INFO]  Ranking pacman mirrors by download speed (country: $reflector_country)..."
                reflector_args+=(--country "$reflector_country")
            else
                echo "[INFO]  Ranking pacman mirrors by download speed (country detection failed, using global pool)..."
            fi

            as_root reflector "${reflector_args[@]}" --save /etc/pacman.d/mirrorlist >/dev/null 2>&1 || echo "[WARN]  reflector failed, continuing with current mirrors."
        fi

        # CachyOS-based installs pull their (differently-versioned) packages
        # from a separate cachyos-mirrorlist that reflector above never
        # touches. cachyos-rate-mirrors re-ranks that (and
        # cachyos-v3/v4-mirrorlist) with proper geoip + real throughput
        # testing - without this, installs can be stuck on a slow/
        # oversubscribed default mirror even on a fast connection.
        if command -v cachyos-rate-mirrors >/dev/null 2>&1; then
            echo "[INFO]  Ranking CachyOS mirrors by download speed..."
            as_root cachyos-rate-mirrors >/dev/null 2>&1 || echo "[WARN]  cachyos-rate-mirrors failed, continuing with current mirrors."
        fi

        # Pre-install dos2unix if it's missing, so the CRLF-normalization
        # step later (normalize_line_endings_first) doesn't need to
        # re-prompt for sudo when it calls run_arch_pacman_install.
        if ! command -v dos2unix >/dev/null 2>&1; then
            as_root pacman -Sy --noconfirm dos2unix >/dev/null 2>&1 || true
        fi

        as_root pacman -Sy --noconfirm >/dev/null 2>&1 || echo "[WARN]  Failed to refresh pacman sources early. Continuing..."
        unset -f as_root
    fi
}

run_arch_pacman_install() {
    local -a pkgs=("$@")
    local -a pacman_args=(-S --needed --noconfirm)

    if (( ${#pkgs[@]} == 0 )); then
        return 0
    fi

    if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
        pacman -Sy --noconfirm >/dev/null 2>&1 || echo "[WARN]  Failed to refresh pacman sources before install. Continuing..."
        pacman "${pacman_args[@]}" "${pkgs[@]}" && return 0

        echo "[WARN]  pacman install failed. Refreshing sources and retrying once..."
        pacman -Sy --noconfirm >/dev/null 2>&1 || true
        pacman "${pacman_args[@]}" "${pkgs[@]}"
        return $?
    fi

    sudo pacman -Sy --noconfirm >/dev/null 2>&1 || echo "[WARN]  Failed to refresh pacman sources before install. Continuing..."
    sudo pacman "${pacman_args[@]}" "${pkgs[@]}" && return 0

    echo "[WARN]  pacman install failed. Refreshing sources and retrying once..."
    sudo pacman -Sy --noconfirm >/dev/null 2>&1 || true
    sudo pacman "${pacman_args[@]}" "${pkgs[@]}"
}

export BASE_DISTRO="$(detect_base_distro)"

# Mirror refresh and CRLF normalization only run in the outer (pre-tmux)
# shell. The script re-execs itself inside a tmux session later, and
# those steps are pointless (and re-prompt for sudo) the second time.
if [[ "${CAELESTIA_TMUX_MASTER:-0}" == "0" ]]; then
    silent_refresh_pacman_sources
fi

normalize_line_endings_first() {
    export BASE_DISTRO="$(detect_base_distro)"
    local -a crlf_files=()
    local convert_choice=""

    mapfile -t crlf_files < <(
        find "$BUNDLE_DIR" -path "$BUNDLE_DIR/.git" -prune -o -type f -name '*.sh' -print0 | \
            xargs -0 grep -Il $'\r' 2>/dev/null || true
    )

    if (( ${#crlf_files[@]} == 0 )); then
        return 0
    fi

    echo "[WARN]  Detected ${#crlf_files[@]} file(s) with CRLF line endings."
    while true; do
        read -r -p "Convert all files under this repo to LF with dos2unix? [Y/n]: " convert_choice
        convert_choice="${convert_choice:-y}"

        case "${convert_choice,,}" in
            y|yes)
                if ! command -v dos2unix >/dev/null 2>&1; then
                    echo "[WARN]  dos2unix is not installed. Attempting to install it now..."
                    case "$BASE_DISTRO" in
                        arch)
                            run_arch_pacman_install dos2unix || return 1
                            ;;
                        fedora)
                            sudo dnf install -y dos2unix || return 1
                            ;;
                        *)
                            echo "[WARN]  Could not detect distro for automatic dos2unix installation."
                            return 1
                            ;;
                    esac
                    echo "[OK]    dos2unix installed."
                fi

                (
                    cd "$BUNDLE_DIR" || exit 1
                    printf '%s\0' "${crlf_files[@]}" | xargs -0 -r dos2unix --
                ) || return 1

                echo "[OK]    Line endings normalized to LF."
                return 0
                ;;
            n|no)
                echo "[WARN]  Skipping line ending normalization by user choice."
                return 0
                ;;
            *)
                echo "Please answer with y or n."
                ;;
        esac
    done
}

if [[ "${CAELESTIA_TMUX_MASTER:-0}" == "0" ]]; then
    if ! normalize_line_endings_first; then
        echo "[FATAL] Line ending normalization step failed. Aborting installer." >&2
        exit 1
    fi
fi

BIN="$BUNDLE_DIR/caelestia-install"

if [[ "${CAELESTIA_TMUX_MASTER:-0}" == "0" ]]; then
    echo -n "Compiling Caelestia installer"
    {
        while true; do
            printf "."
            sleep 0.5
            printf "."
            sleep 0.5
            printf "."
            sleep 0.5
            printf "\b\b\b   \b\b\b"
        done
    } &
    SPINNER_PID=$!

    # Check and install requirements
    MISSING_PKGS=()
    if ! command -v g++ >/dev/null 2>&1; then
        MISSING_PKGS+=("g++")
    fi
    if ! command -v cmake >/dev/null 2>&1; then
        MISSING_PKGS+=("cmake")
    fi
    if ! command -v make >/dev/null 2>&1; then
        MISSING_PKGS+=("make")
    fi
    # tmux is used for the split-pane installer view unless explicitly disabled
    if [[ "${CAELESTIA_USE_TMUX:-1}" == "1" ]] && ! command -v tmux >/dev/null 2>&1; then
        MISSING_PKGS+=("tmux")
    fi

    if [ ${#MISSING_PKGS[@]} -ne 0 ]; then
        kill $SPINNER_PID 2>/dev/null || true
        echo ""
        echo "Missing build tools: ${MISSING_PKGS[*]}. Installing..."
        if [[ "$BASE_DISTRO" == "arch" ]]; then
            if [[ "${CAELESTIA_USE_TMUX:-1}" == "1" ]]; then
                run_arch_pacman_install base-devel cmake tmux
            else
                run_arch_pacman_install base-devel cmake
            fi
        elif [[ "$BASE_DISTRO" == "fedora" ]]; then
            if [[ "${CAELESTIA_USE_TMUX:-1}" == "1" ]]; then
                sudo dnf install -y gcc-c++ cmake make tmux
            else
                sudo dnf install -y gcc-c++ cmake make
            fi
        else
            echo "Could not auto-install build tools. Please install manually: ${MISSING_PKGS[*]}"
            exit 1
        fi
        echo -n "Compiling Caelestia installer"
        {
            while true; do
                printf "."
                sleep 0.5
                printf "."
                sleep 0.5
                printf "."
                sleep 0.5
                printf "\b\b\b   \b\b\b"
            done
        } &
        SPINNER_PID=$!
    fi

    BUILD_DIR="$BUNDLE_DIR/installer/build"
    BUILD_LOG="/tmp/caelestia_build.log"
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    (
        cd "$BUILD_DIR" || exit 1
        cmake -DCMAKE_BUILD_TYPE=Release .. >"$BUILD_LOG" 2>&1 || exit 1
        make -j"$(nproc 2>/dev/null || echo 1)" >>"$BUILD_LOG" 2>&1 || exit 1
    ) || {
        kill $SPINNER_PID 2>/dev/null || true
        echo ""
        echo "[FATAL] Failed to build the Caelestia installer." >&2
        echo "--- build log (last 60 lines) ---"
        tail -n 60 "$BUILD_LOG" 2>/dev/null || cat "$BUILD_LOG" 2>/dev/null
        echo "--- end build log ---"
        echo "Full log saved to: $BUILD_LOG"
        exit 1
    }
    
    kill $SPINNER_PID 2>/dev/null || true
    wait $SPINNER_PID 2>/dev/null || true
    echo ""

    rm -f "$BIN"
    cp "$BUILD_DIR/caelestia-install" "$BIN" || {
        echo "[FATAL] Failed to copy the compiled Caelestia installer to $BIN." >&2
        exit 1
    }
fi

cleanup_install_state() {
    tput cnorm 2>/dev/null || true
    if [[ -f /tmp/caelestia_inhibit.pid ]]; then
        kill -9 "$(cat /tmp/caelestia_inhibit.pid)" 2>/dev/null || true
    fi
    if [[ -f /tmp/caelestia_kde_inhibit.cookie ]]; then
        qdbus6 org.freedesktop.ScreenSaver /ScreenSaver org.freedesktop.ScreenSaver.UnInhibit "$(cat /tmp/caelestia_kde_inhibit.cookie)" 2>/dev/null || true
    fi
    rm -f /tmp/caelestia_inhibit.pid /tmp/caelestia_kde_inhibit.cookie
    
    if [[ -n "${TMUX:-}" && "${CAELESTIA_TMUX_MASTER:-0}" == "1" ]]; then
        tmux kill-session -t caelestia_install 2>/dev/null || true
        rm -f /tmp/caelestia_cmd /tmp/caelestia_status
    fi
    rm -f /tmp/caelestia_tmux_wrapper.sh
}
trap cleanup_install_state EXIT

if [[ -z "${TMUX:-}" && "${CAELESTIA_NO_TMUX:-0}" == "0" && "${CAELESTIA_USE_TMUX:-1}" == "1" ]]; then
    # Kill any stale session first
    tmux kill-session -t caelestia_install 2>/dev/null || true
    
    export CAELESTIA_TMUX_MASTER=1
    rm -f /tmp/caelestia_cmd /tmp/caelestia_status
    rm -f /tmp/caelestia_installer_err.log
    mkfifo /tmp/caelestia_cmd
    mkfifo /tmp/caelestia_status
    
    # Build a wrapper script instead of an inline command string. This
    # guarantees that no matter how (or how fast) the inner script/binary
    # exits or crashes, the tmux pane ALWAYS prints a clear message and
    # waits for a keypress before the pane's shell exits — so the pane
    # (and therefore the session and the attached terminal) can never
    # vanish silently before the user can read what happened.
    WRAPPER_SCRIPT="/tmp/caelestia_tmux_wrapper.sh"
    printf -v args_str '%q ' "$0" "$@"
    cat > "$WRAPPER_SCRIPT" <<WRAPPER_EOF
#!/usr/bin/env bash
bash $args_str
ec=\$?
echo ""
echo "============================================================"
echo "  installer session ended (exit code: \$ec)"
echo "============================================================"
echo ""
echo "Press Enter to close this window..."
read -r
exit \$ec
WRAPPER_EOF
    chmod +x "$WRAPPER_SCRIPT"

    tmux new-session -d -s caelestia_install "bash $WRAPPER_SCRIPT"
    # Keep the dead pane visible if the wrapper's process exits with a
    # non-zero code (crash, etc.), so a catastrophic/instant failure can
    # still be inspected instead of the session vanishing outright. A
    # clean, successful run (exit 0) still closes the session normally.
    tmux set-option -t caelestia_install remain-on-exit failed
    tmux set-option -t caelestia_install mouse on
    
    tmux attach-session -t caelestia_install
    _tmux_exit=$?

    # If the tmux session ended, the inner script may have left a log.
    # Check it here in the outer terminal so the user sees the diagnostic
    # even though the tmux window already closed.
    _needs_pause=0
    if [[ -s /tmp/caelestia_installer_err.log ]]; then
        _reached_done=0
        if grep -q '\[installer\] done (success)' /tmp/caelestia_installer_err.log 2>/dev/null; then
            _reached_done=1
        fi
        if [[ $_reached_done -eq 0 ]]; then
            stty sane 2>/dev/null || true
            tput cnorm 2>/dev/null || true
            echo ""
            echo "============================================================"
            echo "  INSTALLER DID NOT COMPLETE"
            echo "============================================================"
            echo ""
            echo "--- stderr output from installer ---"
            cat /tmp/caelestia_installer_err.log
            echo "--- end stderr ---------------------"
            echo ""
            _needs_pause=1
        fi
    elif [[ $_tmux_exit -ne 0 ]]; then
        stty sane 2>/dev/null || true
        tput cnorm 2>/dev/null || true
        echo ""
        echo "============================================================"
        echo "  INSTALLER SESSION ENDED (exit code: $_tmux_exit)"
        echo "  No stderr log was produced — the binary may have crashed"
        echo "  or the tmux session may have failed to start entirely"
        echo "  (check for a stale tmux server or /tmp/caelestia_cmd issues)."
        echo "============================================================"
        echo ""
        _needs_pause=1
    fi

    # Never let the terminal window auto-close before the user can read
    # the diagnostic above — some terminal emulators close instantly when
    # the launching shell exits, which is what caused the "flash and vanish"
    # behavior previously.
    if [[ $_needs_pause -eq 1 ]]; then
        echo "Press Enter to close this window..."
        read -r
    fi

    exit $_tmux_exit
fi

# Verify the compiled binary exists and is executable before we try to run it
if [[ ! -x "$BIN" ]]; then
    echo ""
    echo "============================================================"
    echo "  FATAL: Installer binary missing or not executable"
    echo "  Expected at: $BIN"
    echo "============================================================"
    echo ""
    echo "This usually means the C++ compilation step failed silently."
    echo "Check that g++, cmake, and make are installed correctly."
    echo ""
    echo "Press Enter to close this window..."
    read -r
    exit 1
fi

# Run the installer, capturing stderr so error messages survive terminal reset
_installer_start=$(date +%s)
"$BIN" "$@" 2>/tmp/caelestia_installer_err.log
_exit_code=$?
_installer_end=$(date +%s)
_installer_elapsed=$((_installer_end - _installer_start))

# Determine if the installer completed normally.
# A real install takes minutes; anything under 3 seconds is a premature exit.
# Also check that the "done (success)" marker appears in stderr — if the binary
# exits 0 without ever printing it, something went wrong before phase 6.
_reached_done=0
if grep -q '\[installer\] done (success)' /tmp/caelestia_installer_err.log 2>/dev/null; then
    _reached_done=1
fi

_show_diagnostic=0
_diag_title=""

if [[ $_exit_code -ne 0 ]]; then
    _show_diagnostic=1
    _diag_title="INSTALLER FAILED (exit code: $_exit_code)"
elif [[ $_reached_done -eq 0 ]]; then
    _show_diagnostic=1
    if [[ $_installer_elapsed -lt 3 ]]; then
        _diag_title="INSTALLER EXITED PREMATURELY (ran ${_installer_elapsed}s, exit 0)"
    else
        _diag_title="INSTALLER EXITED UNEXPECTEDLY (no completion marker)"
    fi
elif [[ -s /tmp/caelestia_installer_err.log ]]; then
    _show_diagnostic=1
    _diag_title="INSTALLER COMPLETED (stderr output captured below)"
fi

if [[ $_show_diagnostic -eq 1 ]]; then
    # Reset terminal in case the binary left it in raw/alt-screen mode
    stty sane 2>/dev/null || true
    tput cnorm 2>/dev/null || true
    printf '\033[0m\033[?1049l\033[?25h' 2>/dev/null || true

    echo ""
    echo "============================================================"
    echo "  $_diag_title"
    echo "============================================================"
    echo ""

    if [[ -s /tmp/caelestia_installer_err.log ]]; then
        echo "--- stderr output ---"
        cat /tmp/caelestia_installer_err.log
        echo "--- end stderr ------"
        echo ""
    else
        echo "(no stderr output captured)"
        echo ""
    fi

    if [[ $_exit_code -eq 139 ]]; then
        echo "Exit code 139 = SIGSEGV (segmentation fault / memory crash)."
    elif [[ $_exit_code -eq 127 ]]; then
        echo "Exit code 127 = command not found (missing shared library or binary)."
    elif [[ $_exit_code -eq 134 ]] || [[ $_exit_code -eq 135 ]]; then
        echo "Exit code $_exit_code = SIGABRT (aborted, possible assertion failure)."
    elif [[ $_exit_code -eq 0 ]] && [[ $_reached_done -eq 0 ]]; then
        echo "Binary exited cleanly (code 0) but never reached the summary screen."
        echo "This usually means it returned early before phase 6."
    fi
    echo ""

    echo "Press Enter to close this window..."
    read -r
fi

exit $_exit_code
