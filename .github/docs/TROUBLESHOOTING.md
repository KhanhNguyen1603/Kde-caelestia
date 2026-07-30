# TROUBLESHOOTING

## Caelestia KDE Port — Troubleshooting Guide

This document catalogs known failure modes, error conditions, and edge cases discovered through analysis of the installer, shell build system, scripts, documentation, and runtime architecture of the Caelestia KDE port.

---

## Table of Contents

1. [Build & Compilation Issues](#1-build--compilation-issues)
2. [Dependency & Package Issues](#2-dependency--package-issues)
3. [Runtime Issues — Shell](#3-runtime-issues--shell)
4. [Runtime Issues — Lock Screen](#4-runtime-issues--lock-screen)
5. [Configuration Issues](#5-configuration-issues)
6. [Network & Proxy Issues](#6-network--proxy-issues)
7. [Tmux & Terminal Issues](#7-tmux--terminal-issues)
8. [KDE & Plasma Specific Issues](#8-kde--plasma-specific-issues)
9. [Post-Install Issues](#9-post-install-issues)
10. [Uninstall Issues](#10-uninstall-issues)
11. [Diagnostic Commands Reference](#11-diagnostic-commands-reference)

---

## 1. Build & Compilation Issues

### 1.1 C++ Installer Compilation Fails

The installer compiles the `caelestia-install` TUI binary during `setup.sh`. The CMake project requires **C++20** (`CMAKE_CXX_STANDARD 20`).

| Symptom | Likely Cause | Fix |
|---|---|---|
| `g++: command not found` | Build tools not installed | Arch: `sudo pacman -S base-devel` — Fedora: `sudo dnf install gcc-c++` |
| `cmake: command not found` | CMake missing | Auto-installer handles this if `BASE_DISTRO` is detected; otherwise install manually |
| `[FATAL] Failed to build the Caelestia installer` | General CMake/make error | Read build log: `cat /tmp/caelestia_build.log` |
| Compiler error about modern C++ features | GCC older than 10 | Ensure GCC 10+ is installed: `g++ --version` |
| Exit 139 (SIGSEGV) at runtime | C++ bug in the TUI | Check stderr log at `/tmp/caelestia_installer_err.log` |
| Exit 127 at runtime | Missing shared library | Run `ldd` on the binary to find missing `.so` files |

### 1.2 Shell / Plugin Compilation Fails

The shell build (`08-build-shell.sh`) requires **Qt 6.9+** and several system libraries. The CMake project in `shell/CMakeLists.txt` uses `qt_standard_project_setup(REQUIRES 6.9)`.

#### Qt / QML Dependencies

| Missing Dependency | CMake Error Clue | Arch Package | Fedora Package |
|---|---|---|---|
| Qt6::Qml / Qt6::Quick | `find_package` failed | `qt6-declarative` | `qt6-qtdeclarative-devel` |
| Qt6::ShaderTools | Shader tool config | `qt6-shadertools` | `qt6-qtshadertools-devel` |
| Qt6::WaylandClient | Wayland client plugin | `qt6-wayland` | `qt6-qtwayland-devel` |
| KF6WindowSystem | KWindowSystem not found | `kwindowsystem` | `kf6-kwindowsystem-devel` |
| KGlobalAccel | kglobalaccel not found | `kglobalaccel` | `kf6-kglobalaccel-devel` |
| KPipeWire | pipewire integration | `kpipewire` | `kf6-kpipewire-devel` |

#### Library Dependencies (pkg_check_modules)

| Library | Arch Package | Fedora Package |
|---|---|---|
| `libqalculate` | `libqalculate` | `libqalculate-devel` |
| `libpipewire-0.3` | `pipewire` | `pipewire-devel` |
| `aubio` | `aubio` | `aubio-devel` |
| `libcava` | `libcava` | `celestelove/libcava` (COPR) |
| `libpulse` | `libpulse` | `pulseaudio-libs-devel` |
| `libpam` | `pam` | `pam-devel` |
| `lm_sensors` (Fedora) | not needed | `lm_sensors-devel` |

**Fedora note:** The custom `cmake/sensorslib.cmake` module loads `lm_sensors`. If it's missing, the build may silently skip sensor support.

### 1.3 "Missing QML Module Metadata" After Build

```text
[ERR] Missing QML module metadata: $HOME/.local/lib/qt6/qml/Caelestia/Config/qmldir
```

This means the CMake install step didn't copy required `qmldir` or `.so` files properly.

**Causes & fixes:**
- **Install prefix mismatch:** The build uses `-DCMAKE_INSTALL_PREFIX=$HOME/.local`. If Qt6 looks for QML modules elsewhere, the module won't load.
- **Stale build artifacts:** Run `rm -rf shell/build shell/plugin/build` before re-running
- **Partial installation:** If CMake install was interrupted, files may be missing. Re-run `08-build-shell.sh`

### 1.4 ccache Not Speeding Up Rebuilds

The project enables ccache in both `installer/CMakeLists.txt` and `shell/CMakeLists.txt`. If rebuilds are still slow:

- Check ccache stats: `ccache -s`
- The cache directory (`~/.cache/ccache`) may be too small — increase it: `ccache -M 5G`
- Debug builds (`-DCMAKE_BUILD_TYPE=Debug`) are much slower; the installer uses `Release`

---

## 2. Dependency & Package Issues

### 2.1 Arch Linux / yay Failures

| Issue | Cause |
|---|---|
| `yay` fails to install | Network issues, AUR down, or PKGBUILD changes. The script (`installDP.sh`) retries individually and falls back to `makepkg -si`. |
| `pacman` errors during install | The script uses `-Sy --noconfirm` (refresh DB) then `-S --needed --noconfirm`. If the system update step (`00a-system-update.sh`) was skipped, partial upgrades can cause conflicts. |

**AUR packages used by Caelestia:**

| AUR Package | Failure Symptoms |
|---|---|
| `quickshell-git` | Shell won't start; autostart fails with exit 127 |
| `caelestia-cli` | `caelestia` command not found; shell falls back to direct `quickshell` calls |
| `kde-material-you-colors` | Colors won't sync with wallpaper |
| `darkly` | KDE theme won't apply |

### 2.2 Fedora / COPR Failures

| Package | COPR / Source | Known Issues |
|---|---|---|
| `quickshell-git` | `errornointernet/quickshell` | COPR may be out of date |
| `gpu-screen-recorder` | `brycensranch/gpu-screen-recorder-git` | May need `ffmpeg` from RPM Fusion |
| `app2unit` | `celestelove/app2unit` | Falls back to `make install` |
| `libcava` | `celestelove/libcava` | Falls back to manual build from GitHub |
| `starship` | `atim/starship` | Stable, rarely fails |
| `wl-clip-persist` | `leloubil/wl-clip-persist` | Needed for clipboard persistence |

**RPM Fusion requirement:** `ffmpeg` with H264 support requires RPM Fusion. The script auto-enables it, but this may fail behind a proxy or on air-gapped systems.

**kde-material-you-colors on Fedora:** Installed via `uv tool install`. Requires `dbus-devel`, `dbus-glib-devel`, and `python3-devel`.

### 2.3 CRLF / dos2unix Failure

If CRLF line endings are detected and `dos2unix` auto-install fails, the installer **aborts** with:

```text
[FATAL] Line ending normalization step failed. Aborting installer.
```

**Fix:** Install `dos2unix` manually, or answer `n` to the CRLF prompt to skip normalization.

### 2.4 Failed Packages Log

Failed packages are logged to:

```text
$XDG_CACHE_HOME/caelestia-kde/failed_packages.txt
```

The installer does **not** abort on package failure — it logs and continues. Check this file after installation if something doesn't work.

---

## 3. Runtime Issues — Shell

### 3.1 Shell Doesn't Start After Login

The shell autostarts via `~/.config/autostart/caelestiashell.desktop` which runs `~/.local/bin/caelestia-autostart.sh`.

| Symptom | Likely Cause |
|---|---|
| Blank screen at login | Shell binary launched but crashed immediately. Check `journalctl --user -xe`. |
| Plasma desktop visible, no shell | Autostart entry didn't execute. Verify the `.desktop` file exists. |
| Shell appears briefly then disappears | Quickshell crashed. Run manually from a terminal. |
| `quickshell: command not found` | Quickshell not in PATH at login. The autostart wrapper resolves the binary path. |

**Manual start for debugging:**
```bash
export QML2_IMPORT_PATH="$HOME/.local/lib/qt6/qml"
export CAELESTIA_LIB_DIR="$HOME/.local/lib/caelestia"
quickshell -d -n -p ~/.config/quickshell/caelestia/shell.qml
```

### 3.2 Environment Variables Not Set On Login

The build script appends to `~/.bashrc` and `~/.config/fish/config.fish`:

```bash
export QML2_IMPORT_PATH="$HOME/.local/lib/qt6/qml"
export CAELESTIA_LIB_DIR="$HOME/.local/lib/caelestia"
```

**Known issues:**
- **Zsh users:** Only `.bashrc` and `fish/config.fish` are updated — add the exports to `~/.zshrc` manually
- **Duplicate lines:** Running the installer multiple times adds duplicate exports
- **Fish users:** The grep check may miss existing entries if they're set via a different mechanism

### 3.3 Window Thumbnails / Screencast Not Working

KWin only grants `zkde_screencast_unstable_v1` to clients whose `.desktop` file lists the protocol.

**Fix:**
```bash
# Verify the desktop file exists
cat ~/.local/share/applications/quickshell.desktop
# Rebuild KService cache
kbuildsycoca6 --noincremental
# Reload KWin
qdbus6 org.kde.KWin /KWin reconfigure
```

If the desktop file is missing, re-run `scripts/10-autostart.sh`.

### 3.4 Material You Colors Not Working

| Symptom | Fix |
|---|---|
| Colors not updating with wallpaper | Check service: `systemctl status --user kde-material-you-colors.service` |
| Service failed to start | On Fedora, installed via `uv`. If `uv` isn't in PATH at login, the service fails. |
| Old schemes accumulating | The installer removes old `MaterialYou*.colors`, but multiple restarts can recreate them. |

**Manual restart:**
```bash
systemctl --user restart kde-material-you-colors.service
journalctl --user -u kde-material-you-colors.service -n 50
```

### 3.5 Screen Recording Issues

| Symptom | Cause |
|---|---|
| Recording appears stuck | `gpu-screen-recorder` not installed or not in PATH |
| Portal dialog doesn't appear | The build script patches `record.py` to restart `plasma-xdg-desktop-portal-kde`. If it doesn't restart in time, the target selector won't show. |
| OpenCV linking errors | Symlinks like `libopencv_core.so.413 → libopencv_core.so.5.0.0` break when OpenCV updates. |

The recorder now verifies both `pidof gpu-screen-recorder` AND that `recording.mp4` exists, preventing false positives from stale PID matches.

### 3.6 Screenshot Issues

The screenshot tool was patched to use `spectacle` (KDE) instead of `grim` (wlroots).

- If `spectacle` isn't installed, screenshots silently fail
- Screenshots are written to `/tmp/qs-screenshot.png` — if `/tmp` is cleaned during the session, this may fail

---

## 4. Runtime Issues — Lock Screen

### 4.1 Lock Screen Shows Default KDE Wallpaper

The lock screen runs inside `plasma-wallpaper-application` as a proxy workaround, because KWin blocks third-party Wayland lock screen clients.

**Diagnostic commands:**
```bash
# Verify plugin is installed
kpackagetool6 --list -t Plasma/Wallpaper
# Read the configured command
kreadconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group net.dosowisko.PlasmaApplicationWallpaper --group General --key command
```

| Symptom | Cause |
|---|---|
| Default KDE wallpaper on lock | `plasma-wallpaper-application` plugin not installed. Install from `src/plasma-wallpaper-application/`: `kpackagetool6 -t Plasma/Wallpaper -i package` |
| Black screen on lock | Quickshell can't connect to the proxy socket. Check QML import paths in the plugin settings. |
| Lock screen ignores input | PAM configuration may be incorrect. Check `shell/assets/pam.d/`. |

### 4.2 High CPU Usage While Locked

The lock screen renders via a nested Wayland compositor using **software compositing** — every frame is rendered on the CPU.

**If CPU usage is >30% while locked:**

1. **Reduce FPS:** In KDE System Settings → Screen Locking → Wallpaper plugin settings, set FPS to `1`–`15`
2. **Remove animated widgets:** Animated lock screen widgets continuously generate frames
3. **Snap values, don't animate:** On timer-updated data (CPU, RAM), use instant value updates rather than `Behavior` animations

**Developer rules (from lock screen architecture):**
- No continuous animations (rotation, marquees, scrolling text)
- Synchronize polling intervals across widgets to batch frame damage
- Don't combine `Behavior` animations with 1-second timer updates
- Set `ShaderEffectSource.live = false` except during transitions

---

## 5. Configuration Issues

### 5.1 Darkly Theme Not Applied

| Symptom | Cause |
|---|---|
| Plasma style unchanged | `APPLY_DARKLY` was set to `false` in the configuration menu |
| Window decorations missing | The installer tries `org.kde.darkly` library, falls back silently to `org.kde.breeze` |
| `lookandfeeltool --apply "Darkly"` failed | The `darkly` package may not be installed (AUR/COPR only) |

**Manual apply:**
```bash
kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "library" "org.kde.darkly"
kwriteconfig6 --file kwinrc --group "org.kde.kdecoration2" --key "theme" "@darkly"
qdbus6 org.kde.KWin /KWin reconfigure
```

### 5.2 KDE OSD Still Showing

The tweak script disables OSD in `plasmarc`, `kdeglobals`, `plasmanotifyrc`, `powerdevilrc`, and `kmixrc`. If OSD still appears:

```bash
systemctl --user restart plasma-plasmashell
```

Some KDE versions (6.1 vs 6.2) may use slightly different config keys.

### 5.3 Wrong Number of Virtual Desktops

The installer configures exactly **5 desktops**. If you had a different count before:
- Re-run `scripts/09-system-tweaks.sh` to re-apply
- The uninstaller resets desktop count to `1`

### 5.4 Keyboard Shortcut Conflicts

Caelestia's `GlobalShortcut` system uses `kglobalacceld`. When it registers a shortcut that conflicts with another app, it "steals" the binding and records it in:

```text
~/.config/caelestia/stolen-shortcuts.json
```

**If shortcuts are missing or wrong:**
```bash
rm -f ~/.config/caelestia/stolen-shortcuts.json
systemctl --user status plasma-kglobalaccel.service
```

If `keyd` is active and manages Meta+1..5, the tweak script skips KWin bindings for those combos to avoid conflicts.

### 5.5 Terminal Sequence Bleeding (Garbled Output)

If ANSI escape sequences leak from the `caelestia` CLI into your terminal:

```bash
cat $XDG_CACHE_HOME/caelestia-kde/failed_patches.txt
```

If `Caelestia CLI Theme Sequence Patch` appears in the failed list, re-run:
```bash
bash scripts/09-system-tweaks.sh
```

---

## 6. Network & Proxy Issues

### 6.1 Pacman Mirror Ranking Fails

The installer uses `reflector` to rank mirrors. Failure modes:
- **Offline:** `curl -fsSL https://ipapi.co/country_name/` fails → falls back to global pool
- **reflector not installed:** Auto-installed via `pacman -Sy reflector`. If that fails, ranking is skipped
- **cachyos-rate-mirrors:** CachyOS-specific; if it fails, existing mirrors are kept

### 6.2 Git / Submodule Failures

The submodule `src/dots` is critical. If `git submodule update --init --recursive` fails:

```text
[ERR] Missing src/dots content. Run: git submodule update --init --recursive src/dots
```

This is a **hard failure** — the installer cannot proceed past config deployment.

**Behind a proxy?**
```bash
git config --global http.proxy http://proxy:port
git config --global https.proxy http://proxy:port
export GIT_SSL_NO_VERIFY=1
```

### 6.3 AUR Builds Fail Behind Proxy

`makepkg -si` downloads sources from various URLs. Set proxy environment variables before running `setup.sh`:
```bash
export http_proxy=http://proxy:port
export https_proxy=http://proxy:port
export ALL_PROXY=http://proxy:port
```

---

## 7. Tmux & Terminal Issues

### 7.1 Tmux Session Doesn't Start Properly

The installer re-execs itself inside a tmux session with split panes.

| Symptom | Cause | Fix |
|---|---|---|
| Session appears then vanishes | Process exited immediately | The wrapper script (`/tmp/caelestia_tmux_wrapper.sh`) should prevent this. Check it exists. |
| `Another Caelestia setup is already running` | Stale lock file | `rm -f "${XDG_RUNTIME_DIR:-/tmp}/caelestia-setup.lock"` |
| `INSTALLER SESSION ENDED (exit code: 1)` with no log | Binary crashed before writing stderr, or `/tmp` was full | Check available disk space |

### 7.2 Worker Pane Communication Fails

The C++ installer communicates with the worker tmux pane via named pipes:
- `/tmp/caelestia_cmd` — command FIFO
- `/tmp/caelestia_status` — status FIFO

**Failure modes:**
- **FIFO deadlock:** If the worker pane's `while read` loop exits, the `O_WRONLY` open blocks. Handled via `O_NONBLOCK` fallback.
- **Safety timeout:** Steps that hang >30 minutes are treated as failed.
- **ENXIO:** If the FIFO reader disappears (pane crash), the step is failed immediately.

### 7.3 Terminal Rendering Problems

The TUI uses advanced terminal escape sequences:

| Feature | Sequence | Terminal Support |
|---|---|---|
| Sync mode (tear-free) | `\x1b[?2026h` / `\x1b[?2026l` | Not all terminals support this |
| Alt-screen buffer | `\x1b[?1049h` | Most terminals support this |
| SIGWINCH handling | Window resize signal | Some tmux configs don't forward SIGWINCH |

**Requirements:**
- 24-bit true color support
- Synchronized Updates (DEC private mode 2026)
- UTF-8 encoding for box-drawing characters

---

## 8. KDE & Plasma Specific Issues

### 8.1 Legacy qs-kwin-bridge Service

The old `qs-kwin-bridge` Python daemon is now **disabled** in favor of native C++ plugins. If you see it running:
```bash
systemctl --user disable --now qs-kwin-bridge.service
```

### 8.2 xdg-desktop-portal-kde

The recording patch restarts `plasma-xdg-desktop-portal-kde` before each recording. This may fail if:
- The portal service is masked
- The user's systemd session is in a bad state

### 8.3 ydotoold (On-Screen Keyboard)

`ydotoold` needs access to `/dev/uinput`. The installer:
1. Creates `/etc/udev/rules.d/80-uinput.rules`
2. Adds user to `input` group
3. Creates sudoers NOPASSWD rule

**If ydotoold doesn't work:**
- Re-login (group changes take effect on next login)
- Verify: `groups $USER` should include `input`
- Verify: `ls -la /run/user/$(id -u)/.ydotool_socket`

### 8.4 Krohnkite Tiling Disabled on Uninstall

The uninstaller disables `krohnkiteEnabled` in `kwinrc`. If you don't have the Krohnkite KWin script installed, this setting is simply ignored.

### 8.5 KWin Script Injection Fails

The plugin injects a temporary KWin script for window tracking. If KWin scripting is disabled:
```bash
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript
```

---

## 9. Post-Install Issues

### 9.1 Shell Not Visible After Install

The shell only runs at **next login**. After the summary screen, the installer asks: *"Would you like to log out now? (y/N)"*

If you chose not to log out:
1. Log out manually (`Super+Ctrl+Q` or KDE menu → Leave → Log Out)
2. Log back in
3. If the shell still doesn't appear, run: `caelestia shell -d`

### 9.2 Installer Exited Prematurely (Marker Check)

The outer `setup.sh` wrapper checks if `[installer] done (success)` appears in stderr:

| Condition | Warning |
|---|---|
| Exit 0 but elapsed < 3 seconds without marker | **"INSTALLER EXITED PREMATURELY"** |
| Exit 0 but elapsed > 3 seconds without marker | **"INSTALLER EXITED UNEXPECTEDLY"** |

### 9.3 CONFIRM_ARG Behavior

The configuration menu sets `CONFIRM_ARG` as `true`/`false`. The installer converts it per-script context:
- Some scripts use `-n "$CONFIRM_ARG"` (non-empty = auto-confirm)
- The C++ code has a known inconsistency — see `Runner.cpp` comments for details

### 9.4 Stale Lock Files

If the script is killed with **SIGKILL** (not SIGTERM), lock files may persist:

| Lock File | Script |
|---|---|
| `${XDG_RUNTIME_DIR:-/tmp}/caelestia-setup.lock` | `setup.sh` |
| `${XDG_RUNTIME_DIR:-/tmp}/caelestia-update.lock` | `update.sh` |

**Always use Ctrl+C (SIGINT)** which is handled gracefully. Remove stale locks:
```bash
rm -f "${XDG_RUNTIME_DIR:-/tmp}/caelestia-setup.lock"
rm -f "${XDG_RUNTIME_DIR:-/tmp}/caelestia-update.lock"
```

### 9.5 Update.sh Fails

| Symptom | Cause |
|---|---|
| `git pull` fails | Uncommitted changes exist. The updater auto-stashes, but conflicts may remain. |
| Submodule update fails | Network issue or GitHub down. Retry later. |
| CMake configure fails | New dependencies added since last install. Check error output. |

---

## 10. Uninstall Issues

### 10.1 No Backups Available

Backups are stored in `$BUNDLE_DIR/backups/YYYYMMDD_HHMMSS/`. If you moved or deleted the repository, backups are gone.

### 10.2 konsave Restore Fails

If the `.knsv` archive is corrupted or konsave can't be installed:
- Falls back to manual restore of individual config files
- If `python3 -m venv` fails (missing `python3-venv`), theme data can't be restored

**Expected warning when restoring a Caelestia backup:**
> *"The selected backup contains Caelestia configurations. Restoring this backup will NOT revert to a clean KDE desktop!"*

### 10.3 Shell RC Files Not Cleaned

The uninstaller uses state files (`shellrc/bashrc.state`, etc.) to determine whether to restore or remove shell config files. If these are missing (older installer version), a fallback `sed` cleanup removes `QML2_IMPORT_PATH` and `CAELESTIA_LIB_DIR` lines.

### 10.4 Package Removal Leaves Dependencies

Package removal is optional. It uses `yay -Rns` / `dnf remove` which does NOT remove:
- Dependencies pulled in automatically (unless `-s` handles it)
- Packages installed outside the defined lists
- `base-devel` or build tools that existed before install

### 10.5 Input Group Membership Persists

The uninstaller runs `sudo gpasswd -d $USER input`. This only works if the user was added to the group during installation, and takes effect on next login.

### 10.6 Failed Patches Tracking

Failed patches are logged to:
```text
$XDG_CACHE_HOME/caelestia-kde/failed_patches.txt
```

Possible entries:
- `Caelestia CLI Hyprctl Mock Patch`
- `Caelestia CLI Record/Dolphin Patch`
- `Caelestia CLI Theme Sequence Patch`

These are **cosmetic** — the shell works without them, but certain features (screenshot, recording, terminal colors) may be degraded.

---

## 11. Diagnostic Commands Reference

### System State Checks

```bash
# KWin reconfigure
qdbus6 org.kde.KWin /KWin reconfigure

# Check user services
systemctl --user list-units | grep -E 'caelestia|quickshell|kde-material-you'

# Check KWin plugins
kwriteconfig6 --file kwinrc --group Plugins --key list

# Verify QML imports
qml6 -p ~/.config/quickshell/caelestia/shell.qml 2>&1 | head -30
```

### Caelestia-Specific Diagnostics

```bash
# Check if the shell binary was built
ls -la ~/.local/lib/qt6/qml/Caelestia/

# Check installed wallpaper plugin
kpackagetool6 --list -t Plasma/Wallpaper

# Read lock screen config
kreadconfig6 --file kscreenlockerrc --group Greeter --key WallpaperPlugin

# View failed packages log
cat $XDG_CACHE_HOME/caelestia-kde/failed_packages.txt 2>/dev/null

# View failed patches log
cat $XDG_CACHE_HOME/caelestia-kde/failed_patches.txt 2>/dev/null

# View installer build log
cat /tmp/caelestia_build.log 2>/dev/null | tail -60

# View installer stderr log (tmux runs)
cat /tmp/caelestia_installer_err.log 2>/dev/null
```

### Network Diagnostics

```bash
# Test submodule availability
git ls-remote https://github.com/ladybug-me/caelestia-dots.git HEAD

# Test AUR access
curl -sI https://aur.archlinux.org/rpc/?v=5\&type=info\&arg[]=quickshell-git | head -5
```

### KDE Cache Refresh

```bash
# Rebuild desktop file cache
kbuildsycoca6 --noincremental

# Refresh desktop database
update-desktop-database ~/.local/share/applications/

# Restart Plasma shell (affects current session)
systemctl --user restart plasma-plasmashell
```

---

## Quick Reference: Common Fixes

| Problem | Quick Fix |
|---|---|
| Shell won't start | `quickshell -d -n -p ~/.config/quickshell/caelestia/shell.qml` |
| Lock screen blank | `cd src/plasma-wallpaper-application && kpackagetool6 -t Plasma/Wallpaper -i package` |
| High CPU while locked | Set wallpaper plugin FPS to 1 in System Settings |
| Stale lock file | `rm -f "${XDG_RUNTIME_DIR:-/tmp}/caelestia-setup.lock"` |
| Missing QML module | `export QML2_IMPORT_PATH="$HOME/.local/lib/qt6/qml"` |
| No window thumbnails | `kbuildsycoca6 --noincremental && qdbus6 org.kde.KWin /KWin reconfigure` |
| Git submodule error | `git submodule update --init --recursive src/dots` |
| Colors not updating | `systemctl --user restart kde-material-you-colors.service` |
| Installer compiles but flashes/exits | Check `/tmp/caelestia_installer_err.log` |
| Recording not working | Verify `gpu-screen-recorder` is installed |
| Screenshot not working | Verify `spectacle` is installed |