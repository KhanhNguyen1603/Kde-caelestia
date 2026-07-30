#include "nightcolorbridge.hpp"
#include <QDBusMessage>
#include <QDBusReply>
#include <QDebug>
#include <QProcess>

#include <QSettings>
#include <QStandardPaths>

namespace caelestia::services {

NightColorBridge::NightColorBridge(QObject* parent)
    : QObject(parent) {

    QDBusConnection::sessionBus().connect("org.kde.KWin", "/org/kde/KWin/NightLight", "org.freedesktop.DBus.Properties",
        "PropertiesChanged", this, SLOT(onPropertiesChanged(QString, QVariantMap, QStringList)));

    fetchInitialState();
}

NightColorBridge::~NightColorBridge() = default;

bool NightColorBridge::active() const {
    return m_active;
}

int NightColorBridge::currentTemperature() const {
    return m_currentTemperature;
}

int NightColorBridge::dayTemperature() const {
    return m_dayTemperature;
}

int NightColorBridge::nightTemperature() const {
    return m_nightTemperature;
}

bool NightColorBridge::autoMode() const {
    return m_autoMode;
}

bool NightColorBridge::available() const {
    return m_available;
}

void NightColorBridge::toggleAutoMode() {
    m_autoMode = !m_autoMode;
    // In KWin 6: Constant = 0, DarkLight = 1
    QString modeStr = m_autoMode ? QStringLiteral("DarkLight") : QStringLiteral("Constant");
    
    QStringList args = {
        QStringLiteral("--notify"),
        QStringLiteral("--file"), QStringLiteral("kwinrc"),
        QStringLiteral("--group"), QStringLiteral("NightColor"),
        QStringLiteral("--key"), QStringLiteral("Mode"),
        modeStr
    };
    QProcess::startDetached(QStringLiteral("kwriteconfig6"), args);

    emit autoModeChanged();
}

void NightColorBridge::toggleNightLight() {
    m_active = !m_active;
    QString activeStr = m_active ? QStringLiteral("true") : QStringLiteral("false");
    
    QStringList args = {
        QStringLiteral("--notify"),
        QStringLiteral("--file"), QStringLiteral("kwinrc"),
        QStringLiteral("--group"), QStringLiteral("NightColor"),
        QStringLiteral("--key"), QStringLiteral("Active"),
        activeStr
    };
    QProcess::startDetached(QStringLiteral("kwriteconfig6"), args);

    emit activeChanged();
}

void NightColorBridge::setDayTemperature(int temp) {
    if (temp <= 0)
        return;

    m_dayTemperature = temp;
    QStringList args = {
        QStringLiteral("--notify"),
        QStringLiteral("--file"), QStringLiteral("kwinrc"),
        QStringLiteral("--group"), QStringLiteral("NightColor"),
        QStringLiteral("--key"), QStringLiteral("DayTemperature"),
        QString::number(temp)
    };
    QProcess::startDetached(QStringLiteral("kwriteconfig6"), args);
    emit dayTemperatureChanged();
}

void NightColorBridge::setNightTemperature(int temp) {
    if (temp <= 0)
        return;

    m_nightTemperature = temp;
    QStringList args = {
        QStringLiteral("--notify"),
        QStringLiteral("--file"), QStringLiteral("kwinrc"),
        QStringLiteral("--group"), QStringLiteral("NightColor"),
        QStringLiteral("--key"), QStringLiteral("NightTemperature"),
        QString::number(temp)
    };
    QProcess::startDetached(QStringLiteral("kwriteconfig6"), args);
    emit nightTemperatureChanged();
}

void NightColorBridge::previewTemperature(int temp) {
    if (temp <= 0) return;
    QDBusMessage msg = QDBusMessage::createMethodCall(
        QStringLiteral("org.kde.KWin"), QStringLiteral("/org/kde/KWin/NightLight"),
        QStringLiteral("org.kde.KWin.NightLight"), QStringLiteral("preview"));
    msg << (uint)temp;
    QDBusConnection::sessionBus().call(msg, QDBus::NoBlock);
}

void NightColorBridge::stopPreview() {
    QDBusMessage msg = QDBusMessage::createMethodCall(
        QStringLiteral("org.kde.KWin"), QStringLiteral("/org/kde/KWin/NightLight"),
        QStringLiteral("org.kde.KWin.NightLight"), QStringLiteral("stopPreview"));
    QDBusConnection::sessionBus().call(msg, QDBus::NoBlock);
}

void NightColorBridge::fetchInitialState() {
    QSettings settings(QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + QStringLiteral("/kwinrc"), QSettings::IniFormat);
    settings.beginGroup(QStringLiteral("NightColor"));
    m_dayTemperature = settings.value(QStringLiteral("DayTemperature"), 6500).toInt();
    m_nightTemperature = settings.value(QStringLiteral("NightTemperature"), 4500).toInt();
    settings.endGroup();

    QDBusMessage msg = QDBusMessage::createMethodCall(
        QStringLiteral("org.kde.KWin"), QStringLiteral("/org/kde/KWin/NightLight"), QStringLiteral("org.freedesktop.DBus.Properties"), QStringLiteral("GetAll"));
    msg << QStringLiteral("org.kde.KWin.NightLight");
    QDBusReply<QVariantMap> reply = QDBusConnection::sessionBus().call(msg);

    if (reply.isValid()) {
        m_available = true;
        updateState(reply.value());
    } else {
        m_available = false;
        qWarning() << "Failed to fetch initial Night Color state:" << reply.error().message();
    }
}

void NightColorBridge::onPropertiesChanged(
    const QString& interface, const QVariantMap& changedProps, const QStringList& invalidatedProps) {
    Q_UNUSED(interface)
    Q_UNUSED(invalidatedProps)
    updateState(changedProps);
}

void NightColorBridge::updateState(const QVariantMap& config) {
    if (config.contains(QStringLiteral("running"))) {
        bool newActive = config.value(QStringLiteral("running")).toBool();
        if (newActive != m_active) {
            m_active = newActive;
            emit activeChanged();
        }
    }

    if (config.contains(QStringLiteral("currentTemperature"))) {
        int newTemp = config.value(QStringLiteral("currentTemperature")).toUInt();
        if (newTemp != m_currentTemperature) {
            m_currentTemperature = newTemp;
            emit currentTemperatureChanged();
        }
    }

    if (config.contains(QStringLiteral("mode"))) {
        bool newAuto = (config.value(QStringLiteral("mode")).toUInt() == 1); // 1 = DarkLight (Auto), 0 = Constant (Manual)
        if (newAuto != m_autoMode) {
            m_autoMode = newAuto;
            emit autoModeChanged();
        }
    }
}

} // namespace caelestia::services
