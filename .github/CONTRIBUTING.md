# Contributing to caelestia-dots-kde

Thanks for your interest in contributing to the KDE Plasma port!

## Guidelines

- Please make **multiple PRs** if you have many features/fixes—don't combine unrelated changes
- Don't include your personal configuration defaults in PRs
- We can accept features we don't personally use, but they **must be configurable** (off by default for experimental features)
- For **big changes**, please open an issue first to discuss—it saves effort for everyone

### Native C++ KWin & Wayland Backend
This port uses a native C++ plugin backend (`KWinActiveWindowBridge`, `KWinWorkspaceState`, and `GlobalShortcut`) to interact directly with KWin and the Wayland registry.

For a full list of exposed QML APIs, signals, and architectural details, refer to:
* docs/kwin_port_architecture.md

### Installer Development
Caelestia uses a custom C++ TUI installer for interactive installation setups.
- **Aesthetics & Theme**: Customize colors, ASCII splash screen, layout coordinates, and labels inside `installer/theme.json`
- **Menu Options**: Configure the installation checklist options, groupings, and triggers inside `installer/menu.json`
- **Core C++ Logic**: Edit terminal drawing (`Draw.cpp`), UI layouts (`UI.cpp`), and **Script execution order** (`Runner.cpp`) inside `installer/src/`

For a complete configuration and styling guide, refer to:
* `docs/installer_config.md`

# Code

## Dynamic loading

- If something's not always necessary, especially when guarded by a config option to enable/disable, put it in a `Loader`
  - Note that you will need to declare positioning properties (like `anchors`) in the `Loader`, not the `sourceComponent`
  - When something that's to be dynamically loaded doesn't affect its parent layout, you can have a fading animation by using FadeLoader and set the `shown` prop instead of `active` and `visible`

## Practical concerns

- Make sure what you add does not require significant resources for a minor purpose or harm usability just for the sake of looking nice. The dotfiles must remain practical for daily driving.
- If there is something really fancy and impractical anyway, add a config option for it and make sure it's disabled by default (example: constantly rotating background clock)

## Style

- Spaces
  - Space properties and children data into meaningful groups. (but of course, don't use 2+ blanks in a row)
  - Put spaces between text and operators: `if (condition) { ... } else { ... }` instead of `if(condition){ ... }else{ ... }`
- As you can see, it's pretty easy to use lots of nesting. There's no hard limit, the original author nests a lot too, but avoid/mitigate that:
  - Prefer early return: Use something like `if (!condition) return; doStuff();` instead of `if (condition) { doStuff() }`
  - If you feel it's a bother to refractor something into a new file, remember there's `component` to declare reusable components in the same file.

## Setting up for Development

These instructions assume **Arch Linux** or an Arch-based distro.

### Full Installation (Recommended)

- Clone this repo: `git clone https://github.com/ladybug-me/caelestia-dots-kde ~/caelestia-dots-kde`
- Run the installer: `bash ~/caelestia-dots-kde/setup.sh`
- Make your changes in the cloned repo
- Test locally, then push to your fork and create a PR

### Development-Only Setup

_For testing Quickshell widget changes without a full KDE installation:_

- Install KDE Plasma 6+ and Quickshell: `yay -S plasma-desktop quickshell-git`
- Copy `shell` folder to `~/.config/quickshell/caelestia`
- Most widgets will work, but KDE integration may be limited

### Quickshell Development

- **LSP setup**: Run `touch ~/.config/quickshell/caelestia/.qmlls.ini` for QML language server support
- **VSCode**: Install the official "Qt Qml" extension, then set `qmlls` custom exe path to `/usr/bin/qmlls6` in settings
- **Live reload**: Changes to `.qml` files reload automatically when saved


## Testing Your Changes

**For C++ plugin changes:**
- Recompile the C++ plugins: `bash scripts/08-build-shell.sh`

**For Quickshell shell:**
- Restart the shell cleanly: `caelestia shell -k && caelestia shell -d`
- Or run raw: `qs -c caelestia` in the terminal to view debugging logs
- Edit files in `~/.config/quickshell/caelestia`, changes reload live

**For KDE settings:**
- Re-run the relevant installation step or manually test with `kwriteconfig6`


## Security & Conventions

- **Shell Execution Security**: When invoking shell scripts via `Quickshell.execDetached` or `Process {}`, prefer argv arrays or positional `$1`/`$2` args over string-concatenated shell commands to prevent injection footguns.
  - **Good**: `Quickshell.execDetached(["bash", "-c", "echo \"$1\"", "--", myVar]);`
  - **Bad**: `Quickshell.execDetached(["bash", "-c", "echo " + myVar]);`
- **Temporary Files**: Do not hardcode `/tmp/` paths. Instead, use the `Paths.runtimeTemp("filename")` helper from `qs.utils` to safely place temp files in the user's `XDG_RUNTIME_DIR`. This prevents permission clashes on multi-user systems.
- **IPC Parsing**: When writing custom C++ D-Bus or IPC listeners (e.g. `discordipc.cpp`), always validate frame length prefixes before reading from the buffer to prevent infinite loops from malicious or malformed payloads.
