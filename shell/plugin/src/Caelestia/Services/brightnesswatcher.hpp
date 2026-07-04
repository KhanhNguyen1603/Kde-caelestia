// SPDX-License-Identifier: GPL-3.0-only
#pragma once

#include <qdbusconnection.h>
#include <qobject.h>
#include <qqmlintegration.h>

namespace caelestia::services {

/**
 * Subscribes to the KDE Solid PowerManagement D-Bus brightness signal
 * instead of running a persistent `dbus-monitor` process.
 *
 * Used by Brightness.qml to replace:
 *   Process { command: ["dbus-monitor", "...brightnessChanged..."] }
 */
class BrightnessWatcher : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit BrightnessWatcher(QObject* parent = nullptr);

signals:
    /// Emitted whenever the KDE brightness D-Bus signal fires.
    void brightnessChanged();

private slots:
    void onDbusSignal();
};

} // namespace caelestia::services
