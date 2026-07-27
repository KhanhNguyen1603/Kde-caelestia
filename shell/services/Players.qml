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
    readonly property MprisPlayer active: props.manualActive ?? list.find(p => p.isPlaying && (p.trackTitle ?? "") !== "") ?? list.find(p => getIdentity(p) === GlobalConfig.services.defaultPlayer) ?? list.find(p => (p.trackTitle ?? "") !== "") ?? list[0] ?? null
    property alias manualActive: props.manualActive

    // Dedup key for progressive metadata (e.g. mpv-mpris/yt-dlp player fills title then artist later).
    property string lastNowPlayingKey: ""

    property string fetchedArtUrl: ""
    readonly property string activeArtUrl: active ? (getArtUrl(active) || fetchedArtUrl) : ""

    property string lastFetchedTitle: ""

    function isPlaceholderTitle(title: string): bool {
        if (!title) return true;
        const clean = title.toLowerCase().trim();
        return clean.startsWith("spotify - web player") ||
               clean.startsWith("youtube - web player") ||
               clean.startsWith("youtube music") ||
               clean === "spotify" ||
               clean === "youtube" ||
               clean === "web player" ||
               clean === "unknown title";
    }

    function fetchArtwork() {
        const player = root.active;
        if (!player) {
            fetchedArtUrl = "";
            lastFetchedTitle = "";
            return;
        }

        if (getArtUrl(player) !== "") {
            fetchedArtUrl = "";
            lastFetchedTitle = "";
            return;
        }

        const title = player.trackTitle ? player.trackTitle.trim() : "";
        if (title === "" || isPlaceholderTitle(title)) {
            // Keep previous fetchedArtUrl when paused on generic web player titles
            return;
        }

        if (title === lastFetchedTitle && fetchedArtUrl !== "")
            return;

        lastFetchedTitle = title;

        // Clean title only (strip unclosed/closed brackets, keywords)
        let cleanTitle = title;
        cleanTitle = cleanTitle.replace(/[\(\[\{][^\)\]\}]*$/, "");
        cleanTitle = cleanTitle.replace(/\s*[\(\[\{].*?[\)\]\}]\s*/g, " ");
        cleanTitle = cleanTitle.replace(/\s+(feat|ft|featuring)\..*/gi, "");
        cleanTitle = cleanTitle.replace(/\s+(remix|music video|official video|lyric video|lyrics|audio|mv|hd|4k)\b/gi, " ");
        cleanTitle = cleanTitle.trim();

        if (cleanTitle === "")
            cleanTitle = title.trim();

        // Search ONLY by title
        const queryUrl = "https://itunes.apple.com/search?term=" + encodeURIComponent(cleanTitle) + "&entity=song&limit=1";

        const xhr = new XMLHttpRequest();
        xhr.open("GET", queryUrl);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    const response = JSON.parse(xhr.responseText);
                    if (response.results && response.results.length > 0) {
                        fetchedArtUrl = response.results[0].artworkUrl100 || "";
                    } else {
                        fetchedArtUrl = "";
                    }
                } catch (e) {
                    fetchedArtUrl = "";
                }
            }
        };
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

        // 1. Extract Youtube Video ID from any Youtube URL format (highest priority for Youtube)
        const url = String(player.metadata["xesam:url"] ?? player.metadata["mpris:artUrl"] ?? player.trackArtUrl ?? "");
        const ytMatch = url.match(/(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/|ytimg\.com\/vi\/)([^"&?\/\s]{11})/i);
        if (ytMatch && ytMatch[1]) {
            return "https://img.youtube.com/vi/" + ytMatch[1] + "/mqdefault.jpg";
        }

        // 2. Ignore Chrome temporary local file paths (/tmp/.org.chromium...) and plasma browser integration cache
        const art = player.trackArtUrl ? String(player.trackArtUrl).trim() : "";
        if (art !== "" && !art.includes(".org.chromium.Chromium") && !art.includes("/tmp/") && !art.includes("plasma-browser-integration")) {
            return art;
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

    onActiveChanged: {
        lastNowPlayingKey = "";
        fetchArtwork();
    }

    Connections {
        function onPostTrackChanged(): void {
            root.maybeToastNowPlaying();
            root.fetchArtwork();
        }

        function onTrackTitleChanged(): void {
            root.maybeToastNowPlaying();
            root.fetchArtwork();
        }

        function onTrackArtistChanged(): void {
            root.maybeToastNowPlaying();
            root.fetchArtwork();
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
