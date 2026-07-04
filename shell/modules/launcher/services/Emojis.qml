pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config

QtObject {
    id: root

    property var items: []
    property var frequencies: ({})
    property bool _loaded: false

    property Process reader: Process {
        running: false
        command: ["cat", "/usr/lib/python3.14/site-packages/caelestia/data/emojis.txt"]
        stdout: StdioCollector {
            onStreamFinished: {
                const result = [];
                const lines = text.trim().split("\n");

                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i];
                    if (!line)
                        continue;

                    const spaceIdx = line.indexOf(" ");
                    if (spaceIdx < 0)
                        continue;

                    const name = line.substring(spaceIdx + 1).trim();
                    result.push({
                        ch: line.substring(0, spaceIdx),
                        name: name,
                        nameLower: name.toLowerCase()
                    });
                }

                root.items = result;
                root._loaded = true;
            }
        }
    }

    property Process freqReader: Process {
        running: false
        command: ["test", "-f", Paths.config + "emoji-frequencies.json", "&&", "cat", Paths.config + "emoji-frequencies.json", "||", "echo", "{}"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.frequencies = JSON.parse(text) || {};
                } catch (e) {
                    root.frequencies = {};
                }
            }
        }
    }

    property Process freqWriter: Process {
        running: false
    }

    function reload(): void {
        if (_loaded)
            return;
        reader.running = true;
        loadFrequencies();
    }

    function loadFrequencies(): void {
        freqReader.running = true;
    }

    function saveFrequencies(): void {
        freqWriter.command = ["bash", "-c", "echo '" + JSON.stringify(frequencies) + "' > " + Paths.config + "emoji-frequencies.json"];
        freqWriter.running = true;
    }

    function recordUsage(ch: string): void {
        frequencies[ch] = (frequencies[ch] || 0) + 1;
        saveFrequencies();
    }

    property var _sortedCache: []
    property bool _sortDirty: true

    property Connections favConnections: Connections {
        target: GlobalConfig.launcher
        function onFavouriteEmojisChanged(): void {
            root._sortDirty = true;
        }
    }

    onItemsChanged: root._sortDirty = true
    onFrequenciesChanged: root._sortDirty = true

    function getSortedItems(): var {
        if (!items.length)
            return [];
        if (!_sortDirty)
            return _sortedCache;
        const favEmojis = GlobalConfig.launcher.favouriteEmojis || [];
        const favSet = new Set(favEmojis);
        _sortedCache = [...items].sort((a, b) => {
            const aIsFav = favSet.has(a.ch);
            const bIsFav = favSet.has(b.ch);
            if (aIsFav !== bIsFav)
                return aIsFav ? -1 : 1;
            const freqA = frequencies[a.ch] || 0;
            const freqB = frequencies[b.ch] || 0;
            if (freqA !== freqB)
                return freqB - freqA;
            return 0;
        });
        root._sortDirty = false;
        return _sortedCache;
    }
}