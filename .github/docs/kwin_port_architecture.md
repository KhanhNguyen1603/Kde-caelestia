# Caelestia KWin Port - Architecture & Developer API

This document provides a comprehensive overview of the new C++ plugin backend introduced in the `kwin_port` branch, detailing the architectural shift from the old mock-hyprctl backend and providing full API documentation for developers building QML components.

---

## 1. Architectural Shift: The Native Backend

### The Old Approach (`dev` branch)
Previously, the KDE port relied on a "fake Hyprland" wrapper architecture:
1. **KWin JS Script** (`main.js`): Ran continuously in KWin, pushing window data over D-Bus.
2. **Python Daemon** (`qs-kwin-bridge.py`): A background service that listened to these D-Bus signals.
3. **Mock `hyprctl`**: A fake `hyprctl` binary. Whenever Quickshell requested window data or dispatched focus commands, it called this Python mock, which returned JSON formatted exactly like Hyprland's native output.

**The Problem**: This involved too many IPC hops, was prone to lagging, required a background daemon, and heavily restricted the shell from using KDE's native capabilities.

### The New Approach (`kwin_port` branch)
Inspired by setups like *kineticwe* and *noctalia*, the `kwin_port` branch rips out the Python daemon and mock `hyprctl` files. Caelestia now talks directly to KWin and Wayland via native **C++ Quickshell Plugins**:

1. **`KWinWorkspaceState` (C++ / Wayland Protocol)**
   - Binds directly to the KDE Plasma Virtual Desktop Wayland protocol.
   - Tracks desktop creation, destruction, and switching synchronously at the compositor level.
2. **`KWinActiveWindowBridge` (C++)**
   - Automatically injects and loads a temporary KWin script at runtime.
   - Pushes window updates directly to the Quickshell D-Bus interface.
   - **Reliability Update**: Uses decoupled `QProcess` tasks executing `qdbus6` for window actions (like closing/focusing), eliminating event-loop race conditions and silent execution failures.
3. **`GlobalShortcut` (C++)**
   - Standardizes system-wide keyboard shortcuts in C++, routing through KDE's `kglobalaccel` seamlessly.

---

## 2. Developer API Reference (QML)

The following native C++ singletons and components are exposed to QML to interact with KDE and Wayland directly.

### `KWinActiveWindowBridge` (Singleton)
Provides real-time information about active windows, monitors, and the global window list.

**Properties:**
* `activeWindow` (`QVariantMap`): The currently focused window.
  * Fields: `address` (String), `title` (String), `class` (String), `fullscreen` (Boolean), `maximized` (Boolean).
* `activeOutputName` (`QString`): The name of the monitor/output where the active window resides.
* `windowList` (`QVariantList` of `QVariantMap`): An array containing all active windows across the system. 
  * Each map contains: `address`, `title`, `class`, `floating`, `fullscreen`, `x`, `y`, `width`, `height`.

**Methods (Invokables):**
* `void focusWindow(const QString &address)`: Brings the specified window to the front and focuses it.
* `void closeWindow(const QString &address)`: Gracefully requests the specified window to close.
* `void minimizeWindow(const QString &address)`: Minimizes the specified window.
* `void maximizeWindow(const QString &address, bool horz = true, bool vert = true)`: Maximizes the window.
* `void raiseWindow(const QString &address)`: Raises the window to the top of the stack.
* `void moveWindow(const QString &address, int x, int y)`: Moves the window to absolute screen coordinates.
* `void resizeWindow(const QString &address, int width, int height)`: Resizes the window.
* `void setWindowProperty(const QString &address, const QString &property, bool enable)`: Toggles states (above, below, skip_taskbar, fullscreen, minimized, etc).
* `void setWindowDesktop(const QString &address, int desktopId)`: Moves window to desktop (-1 for current, -2 for all).
* `void setDesktop(int desktopId)`: Switches the current desktop workspace (1-indexed).
* `void nextDesktop()`: Switches to the next adjacent desktop, wrapping around at the end.
* `void previousDesktop()`: Switches to the previous adjacent desktop, wrapping around at the beginning.
* `void setDesktop(int desktopId)`: Switches the current desktop workspace.
* `void runArbitraryScript(const QString &script)`: Executes raw KWin JavaScript natively.
* `void setActiveOutputName(const QString &outputName)`: Manually sets the active output tracker.

### `KWinWorkspaceState` (Singleton)
Provides real-time tracking of KDE Plasma virtual desktops (workspaces).

**Properties:**
* `activeId` (`int`): The ID of the currently active virtual desktop (1-indexed).
* `workspaces` (`QVariantList` of `QVariantMap`): A list of all virtual desktops.
  * Each map contains: `id` (Integer), `name` (String), `monitor` (String), `windows` (Integer - count of windows), `hasfullscreen` (Boolean).

**Methods (Invokables):**
* `void switchTo(const QString& id)`: Switches the active workspace to the provided desktop ID.

### `GlobalShortcut` (Component)
A QML component used to register global keyboard shortcuts through KDE's native `kglobalaccel` system.

**Properties:** `name`, `key` (semicolon-separated multi-key), `description`  
**Signal:** `activated()`

### `KeybindsModel` & `GlobalShortcutDispatcher` (Singletons)
- **`GlobalShortcutDispatcher`**: Singleton relay for cross-instance signals and the central **collision index** (`key → friendly label`), backed by `stolen-shortcuts.json`.
- **`KeybindsModel`**: `QAbstractListModel` singleton that loads defaults, merges user overrides from `~/.config/caelestia/keybinds.json`, and drives the Nexus shortcut manager UI.

> **Full documentation** — shortcut theft, conflict resolution, crash-safe recovery, the diff-based update logic, and the Nexus UI integration are all covered in detail in **[`docs/shortcut_architecture.md`](shortcut_architecture.md)**.

---

## 3. How Shortcuts are Loaded (`Shortcuts.qml`)

All keyboard shortcuts in Caelestia are declared inside `Shortcuts.qml` under `shell/modules/` using the `CustomShortcut` QML wrapper under `shell/components/misc/`.

The `CustomShortcut` wrapper dynamically inspects the environment at startup:
- **Hyprland**: loads `Quickshell.Hyprland.GlobalShortcut`; bindings come from `hyprland.conf`.
- **KDE (KWin)**: loads `Caelestia.GlobalShortcut`, registering directly with KDE's global shortcut daemon.

See [`docs/shortcut_architecture.md`](shortcut_architecture.md) for full details on the shortcut loading pipeline, Nexus manager, and user override persistence.
