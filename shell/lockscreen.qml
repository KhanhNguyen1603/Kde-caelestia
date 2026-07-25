pragma ComponentBehavior: Bound

import QtQml
import Quickshell
import Caelestia.Config
import "modules/lock"

ShellRoot {
    Variants {
        model: Quickshell.screens
        
        LockBackgroundWindow {
            required property var modelData
            screen: modelData
        }
    }
}
