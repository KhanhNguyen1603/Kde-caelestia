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

    // Dedup key for progressive metadata (e.g. mpv-mpris/yt-dlp player fills title then artist later).
    property string lastNowPlayingKey: ""

    property string fetchedArtUrl: ""
    readonly property string activeArtUrl: active ? (getArtUrl(active) || fetchedArtUrl) : ""

    onActiveChanged: {
        lastNowPlayingKey = "";
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

        // YouTube and Spotify ALREADY provide their own cover art; they must NEVER call iTunes API
        const identity = getIdentity(player).toLowerCase();
        if (identity.includes("youtube") || identity.includes("spotify")) {
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
        const alias = GlobalConfig.services.playerAliases.values.find(a => a.from === player.identity);
        return alias?.to ?? player.identity;
    }

    function getArtUrl(player: MprisPlayer): string {
        if (!player)
            return "";
        if (player.trackArtUrl && String(player.trackArtUrl).trim() !== "")
            return String(player.trackArtUrl).trim();

        const url = String(player.metadata["xesam:url"] ?? player.metadata["mpris:artUrl"] ?? "");
        const ytMatch = url.match(/(?:youtube\.com\/(?:[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?|shorts)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})/i);
        if (ytMatch && ytMatch[1]) {
            return "https://img.youtube.com/vi/" + ytMatch[1] + "/hqdefault.jpg";
        }

        return "";
    }

    // Quickshell only emits postTrackChanged when trackid/url/title change, so late
    // artist updates (common with mpv-mpris + yt-dlp player) never retrigger it. Watch
    // title/artist too and toast once both are usable.
    function maybeToastNowPlaying(): void {
        if (!GlobalConfig.utilities.toasts.nowPlaying)
            return;

        const player = root.active;
        if (!player)
            return;

        const title = player.trackTitle ?? "";
        const artist = player.trackArtist ?? "";
        if (!title || !artist)
            return;

        const key = `${getIdentity(player)}\0${player.uniqueId}\0${title}\0${artist}`;
        if (key === lastNowPlayingKey)
            return;

        lastNowPlayingKey = key;
        Toaster.toast(qsTr("Now Playing"), qsTr("%1 - %2").arg(artist).arg(title), "music_note");
    }

    Connections {
        function onPostTrackChanged(): void {
            root.fetchArtwork();
            root.maybeToastNowPlaying();
        }

        function onTrackTitleChanged(): void {
            root.fetchArtwork();
            root.maybeToastNowPlaying();
        }

        function onTrackArtistChanged(): void {
            root.fetchArtwork();
            root.maybeToastNowPlaying();
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
        description: qsTr("Toggle media playback")
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
        description: qsTr("Previous track")
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
        description: qsTr("Next track")
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
        description: qsTr("Stop media playback")
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
