import QtQuick
import qs.components
import qs.services

PerfStat {
    readonly property real totalSpeed: (NetworkUsage.downloadSpeed ?? 0) + (NetworkUsage.uploadSpeed ?? 0)
    widthFactor: 2.9

    icon: "swap_vert"
    accent: Colours.palette.m3tertiary
    value: NaN
    valueText: {
        const fmt = NetworkUsage.formatBytes(totalSpeed);
        if (!fmt)
            return "0.0 B/s";
        return `${fmt.value.toFixed(1)} ${fmt.unit}`;
    }

    Component.onCompleted: NetworkUsage.refCount += 1
    Component.onDestruction: NetworkUsage.refCount = Math.max(0, NetworkUsage.refCount - 1)
}
