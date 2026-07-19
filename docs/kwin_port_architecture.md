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

**Properties:**
* `name` (`QString`): The unique identifier for the shortcut.
* `key` (`QString`): The key sequence trigger (e.g., `"Meta+Shift+S"`). Multiple key sequences can be separated by semicolons (e.g., `"Meta+Shift+S; Print"`).
* `description` (`QString`): A human-readable description of what the shortcut does (visible in KDE System Settings).

**Signals:**
* `activated()`: Emitted globally when the user presses the registered key sequence.

**Under the Hood: Key Theft & Conflict Resolution**
To guarantee that Caelestia's hotkeys always work, the C++ backend overrides existing KDE shortcuts (such as the default Meta+Shift+S screenshot tool) on startup and restores them on exit:
1. It queries `KGlobalAccel::globalShortcutsByKey(seq)` to find any conflicts with other registered KDE components.
2. If conflicts are found, it unbinds them from their parent components using a shell execution of `gdbus`:
   ```bash
   gdbus call --session --dest org.kde.kglobalaccel \
              --object-path /kglobalaccel \
              --method org.kde.KGlobalAccel.setShortcutKeys \
              "['<component>', '<action>', '', '']" "[([0, 0, 0, 0],)]" 4
   ```
3. It then binds the shortcut to Caelestia's own action object using `KGlobalAccel::self()->setShortcut(m_action, seqs, KGlobalAccel::NoAutoloading)`.
4. Upon shell destruction, it executes a similar `gdbus` call to restore the original keybinds back to their respective components (e.g., Spectacle or KWin).

---

## 3. How Shortcuts are Loaded (`Shortcuts.qml`)

All keyboard shortcuts in Caelestia are declared inside `Shortcuts.qml` under `shell/modules/` using the `CustomShortcut` QML wrapper under `shell/components/misc/`.

### Compositor Adaptation
The `CustomShortcut` wrapper dynamically inspects the environment at startup:
- **Hyprland**: If `$HYPRLAND_INSTANCE_SIGNATURE` is present, it loads `Quickshell.Hyprland`'s `GlobalShortcut` component. Key bindings are defined in `hyprland.conf` by mapping action names. (This should be removed in future)
- **KDE (KWin)**: If not on Hyprland, it loads the C++ `Caelestia.GlobalShortcut` component, registering the hotkeys directly with KDE's global shortcut daemon.

### Hardcoded vs. System Settings Configurable Keybinds
There are two ways shortcuts are registered in `Shortcuts.qml` under KDE:
1. **Hardcoded Hotkeys**: Keybinds that have an explicit `key` string defined (e.g., `key: "Meta+Shift+S; Print"` for screenshots or `key: "Meta+Return"` for launching the terminal). These are bound forcefully on startup.
2. **KDE System-Configurable Hotkeys**: General shortcuts (like `nexus` or `dashboard`) are defined with a `name` and `description` but leave `key` empty. Because `key` is empty, Caelestia registers the action with `KGlobalAccel` but binds no default key. This registers the actions under **KDE System Settings -> Shortcuts -> quickshell**, allowing the user to natively map their own custom hotkeys inside KDE!
