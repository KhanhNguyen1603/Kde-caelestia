// SPDX-License-Identifier: GPL-3.0-only
#include "brightnesswatcher.hpp"

#include <qdbusmessage.h>
#include <qloggingcategory.h>

Q_LOGGING_CATEGORY(lcBrightnessWatcher, "caelestia.services.brightnesswatcher", QtInfoMsg)

namespace caelestia::services {

namespace {

// The exact interface Brightness.qml was monitoring via dbus-monitor
constexpr const char* BRIGHTNESS_SERVICE = "org.kde.Solid.PowerManagement";
constexpr const char* BRIGHTNESS_PATH    = "/org/kde/Solid/PowerManagement/Actions/BrightnessControl";
constexpr const char* BRIGHTNESS_IFACE   = "org.kde.Solid.PowerManagement.Actions.BrightnessControl";
constexpr const char* BRIGHTNESS_SIGNAL  = "brightnessChanged";

} // namespace

BrightnessWatcher::BrightnessWatcher(QObject* parent)
    : QObject(parent) {
    auto bus = QDBusConnection::sessionBus();
    if (!bus.isConnected()) {
        qCWarning(lcBrightnessWatcher) << "Cannot connect to D-Bus session bus. Brightness monitoring disabled.";
        return;
    }

    const bool ok = bus.connect(
        BRIGHTNESS_SERVICE,
        BRIGHTNESS_PATH,
        BRIGHTNESS_IFACE,
        BRIGHTNESS_SIGNAL,
        this,
        SLOT(onDbusSignal()));

    if (!ok) {
        qCWarning(lcBrightnessWatcher) << "Failed to connect to brightness D-Bus signal:" << bus.lastError().message();
    } else {
        qCInfo(lcBrightnessWatcher) << "Subscribed to KDE brightness D-Bus signal.";
    }
}

void BrightnessWatcher::onDbusSignal() {
    emit brightnessChanged();
}

} // namespace caelestia::services
