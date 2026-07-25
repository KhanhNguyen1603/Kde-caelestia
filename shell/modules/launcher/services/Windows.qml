pragma Singleton

import QtQuick
import Quickshell
import Caelestia.Services

QtObject {
    id: root

    property var items: []

    signal cycleNext()
    signal cyclePrev()

    function reload(): void {
        updateItems();
    }

    function updateItems(): void {
        const windows = [];
        const activeAddress = KWinActiveWindowBridge.activeWindow ? KWinActiveWindowBridge.activeWindow.address : "";
        let activeWin = null;
        
        const winList = KWinActiveWindowBridge.windowList;
        for (let i = winList.length - 1; i >= 0; --i) {
            const client = winList[i];
            const win = {
                address: client.address,
                title: client.title || "",
                class: client.class || "",
                iconName: client.iconName || client.class || "",
                workspace: client.workspace?.id || "",
                monitor: "",
                wayland: true,
                size: [client.width || 0, client.height || 0],
                at: [client.x || 0, client.y || 0]
            };
            
            if (win.address === activeAddress) {
                activeWin = win;
            } else {
                windows.push(win);
            }
        }
        
        if (activeWin) {
            windows.unshift(activeWin);
        }
        
        items = windows;
    }

    function query(search: string): var {
        if (!search)
            return items;
        const lower = search.toLowerCase();
        return items.filter(w => w.title.toLowerCase().includes(lower) || w.class.toLowerCase().includes(lower));
    }

    function focusWindow(address: string): void {
        KWinActiveWindowBridge.focusWindow(address);
    }

    Component.onCompleted: {
        updateItems();
        KWinActiveWindowBridge.onWindowListChanged.connect(updateItems);
    }
}
