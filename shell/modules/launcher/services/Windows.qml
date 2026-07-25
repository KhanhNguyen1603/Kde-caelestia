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
        const activeAddress = KWinActiveWindowBridge.activeWindow ? KWinActiveWindowBridge.activeWindow.address : "";
        const winList = KWinActiveWindowBridge.windowList;
        
        let currentItems = root.items.slice();
        
        // 1. Remove closed windows
        currentItems = currentItems.filter(item => {
            for (let i = 0; i < winList.length; i++) {
                if (winList[i].address === item.address) return true;
            }
            return false;
        });
        
        // Helper to format
        const formatClient = (client) => {
            return {
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
        };

        // 2. Add new windows & update existing
        for (let i = 0; i < winList.length; ++i) {
            const client = winList[i];
            let found = false;
            for (let j = 0; j < currentItems.length; ++j) {
                if (currentItems[j].address === client.address) {
                    currentItems[j] = formatClient(client); // Update properties
                    found = true;
                    break;
                }
            }
            if (!found) {
                currentItems.push(formatClient(client));
            }
        }
        
        // 3. Move active window to index 0
        if (activeAddress) {
            for (let i = 0; i < currentItems.length; i++) {
                if (currentItems[i].address === activeAddress) {
                    const activeWin = currentItems.splice(i, 1)[0];
                    currentItems.unshift(activeWin);
                    break;
                }
            }
        }
        
        items = currentItems;
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
        KWinActiveWindowBridge.onActiveWindowChanged.connect(updateItems);
    }
}
