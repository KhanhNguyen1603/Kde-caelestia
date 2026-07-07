import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.Services
import qs.components
import qs.components.controls
import qs.services
import qs.utils
import qs.modules.nexus.common

PageBase {
    id: root

    property bool idleSuspendEnabledState: false
    property int idleSuspendMinutesState: 10

    // Lyrics backends, ordered to match LyricsBackend::Backend (Auto, Local, LRCLIB, NetEase)
    readonly property list<MenuItem> lyricsItems: [
        MenuItem {
            text: qsTr("Auto")
        },
        MenuItem {
            text: "Local"
        },
        MenuItem {
            text: "LRCLIB"
        },
        MenuItem {
            text: "NetEase"
        }
    ]

    // GPU options + the config string each maps to (see Gpu::parseType)
    readonly property list<MenuItem> gpuItems: [
        MenuItem {
            text: qsTr("Auto")
        },
        MenuItem {
            text: "NVIDIA"
        },
        MenuItem {
            text: qsTr("Generic")
        },
        MenuItem {
            text: qsTr("None")
        }
    ]
    readonly property list<string> gpuValues: ["", "NVIDIA", "GENERIC", "None"]



    function gpuKeyToIndex(key: string): int {
        const u = (key ?? "").trim().toUpperCase();
        if (u === "")
            return 0; // Auto
        if (u === "NVIDIA")
            return 1;
        if (u === "GENERIC")
            return 2;
        return 3; // None
    }

    function isSuspendIdleAction(action: var): bool {
        if (!action)
            return false;

        if (typeof action === "string") {
            const normalized = action.trim().toLowerCase();
            return normalized === "suspendthenhibernate" || normalized === "suspend" || normalized === "suspend-then-hibernate" || normalized === "systemctl suspend" || normalized === "systemctl suspend-then-hibernate";
        }

        const isArrayLike = action instanceof Array || (typeof action === "object" && action.length !== undefined);
        if (isArrayLike) {
            for (const a of action) {
                if (root.isSuspendIdleAction(a))
                    return true;
            }
        }

        return false;
    }

    function cloneEntry(entry: var): var {
        const out = {};
        for (const k in entry)
            out[k] = entry[k];
        return out;
    }

    function clonedIdleTimeouts(): var {
        const source = GlobalConfig.general.idle.timeouts ?? [];
        const copy = [];

        for (const entry of source)
            copy.push(root.cloneEntry(entry));

        return copy;
    }

    function refreshIdleSuspendState(): void {
        root.idleSuspendEnabledState = root.suspendTimeoutEnabled();
        root.idleSuspendMinutesState = root.suspendTimeoutMinutes();
    }

    function suspendTimeoutMinutes(): int {
        const entries = GlobalConfig.general.idle.timeouts ?? [];

        for (const entry of entries) {
            if (root.isSuspendIdleAction(entry.idleAction)) {
                const seconds = Number(entry.timeout);
                if (isFinite(seconds) && seconds > 0)
                    return Math.max(1, Math.round(seconds / 60));
            }
        }

        return 10;
    }

    function suspendTimeoutEnabled(): bool {
        const entries = GlobalConfig.general.idle.timeouts ?? [];

        for (const entry of entries) {
            if (root.isSuspendIdleAction(entry.idleAction))
                return entry.enabled ?? true;
        }

        return false;
    }

    function setSuspendTimeoutMinutes(minutes: int): void {
        const sanitizedMinutes = Math.max(1, Math.min(180, Math.round(minutes)));
        const timeoutSeconds = sanitizedMinutes * 60;
        const updated = root.clonedIdleTimeouts();
        let found = false;

        for (let i = 0; i < updated.length; i++) {
            if (!root.isSuspendIdleAction(updated[i].idleAction))
                continue;

            updated[i].timeout = timeoutSeconds;
            if (updated[i].enabled === undefined)
                updated[i].enabled = true;
            found = true;
        }

        if (!found) {
            updated.push({
                timeout: timeoutSeconds,
                idleAction: ["suspendThenHibernate"],
                enabled: true,
                respectInhibitors: true
            });
        }

        GlobalConfig.general.idle.timeouts = updated;
        root.refreshIdleSuspendState();
    }

    function setSuspendTimeoutEnabled(enabled: bool): void {
        const updated = root.clonedIdleTimeouts();
        let found = false;

        for (let i = 0; i < updated.length; i++) {
            if (!root.isSuspendIdleAction(updated[i].idleAction))
                continue;

            updated[i].enabled = enabled;
            found = true;
        }

        if (!found && enabled) {
            updated.push({
                timeout: 600,
                idleAction: ["suspendThenHibernate"],
                enabled: true,
                respectInhibitors: true
            });
        }

        GlobalConfig.general.idle.timeouts = updated;
        root.refreshIdleSuspendState();
    }

    Component.onCompleted: root.refreshIdleSuspendState()

    title: qsTr("Services")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Detected running players, used as default-player options
        Variants {
            id: playerVariants

            model: [...new Set(Players.list.map(p => Players.getIdentity(p)).filter(id => id))]

            MenuItem {
                required property string modelData

                text: modelData
                icon: modelData === GlobalConfig.services.defaultPlayer ? "check" : ""
                activeIcon: "music_note"
            }
        }

        // Notifications
        SectionHeader {
            first: true
            text: qsTr("Notifications")
        }

        NavRow {
            first: true
            last: true
            icon: "notifications"
            label: qsTr("Notifications")
            status: qsTr("Notifications, toasts, timeouts")
            onClicked: root.nState.openSubPage(1)
        }

        // Connections
        SectionHeader {
            text: qsTr("Polling")
        }

        StepperRow {
            first: true
            label: qsTr("Media refresh")
            subtext: qsTr("How often the media position updates (ms)")
            value: GlobalConfig.dashboard.mediaUpdateInterval
            from: 100
            to: 2000
            stepSize: 50
            onMoved: v => GlobalConfig.dashboard.mediaUpdateInterval = v
        }

        StepperRow {
            label: qsTr("System stats refresh")
            subtext: qsTr("CPU, memory and GPU update interval (seconds)")
            value: GlobalConfig.dashboard.resourceUpdateInterval / 1000
            from: 0.5
            to: 10
            stepSize: 0.5
            onMoved: v => GlobalConfig.dashboard.resourceUpdateInterval = Math.round(v * 1000)
        }

        StepperRow {
            last: true
            label: qsTr("Wi-Fi rescan")
            subtext: qsTr("How often available networks are rescanned (seconds)")
            value: GlobalConfig.nexus.networkRescanInterval / 1000
            from: 5
            to: 120
            stepSize: 5
            onMoved: v => GlobalConfig.nexus.networkRescanInterval = Math.round(v * 1000)
        }

        // Media & lyrics
        SectionHeader {
            text: qsTr("Media & lyrics")
        }

        SelectRow {
            first: true
            label: qsTr("Lyrics backend")
            subtext: qsTr("Source used to fetch synced lyrics")
            menuItems: root.lyricsItems
            active: root.lyricsItems[Lyrics.preferredBackend] ?? root.lyricsItems[0]
            onSelected: item => Lyrics.preferredBackend = root.lyricsItems.indexOf(item)
        }

        SelectRow {
            last: true
            label: qsTr("Default player")
            subtext: qsTr("Preferred media player when several are open")
            menuItems: playerVariants.instances
            active: menuItems.find(i => i.text === GlobalConfig.services.defaultPlayer) ?? null
            fallbackIcon: "music_note"
            fallbackText: GlobalConfig.services.defaultPlayer || qsTr("Auto")
            onSelected: item => GlobalConfig.services.defaultPlayer = item.text
        }

        // Input increments
        SectionHeader {
            text: qsTr("Input increments")
        }

        StepperRow {
            first: true
            label: qsTr("Volume step")
            subtext: qsTr("Amount the volume changes per scroll (%)")
            value: Math.round(GlobalConfig.services.audioIncrement * 100)
            from: 1
            to: 50
            stepSize: 1
            onMoved: v => GlobalConfig.services.audioIncrement = v / 100
        }

        StepperRow {
            label: qsTr("Brightness step")
            subtext: qsTr("Amount the brightness changes per scroll (%)")
            value: Math.round(GlobalConfig.services.brightnessIncrement * 100)
            from: 1
            to: 50
            stepSize: 1
            onMoved: v => GlobalConfig.services.brightnessIncrement = v / 100
        }

        StepperRow {
            last: true
            label: qsTr("Max volume")
            subtext: qsTr("Upper limit for output volume (%)")
            value: Math.round(GlobalConfig.services.maxVolume * 100)
            from: 50
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.services.maxVolume = v / 100
        }

        // Idle behavior
        SectionHeader {
            text: qsTr("Idle & sleep")
        }

        ToggleRow {
            first: true
            text: qsTr("Idle suspend")
            subtext: qsTr("Suspend the system after inactivity")
            checked: root.idleSuspendEnabledState
            onToggled: root.setSuspendTimeoutEnabled(checked)
        }

        StepperRow {
            last: true
            enabled: root.idleSuspendEnabledState
            label: qsTr("Idle suspend timer")
            subtext: root.idleSuspendEnabledState
                     ? qsTr("Suspend after %1 minute(s) of inactivity").arg(root.idleSuspendMinutesState)
                     : qsTr("Enable idle suspend to apply a timer")
            value: root.idleSuspendMinutesState
            from: 1
            to: 180
            stepSize: 1
            onMoved: v => {
                if (root.idleSuspendEnabledState)
                    root.setSuspendTimeoutMinutes(v)
            }
        }

        // Service tuning
        SectionHeader {
            text: qsTr("Service tuning")
        }

        NavRow {
            first: true
            icon: "sports_esports"
            label: qsTr("Game mode")
            status: qsTr("Manage how Caelestia behaves while gaming")
            onClicked: root.nState.openSubPage(2)
        }

        NavRow {
            icon: "chat" // Using chat since discord icon might not be available in Material icons
            label: qsTr("Discord Rich Presence")
            status: qsTr("Broadcast your status to Vesktop")
            onClicked: root.nState.openSubPage(4)
        }

        StepperRow {
            label: qsTr("Visualiser bars")
            subtext: qsTr("Number of bars in the audio visualisers")
            value: GlobalConfig.services.visualiserBars
            from: 10
            to: 120
            stepSize: 2
            onMoved: v => GlobalConfig.services.visualiserBars = v
        }

        ToggleRow {
            text: Strings.localizeEnglishSpelling(qsTr("Smart colour scheme"))
            subtext: qsTr("Derive theme mode and variant from the wallpaper")
            checked: GlobalConfig.services.smartScheme
            onToggled: GlobalConfig.services.smartScheme = checked
        }


        SelectRow {
            Layout.fillWidth: true
            last: true
            label: qsTr("GPU")
            subtext: Gpu.name ? qsTr("Monitoring: %1").arg(Gpu.name) : qsTr("Override for GPU type")
            menuOnTop: true
            menuItems: root.gpuItems
            active: root.gpuItems[root.gpuKeyToIndex(GlobalConfig.services.gpuType)]
            onSelected: item => GlobalConfig.services.gpuType = root.gpuValues[root.gpuItems.indexOf(item)]
        }
    }
}
