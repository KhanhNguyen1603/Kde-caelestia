pragma Singleton

import QtQuick
import Caelestia
import Caelestia.Config
import Caelestia.Services

QtObject {
    id: root

    readonly property bool _loaded: EmojiDb.loaded
    // Kept for API compatibility — items now live in C++ heap
    readonly property int itemCount: EmojiDb.count

    property Connections favConnections: Connections {
        target: GlobalConfig.launcher
        function onFavouriteEmojisChanged(): void {
            // No-op: getSortedItems() always reads fresh from C++
        }
    }

    function reload(): void {
        // EmojiDb loads at startup; nothing to do unless it somehow wasn't loaded
        if (!EmojiDb.loaded) {
            console.warn("EmojiDb not loaded yet");
        }
    }

    function recordUsage(ch: string): void {
        EmojiDb.recordUsage(ch);
    }

    function getSortedItems(): var {
        const favEmojis = GlobalConfig.launcher.favouriteEmojis || [];
        return EmojiDb.getSortedItems(favEmojis);
    }

    function search(text: string): var {
        return EmojiDb.search(text, 500);
    }
}