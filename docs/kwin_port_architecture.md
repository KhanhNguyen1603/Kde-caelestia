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

**Properties:**
* `name` (`QString`): The unique identifier for the shortcut.
* `key` (`QString`): The current active key sequence trigger (e.g., `"Meta+Shift+S"`). Multiple key sequences can be separated by semicolons.
* `defaultKey` (`QString`): The original fallback key assigned at startup, used when resetting custom overrides.
* `description` (`QString`): A human-readable description of what the shortcut does (visible in the UI).

**Signals:**
* `activated()`: Emitted globally when the user presses the registered key sequence.

### `KeybindsModel` & `GlobalShortcutDispatcher` (Singletons)
* **`GlobalShortcutDispatcher`**: A bridging singleton since static C++ methods cannot emit signals. `GlobalShortcut` instances register themselves into a static `QHash` registry on creation and fire signals through this dispatcher.
* **`KeybindsModel`**: A `QAbstractListModel` singleton exposing the entire list of registered shortcuts to QML. It observes the dispatcher for new shortcuts, applies any user overrides from `~/.config/quickshell/keybinds.json`, and exposes them for the Nexus settings UI. Overrides are persisted to disk using a 300ms debounce timer to prevent IO thrashing.

**`KeybindsModel` Methods (Invokables):**
* `void setKey(const QString& name, const QString& newKey)`: Changes the keybind for the specified shortcut and saves the override to disk.
* `void resetKey(const QString& name)`: Resets the shortcut back to its original `defaultKey` and removes the override.
* `QVariantList query(const QString& searchText = "")`: Returns a filtered list of shortcuts. Used mostly for backward compatibility with older UI components like the app launcher.

**Under the Hood: Key Theft & Conflict Resolution**
To guarantee that Caelestia's hotkeys always work, the C++ backend overrides existing KDE shortcuts on startup and restores them on exit:
1. It queries `KGlobalAccel::globalShortcutsByKey(seq)` to find any conflicts with other registered KDE components.
2. For every conflict, it spawns an asynchronous `QProcess` executing a `gdbus` call to unbind the combo from the foreign component:
   ```bash
   gdbus call --session --dest org.kde.kglobalaccel \
              --object-path /kglobalaccel \
              --method org.kde.KGlobalAccel.setShortcutKeys \
              "['<component>', '<action>', '', '']" "[([0, 0, 0, 0],)]" 4
   ```
3. **Performance First**: Since `system()` or synchronous `QProcess::execute()` would block the main Qt thread, all steal commands run concurrently. A `std::shared_ptr<QAtomicInt>` pending counter tracks them, and only the final process to finish registers the shortcut with `KGlobalAccel::self()->setShortcut(..., NoAutoloading)`. A generation counter (`m_registerGeneration`) protects against rapid consecutive property updates.
4. Upon shell destruction, a similar detached `gdbus` call restores the original keybinds back to their respective components (e.g., Spectacle or KWin).

---

## 3. How Shortcuts are Loaded (`Shortcuts.qml`)

All keyboard shortcuts in Caelestia are declared inside `Shortcuts.qml` under `shell/modules/` using the `CustomShortcut` QML wrapper under `shell/components/misc/`.

### Compositor Adaptation
The `CustomShortcut` wrapper dynamically inspects the environment at startup:
- **Hyprland**: If `$HYPRLAND_INSTANCE_SIGNATURE` is present, it loads `Quickshell.Hyprland`'s `GlobalShortcut` component. Key bindings are defined in `hyprland.conf` by mapping action names. (This should be removed in future)
- **KDE (KWin)**: If not on Hyprland, it loads the C++ `Caelestia.GlobalShortcut` component, registering the hotkeys directly with KDE's global shortcut daemon.

### Nexus Shortcut Manager & Overrides
In the KDE port, all Caelestia keybinds are managed fully natively inside the **Nexus settings panel**:
1. **Initial Declaration**: `Shortcuts.qml` defines the defaults via `Caelestia.GlobalShortcut` elements.
2. **Dynamic UI Rendering**: `KeybindsModel` automatically groups all active shortcuts into categories (Shell UI, Applications, Workspaces, Tiling) by regex-matching their names, exposing them to `ShortcutManagerPage.qml`.
3. **Key Capture & Persistence**: When a user clicks a row in Nexus, a modal `KeyCaptureDialog` intercepts physical keystrokes (`Keys.onPressed`) in QML. The new combination is sent to `KeybindsModel::setKey()`, instantly rebinding the C++ backend and saving the override to `~/.config/quickshell/keybinds.json`.

Because of this unified manager, leaving `key` empty in `Shortcuts.qml` simply registers the action without a default keybind, allowing the user to map it in Nexus later. (It also registers in KDE System Settings -> Shortcuts -> quickshell, but the in-shell Nexus manager is the intended frontend).
