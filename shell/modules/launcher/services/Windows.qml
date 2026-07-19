pragma Singleton

import QtQuick
import Quickshell
import Caelestia.Services

QtObject {
    id: root

    property var items: []

    function reload(): void {
        updateItems();
    }

    function updateItems(): void {
        const windows = [];
        for (const client of KWinActiveWindowBridge.windowList) {
            windows.push({
                address: client.address,
                title: client.title || "",
                class: client.class || "",
                workspace: client.workspace?.id || "",
                monitor: "",
                wayland: true,
                size: [client.width || 0, client.height || 0],
                at: [client.x || 0, client.y || 0]
            });
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
