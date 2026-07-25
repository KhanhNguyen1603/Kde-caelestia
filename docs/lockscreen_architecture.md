# Caelestia Lock Screen Architecture

This document outlines the architecture, setup instructions, and developer guidelines for the Caelestia lock screen implementation in Plasma 6 / KWin.

## How the Backend Works

KDE's native compositor (KWin) enforces strict security policies on the lock screen. It explicitly blocks third-party shell interfaces (like `ext-session-lock-v1`) to prevent keyloggers, unauthorized password harvesting, or lock screen bypasses. Because of this, we cannot natively render Quickshell as a standalone Wayland lock screen client in Plasma 6.

To bypass this restriction, Caelestia relies on the `plasma-wallpaper-application` plugin. 
- **The Proxy:** This plugin acts as a nested Wayland server (proxy) that runs *inside* the secure KDE lock screen environment.
- **The Connection:** Quickshell connects to this proxy socket instead of the native KWin compositor.
- **The Input:** Because it is running underneath the KDE lock screen overlay, native KDE password input will immediately take over as soon as you move your mouse or press a key. Caelestia acts as a beautiful "screensaver" and dashboard that sits behind this authentication overlay.

## Setup Instructions

This plugin is **not** SDDM specific (SDDM is your login screen). This is specifically for KDE's built-in Lock Screen (`kscreenlocker`). 
Additionally, you **do not** need to compile it! It is a pure QML/QtWayland package.

1. **Install Dependencies:** Ensure you have the QtWayland compositor module installed (`qt6-wayland` on Arch).
2. **Install the Plugin:** Navigate to the `plasma-wallpaper-application` directory in this repository and install it using KDE's package tool:
   ```bash
   cd plasma-wallpaper-application
   kpackagetool6 -t Plasma/Wallpaper -i package
   ```
   *(Note: To upgrade it later, use `-u` instead of `-i`)*
3. **Apply in KDE Settings:** 
   - Open KDE System Settings -> Screen Locking -> Configure Appearance
   - Select the `Application` wallpaper plugin.
4. **Configure the Command:** 
   - In the plugin settings, set the application command to:
     ```bash
     quickshell -p ~/.config/quickshell/caelestia/lockscreen.qml
     ```

## Wayland CPU Utilization & Performance

When Quickshell runs natively on your desktop, it communicates directly with KWin and leverages **Hardware (GPU) Compositing**. This is highly efficient and typically uses <5% CPU even with active animations.

However, when running inside the lock screen via `plasma-wallpaper-application`, the nested proxy must capture Wayland buffers and heavily relies on **Software (CPU) Compositing**. 

### The Animation Problem
If your lock screen widgets contain continuous animations, QtQuick will generate new frames at 60 FPS. The proxy must then software-composite all 60 frames per second on your CPU. This creates an **extreme CPU bottleneck**, often spiking usage to 40% or more while locked.

### Solutions for Users
To mitigate high CPU temperatures and fan noise while locked:
1. **Set an FPS Limit:** In the `Application` wallpaper plugin settings, set the FPS limit to a lower value like `15` or `30`. Since it is a lock screen, high framerates are unnecessary.
2. **Use Static Wallpapers:** Avoid using video wallpapers or animated GIFs on the lock screen. The number of frames rendered is directly proportional to your CPU usage.

## Developer Guide: Building Low-FPS Widgets

When developing widgets for the lock screen, you must be extremely conscious of Wayland frame damage. Any active `Timer`, `Behavior`, or infinite loop will force the proxy to redraw the screen.

### Component Structure
- **Root Entry Point:** `lockscreen.qml` - Initializes the lock screen environment.
- **Background Window:** `modules/lock/LockBackgroundWindow.qml` - Creates the transparent fullscreen container.
- **Content Layout:** `modules/lock/BackgroundContent.qml` - Defines the widget grid and responsiveness (portrait vs landscape).
- **Widgets Directory:** `modules/lock/` - Contains the individual dashboard widgets (e.g., `Fetch.qml`, `Media.qml`, `Resources.qml`).

### Strict Rules for Lock Screen Widgets
1. **No Continuous Animations:** Never use infinite `RotationAnimator` or scrolling marquees.
2. **Synchronize Polling:** If you have multiple widgets that poll data (like `Cpu`, `Memory`, `Storage`), ensure they do not stagger their animations. If CPU animates at 0.0s, RAM at 0.3s, and Disk at 0.6s, the screen is animating 90% of the time. 
3. **Avoid Behaviors on Timers:** If a value is updated via a 1-second interval (like system stats), do **not** use a 300ms `Behavior` on that value. It is better to let the value snap instantly, generating 1 frame of damage per second, rather than 18 frames of damage per second.
4. **Pause Shaders:** If using `ShaderEffectSource`, ensure `live` is set to `false` unless a transition is actively occurring.

To create or edit a widget, modify the files inside `shell/modules/lock/` and add them to the grid in `BackgroundContent.qml`. Keep them static!
