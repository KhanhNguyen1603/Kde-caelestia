#!/usr/bin/env python3
import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib
import os, sys, json, subprocess

RUNTIME_DIR = os.environ.get('XDG_RUNTIME_DIR', f"/run/user/{os.getuid()}")
STATE_FILE = os.path.join(RUNTIME_DIR, 'qs_kwin_windows.json')
WORKSPACES_FILE = os.path.join(RUNTIME_DIR, 'qs_kwin_workspaces.json')
ACTIVEWORKSPACE_FILE = os.path.join(RUNTIME_DIR, 'qs_kwin_activeworkspace.json')
MONITORS_FILE = os.path.join(RUNTIME_DIR, 'qs_kwin_monitors.json')
KWIN_SCRIPT_PATH = os.path.expanduser(
    "~/.local/share/kwin/scripts/quickshell-kde-bridge/contents/code/main.js"
)

class QSKWinBridge(dbus.service.Object):
    def __init__(self, bus, path_name):
        super().__init__(bus, path_name)
        self.windows_json = "[]"
        if os.path.exists(STATE_FILE):
            try:
                with open(STATE_FILE, 'r') as f:
                    self.windows_json = f.read().strip() or "[]"
            except:
                pass
        # Emit cached state immediately so overview shows last-known windows
        print(self.windows_json, flush=True)

    def trigger_kwin_update(self):
        """Reload the KWin bridge script so its initial updateWindows() fires with us on the bus."""
        try:
            bus = dbus.SessionBus()
            scripting = bus.get_object("org.kde.KWin", "/Scripting")
            scripting_iface = dbus.Interface(scripting, "org.kde.kwin.Scripting")
            try:
                scripting_iface.unloadScript("quickshell-kde-bridge")
            except Exception:
                pass
            scripting_iface.loadScript(KWIN_SCRIPT_PATH)
            scripting_iface.start()
        except Exception:
            pass
        return False  # Don't repeat

    @dbus.service.method("org.kde.qs.bridge", in_signature='s', out_signature='')
    def updateWindows(self, win_json):
        # Validate JSON before printing (avoid corrupting the stdout stream)
        try:
            parsed = json.loads(str(win_json))
        except Exception:
            return
        self.windows_json = str(win_json)
        try:
            with open(STATE_FILE, 'w') as f:
                f.write(self.windows_json)
        except:
            pass
        # Print only valid JSON lines — no debug output to stdout
        print(self.windows_json, flush=True)

    @dbus.service.method("org.kde.qs.bridge", in_signature='s', out_signature='')
    def updateWorkspaces(self, ws_json):
        try:
            json.loads(str(ws_json))
            with open(WORKSPACES_FILE, 'w') as f:
                f.write(str(ws_json))
        except Exception:
            pass

    @dbus.service.method("org.kde.qs.bridge", in_signature='s', out_signature='')
    def updateActiveWorkspace(self, id_json):
        try:
            json.loads(str(id_json))
            with open(ACTIVEWORKSPACE_FILE, 'w') as f:
                f.write(str(id_json))
        except Exception:
            pass

    @dbus.service.method("org.kde.qs.bridge", in_signature='s', out_signature='')
    def triggerMonitorsUpdate(self, _dummy):
        try:
            out = subprocess.check_output(["kscreen-doctor", "-j"], text=True)
            k_data = json.loads(out)
            monitors = []
            for o in k_data.get("outputs", []):
                if not o.get("enabled", False): continue
                mode = next((m for m in o.get("modes", []) if m["id"] == o.get("currentModeId")), None)
                w = mode["size"]["width"] if mode else 1920
                h = mode["size"]["height"] if mode else 1080
                rr = mode["refreshRate"] if mode else 60.0
                monitors.append({
                    "id": o.get("id", 0),
                    "name": o.get("name", "Unknown"),
                    "description": o.get("name", "Unknown"),
                    "make": "", "model": "", "serial": "", "class": "",
                    "width": w,
                    "height": h,
                    "refreshRate": rr,
                    "x": o.get("pos", {}).get("x", 0),
                    "y": o.get("pos", {}).get("y", 0),
                    "activeWorkspace": {"id": 1, "name": "1"},
                    "specialWorkspace": {"id": 0, "name": ""},
                    "reserved": [0,0,0,0],
                    "scale": o.get("scale", 1.0),
                    "transform": 0,
                    "focused": False,
                    "dpmsStatus": True,
                    "vrr": False,
                    "solitary": "",
                    "active": True
                })
            try:
                active_output = subprocess.check_output(["qdbus6", "org.kde.KWin", "/KWin", "org.kde.KWin.activeOutputName"], text=True).strip()
            except Exception:
                active_output = None
                
            focused_set = False
            for m in monitors:
                if active_output and m["name"] == active_output:
                    m["focused"] = True
                    focused_set = True
                    
            if monitors and not focused_set:
                monitors[0]["focused"] = True
                
            with open(MONITORS_FILE, 'w') as f:
                f.write(json.dumps(monitors))
        except Exception:
            pass

dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
session_bus = dbus.SessionBus()
name = dbus.service.BusName("org.kde.qs", session_bus)
bridge = QSKWinBridge(session_bus, '/bridge')

# After 500ms, reload the KWin script so its initial updateWindows() fires with us on the bus
GLib.timeout_add(500, bridge.trigger_kwin_update)

loop = GLib.MainLoop()
loop.run()
