pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Caelestia
import Caelestia.Config
import qs.components.misc

Singleton {
    id: root

    readonly property list<MprisPlayer> list: Mpris.players.values
    readonly property MprisPlayer active: props.manualActive ?? list.find(p => getIdentity(p) === GlobalConfig.services.defaultPlayer) ?? list[0] ?? null
    property alias manualActive: props.manualActive

    property string fetchedArtUrl: ""
    readonly property string activeArtUrl: active ? (getArtUrl(active) || fetchedArtUrl) : ""

    onActiveChanged: {
        fetchArtwork();
    }

    property string lastFetchedArtist: ""
    property string lastFetchedTitle: ""

    function fetchArtwork() {
        const player = root.active;
        if (!player) {
            fetchedArtUrl = "";
            lastFetchedArtist = "";
            lastFetchedTitle = "";
            return;
        }

        // If player already has art, no need to fetch online
        if (getArtUrl(player) !== "") {
            fetchedArtUrl = "";
            lastFetchedArtist = "";
            lastFetchedTitle = "";
            return;
        }

        const artist = player.trackArtist ? player.trackArtist.trim() : "";
        const title = player.trackTitle ? player.trackTitle.trim() : "";
        if (title === "") {
            fetchedArtUrl = "";
            lastFetchedArtist = "";
            lastFetchedTitle = "";
            return;
        }

        if (artist === lastFetchedArtist && title === lastFetchedTitle) {
            return;
        }

        lastFetchedArtist = artist;
        lastFetchedTitle = title;
        fetchedArtUrl = "";

        // Clean parentheses, brackets, and common suffixes like remix, official video, etc.
        let cleanTitle = title.replace(/\s*[\(\[][^\)\]]*[\)\]]/g, "");
        cleanTitle = cleanTitle.replace(/\s*[-–—]?\s*(remix|official video|official audio|lyric video|lyrics video|lyrics|video|music video|audio)\s*$/i, "");
        cleanTitle = cleanTitle.trim();
        if (cleanTitle === "") cleanTitle = title;

        // Ignore artist if it is empty or is generic "unknown"
        const isArtistValid = (artist !== "" && !artist.toLowerCase().includes("unknown"));
        const searchTerm = isArtistValid ? (artist + " " + cleanTitle) : cleanTitle;

        const xhr = new XMLHttpRequest();
        const query = encodeURIComponent(searchTerm);
        const url = "https://itunes.apple.com/search?term=" + query + "&limit=1&entity=song";

        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        const response = JSON.parse(xhr.responseText);
                        if (response.results && response.results.length > 0) {
                            const rawUrl = response.results[0].artworkUrl100 || "";
                            if (rawUrl !== "") {
                                fetchedArtUrl = rawUrl;
                            }
                        }
                    } catch (e) {
                        console.warn("Error parsing iTunes artwork search response:", e);
                    }
                }
            }
        }
        xhr.open("GET", url);
        xhr.send();
    }

    function getIdentity(player: MprisPlayer): string {
        if (!player)
            return "";
        const alias = GlobalConfig.services.playerAliases.find(a => a.from === player.identity);
        return alias?.to ?? player.identity;
    }

    function getArtUrl(player: MprisPlayer): string {
        if (!player)
            return "";
        if (player.trackArtUrl)
            return player.trackArtUrl;

        const url = player.metadata["xesam:url"] ?? "";
        if (url.startsWith("https://www.youtube.com/watch")) {
            // Fallback for youtube
            const id = url.match(/[?&]v=([\w-]{11})/)?.[1];
            return id ? `https://img.youtube.com/vi/${id}/hqdefault.jpg` : "";
        }
        return "";
    }

    Connections {
        function onPostTrackChanged() {
            root.fetchArtwork();
            if (!GlobalConfig.utilities.toasts.nowPlaying) {
                return;
            }
            if (root.active.trackArtist != "" && root.active.trackTitle != "") {
                Toaster.toast(qsTr("Now Playing"), qsTr("%1 - %2").arg(root.active.trackArtist).arg(root.active.trackTitle), "music_note");
            }
        }

        target: root.active
    }

    PersistentProperties {
        id: props

        property MprisPlayer manualActive

        reloadableId: "players"
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "mediaToggle"
        description: "Toggle media playback"
        onPressed: {
            const active = root.active;
            if (active && active.canTogglePlaying)
                active.togglePlaying();
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "mediaPrev"
        description: "Previous track"
        onPressed: {
            const active = root.active;
            if (active && active.canGoPrevious)
                active.previous();
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "mediaNext"
        description: "Next track"
        onPressed: {
            const active = root.active;
            if (active && active.canGoNext)
                active.next();
        }
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "mediaStop"
        description: "Stop media playback"
        onPressed: root.active?.stop()
    }

    IpcHandler {
        function getActive(prop: string): string {
            const active = root.active;
            return active ? active[prop] ?? "Invalid property" : "No active player";
        }

        function list(): string {
            return root.list.map(p => root.getIdentity(p)).join("\n");
        }

        function play(): void {
            const active = root.active;
            if (active?.canPlay)
                active.play();
        }

        function pause(): void {
            const active = root.active;
            if (active?.canPause)
                active.pause();
        }

        function playPause(): void {
            const active = root.active;
            if (active?.canTogglePlaying)
                active.togglePlaying();
        }

        function previous(): void {
            const active = root.active;
            if (active?.canGoPrevious)
                active.previous();
        }

        function next(): void {
            const active = root.active;
            if (active?.canGoNext)
                active.next();
        }

        function stop(): void {
            root.active?.stop();
        }

        target: "mpris"
    }
}
