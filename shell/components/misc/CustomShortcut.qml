import QtQuick
import Quickshell
import Quickshell.Hyprland

Loader {
    id: root

    property string name: ""
    property string description: ""

    signal pressed()
    signal released()

    active: !!Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")

    sourceComponent: GlobalShortcut {
        appid: "caelestia"
        name: root.name
        description: root.description
        onPressed: root.pressed()
        onReleased: root.released()
    }
}
