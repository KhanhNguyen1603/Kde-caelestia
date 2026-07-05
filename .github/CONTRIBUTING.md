# Contributing to caelestia-dots-kde

Thanks for your interest in contributing to the KDE Plasma port!

## Guidelines

- Please make **multiple PRs** if you have many features/fixes—don't combine unrelated changes
- Don't include your personal configuration defaults in PRs
- We can accept features we don't personally use, but they **must be configurable** (off by default for experimental features)
- For **big changes**, please open an issue first to discuss—it saves effort for everyone

### Hyprland to KWin Mapping
If you are adding a new feature to the UI (QML) that uses a `hyprctl dispatch` command, you **must** register that command in our JSON translation layer.
1. Open `src/bin/hypr_kwin_map.json`.
2. Add your new dispatch verb under the `"verbs"` section.
3. Provide the expected arguments (`args`) and the KWin DBus Javascript equivalent (`kwin_action`).
4. Run `python3 .github/scripts/test_hypr_shim.py` locally to verify that all commands in the QML codebase are correctly mapped. Failure to do this will cause the CI build to fail.
## Translations

See `src/config/quickshell/ii/translations/tools` for translation files.

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
- Copy `src/config/quickshell` folder to `~/.config/quickshell`
- Most widgets will work, but KDE integration may be limited

### Quickshell Development

- **LSP setup**: Run `touch ~/.config/quickshell/ii/.qmlls.ini` for QML language server support
- **VSCode**: Install the official "Qt Qml" extension, then set `qmlls` custom exe path to `/usr/bin/qmlls6` in settings
- **Live reload**: Changes to `.qml` files reload automatically when saved


## Testing Your Changes

**For KDE widgets:**
- Restart Plasmashell: `kquitapp6 plasmashell && kstart6 plasmashell`
- Or restart the Quickshell service: `systemctl --user restart qs-kwin-bridge`

**For Quickshell shell:**
- In a terminal: `pkill qs; qs -c ii` (shows logs for debugging)
- Edit files in `~/.config/quickshell/ii`, changes reload live

**For KDE settings:**
- Re-run the relevant installation step or manually test with `kwriteconfig6`

## Security & Conventions

- **Shell Execution Security**: When invoking shell scripts via `Quickshell.execDetached` or `Process {}`, prefer argv arrays or positional `$1`/`$2` args over string-concatenated shell commands to prevent injection footguns.
  - **Good**: `Quickshell.execDetached(["bash", "-c", "echo \"$1\"", "--", myVar]);`
  - **Bad**: `Quickshell.execDetached(["bash", "-c", "echo " + myVar]);`
- **Temporary Files**: Do not hardcode `/tmp/` paths. Instead, use the `Paths.runtimeTemp("filename")` helper from `qs.utils` to safely place temp files in the user's `XDG_RUNTIME_DIR`. This prevents permission clashes on multi-user systems.
- **IPC Parsing**: When writing custom C++ D-Bus or IPC listeners (e.g. `discordipc.cpp`), always validate frame length prefixes before reading from the buffer to prevent infinite loops from malicious or malformed payloads.
