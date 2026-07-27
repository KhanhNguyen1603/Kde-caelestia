pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.Models
import qs.services
import qs.utils

Searcher {
    id: root

    readonly property string currentNamePath: `${Paths.state}/wallpaper/path.txt`
    readonly property list<string> smartArg: GlobalConfig.services.smartScheme ? [] : ["--no-smart"]
    readonly property string fallback: Quickshell.shellPath("assets/wallpapers/Minimal-Paper.png")

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent
    property bool previewColourLock
    property bool pendingPreviewClear

    onActualCurrentChanged: {
        // Sync KDE Plasma wallpaper
        Quickshell.execDetached(["sh", "-c", 'qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "var allDesktops = desktops();for (i=0;i<allDesktops.length;i++) {d = allDesktops[i];d.wallpaperPlugin = \\"org.kde.image\\";d.currentConfigGroup = Array(\\"Wallpaper\\", \\"org.kde.image\\", \\"General\\");d.writeConfig(\\"Image\\", \\"file://$1\\")}"', "--", actualCurrent]);
    }

    readonly property var categories: {
        let dummy = root.list;
        const baseDir = Paths.wallsdir;
        let cats = [];
        for (let i = 0; i < root.list.length; i++) {
            let p = root.list[i].parentDir;
            if (p !== baseDir) {
                let cat = p.slice(baseDir.length + 1);
                if (cat.includes("/")) cat = cat.slice(0, cat.indexOf("/"));
                if (!cats.includes(cat)) cats.push(cat);
            }
        }
        return ["Main"].concat(cats.sort());
    }

    readonly property var grouped: {
        let dummy = root.list;
        const baseDir = Paths.wallsdir;
        let grp = { "Main": [] };
        for (let i = 0; i < root.list.length; i++) {
            let w = root.list[i];
            let p = w.parentDir;
            if (p === baseDir) {
                grp["Main"].push(w);
            } else {
                let cat = p.slice(baseDir.length + 1);
                if (cat.includes("/")) cat = cat.slice(0, cat.indexOf("/"));
                if (!grp[cat]) grp[cat] = [];
                grp[cat].push(w);
            }
        }
        return grp;
    }

    function getCategoryFor(w: FileSystemEntry): string {
        let category = w.parentDir.slice(Paths.wallsdir.length + 1);
        if (category.includes("/"))
            category = category.slice(0, category.indexOf("/"));
        return category;
    }

    function setRandom(): void {
        Quickshell.execDetached(["caelestia", "wallpaper", "-r", ...smartArg]);
    }

    function setNextSequential(): void {
        if (!root.list || root.list.length === 0) return;
        let idx = -1;
        for (let i = 0; i < root.list.length; i++) {
            if (root.list[i].path === actualCurrent) {
                idx = i;
                break;
            }
        }
        idx = (idx + 1) % root.list.length;
        setWallpaper(root.list[idx].path);
    }

    function next(): void {
        if (GlobalConfig.background.slideshowRandom) {
            setRandom();
        } else {
            setNextSequential();
        }
    }

    function setWallpaper(path: string): void {
        actualCurrent = path;
        Quickshell.execDetached(["caelestia", "wallpaper", "-f", path, ...smartArg]);
    }

    function preview(path: string): void {
        previewPath = path;
        showPreview = true;

        if (Colours.scheme === "dynamic")
            getPreviewColoursProc.running = true;
    }

    function stopPreview(): void {
        showPreview = false;
        if (previewColourLock)
            pendingPreviewClear = true;
        else
            Colours.showPreview = false;
    }

    function getThumbnailPath(path: string): string {
        if (Images.isVideo(path)) {
            return `${Paths.cache}/wallpapers/${CUtils.sha256(path)}/first_frame.png`;
        }
        return path;
    }

    // Video wallpapers have no still to show, so the pickers had nothing to draw
    // and sat on a loading spinner forever. Extract a frame once and cache it
    // beside the wallpaper caches, keyed the same way getThumbnailPath already
    // described — that path was being computed but never produced by anything.
    property var videoThumbs: ({})   // source path -> cached frame, once it exists
    property var videoThumbsPending: ({})

    // What a picker should actually display for a wallpaper: the image itself, or
    // a video's extracted frame once there is one. Returns "" for a video whose
    // frame is still being made, so callers can show a placeholder meanwhile.
    function thumbFor(path: string): string {
        const p = String(path || "").replace(/^file:\/\//, "");
        if (p === "" || !Images.isVideo(p))
            return p;
        if (root.videoThumbs[p])
            return root.videoThumbs[p];
        requestVideoThumb(p);
        return "";
    }

    function requestVideoThumb(path: string): void {
        if (root.videoThumbsPending[path] || root.videoThumbs[path])
            return;
        const pending = root.videoThumbsPending;
        pending[path] = true;
        root.videoThumbsPending = pending;

        const out = getThumbnailPath(path);
        const script = 'out="$1"; src="$2"; [ -s "$out" ] || { mkdir -p "$(dirname "$out")"; ' +
                       'ffmpeg -y -loglevel error -i "$src" -vf "thumbnail,scale=640:-1" -frames:v 1 "$out" >/dev/null 2>&1; }; ' +
                       '[ -s "$out" ] && printf %s "$out"';
        const qml = 'import QtQuick\nimport Quickshell.Io\n' +
            'Process {\n' +
            '    id: p\n' +
            '    command: ' + JSON.stringify(["sh", "-c", script, "--", out, path]) + '\n' +
            '    stdout: StdioCollector { onStreamFinished: root.onVideoThumb(' + JSON.stringify(path) + ', (text || "").trim(), p); }\n' +
            '    onExited: code => { if (code !== 0) p.destroy(); }\n' +
            '}';
        try {
            const o = Qt.createQmlObject(qml, root, "videoThumbProc");
            o.running = true;
        } catch (e) {
            Logger.log("[wallpapers] video thumbnail error: " + e.message);
        }
    }

    function onVideoThumb(path: string, out: string, proc: var): void {
        if (out !== "") {
            const m = root.videoThumbs;
            m[path] = out;
            root.videoThumbs = Object.assign({}, m);   // a copy, so bindings re-run
        }
        const pending = root.videoThumbsPending;
        delete pending[path];
        root.videoThumbsPending = pending;
        if (proc)
            proc.destroy();
    }

    onPreviewColourLockChanged: {
        if (!previewColourLock && pendingPreviewClear)
            Colours.showPreview = false;
    }

    list: wallpapers.entries
    key: "relativePath"
    useFuzzy: GlobalConfig.launcher.useFuzzy.wallpapers
    extraOpts: useFuzzy ? ({}) : ({
            forward: false
        })

    IpcHandler {
        function get(): string {
            return root.actualCurrent;
        }

        function set(path: string): void {
            root.setWallpaper(path);
        }

        function list(): string {
            return root.list.map(w => w.path).join("\n");
        }

        target: "wallpaper"
    }

    FileView {
        path: root.currentNamePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            let wall = text().trim();
            if (!wall) {
                wall = root.fallback;
                Quickshell.execDetached(["caelestia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
            }
            root.actualCurrent = wall;
            root.previewColourLock = false;
        }
        onLoadFailed: {
            root.actualCurrent = root.fallback;
            root.previewColourLock = false;
            Quickshell.execDetached(["caelestia", "wallpaper", "-f", root.fallback, ...root.smartArg]);
        }
    }

    FileSystemModel {
        id: wallpapers

        recursive: true
        path: Paths.wallsdir
        filter: FileSystemModel.Files
        nameFilters: Images.validImageExtensions.concat(Images.validVideoExtensions).map(e => `*.${e}`)
    }

    Process {
        id: getPreviewColoursProc

        command: ["caelestia", "wallpaper", "-p", root.previewPath, ...root.smartArg]
        stdout: StdioCollector {
            onStreamFinished: {
                Colours.load(text, true);
                Colours.showPreview = true;
            }
        }
    }
}
