pragma Singleton

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import Caelestia.Services

QtObject {
    id: root

    readonly property var items: ClipboardManager.items

    /// False when the cliphist binary could not be started, so the launcher can
    /// explain the empty list instead of looking broken.
    readonly property bool available: ClipboardManager.available

    /// Entries kept outside cliphist's rotation, so they survive both the
    /// history filling up and a Clear History.
    readonly property var pinnedItems: ClipboardManager.pinnedItems

    /// Forwarded from C++ so QML items can connect to a single source of truth.
    signal imageReady(int id, string path)
    signal clearHistoryFinished(bool success)
    signal pinFailed(int id)

    readonly property string imageCacheDir: ClipboardManager.imageCacheDir

    function reload(): void {
        ClipboardManager.reload();
    }

    function clearHistory(): void {
        ClipboardManager.clearHistory();
    }

    function pin(clipId: int): void {
        ClipboardManager.pin(clipId);
    }

    function unpin(pinId: int): void {
        ClipboardManager.unpin(pinId);
    }

    function copyPinned(pinId: int): void {
        ClipboardManager.copyPinned(pinId);
    }

    /// Pinned entries carry a negative id so they never collide with a cliphist
    /// one, and so existing code that keys on `id` keeps working.
    function toPinnedEntry(pin: var): var {
        return {
            id: -pin.pinId,
            pinId: pin.pinId,
            preview: pin.preview,
            isImage: pin.isImage,
            imagePath: pin.imagePath,
            isPinned: true
        };
    }

    function getSortedItems(): var {
        const pinned = (pinnedItems || []).map(p => root.toPinnedEntry(p));

        // A pinned entry usually also sits in the live list until it rotates
        // out; show it once, as the pinned copy. Previews are what the user
        // sees, so matching on them is the right granularity here.
        const pinnedPreviews = new Set(pinned.map(p => p.preview));
        const rest = (items || []).filter(item => !pinnedPreviews.has(item.preview));

        return [...pinned, ...rest];
    }

    function getImagePath(clipId: int): string {
        return imageCacheDir + "/" + clipId + ".png";
    }

    /// favouriteClips stored cliphist ids, which do not survive rotation or a
    /// Clear History — the star silently became a dangling reference and the
    /// dead ids piled up in the config. Convert whatever is still resolvable
    /// into real pins, once, then stop tracking it.
    function migrateFavourites(): void {
        const favs = GlobalConfig.launcher.favouriteClips || [];
        if (!favs.length || !items.length)
            return;

        const live = new Set(items.map(item => String(item.id)));
        for (const fav of favs)
            if (live.has(String(fav)))
                root.pin(Number(fav));

        GlobalConfig.launcher.favouriteClips = [];
    }

    /// Connections block to forward the C++ imageReady signal to the QML world.
    property var _conn: Connections {
        target: ClipboardManager
        function onImageReady(id: int, path: string): void {
            root.imageReady(id, path);
        }
        function onClearHistoryFinished(success: bool): void {
            root.clearHistoryFinished(success);
        }
        function onPinFailed(id: int): void {
            root.pinFailed(id);
        }
        function onItemsChanged(): void {
            root.migrateFavourites();
        }
    }
}
