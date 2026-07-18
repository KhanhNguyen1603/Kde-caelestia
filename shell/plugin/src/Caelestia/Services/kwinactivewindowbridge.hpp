#pragma once

#include <QObject>
#include <QVariantMap>
#include <QVariantList>
#include <QQmlEngine>
#include <QtDBus/QDBusAbstractAdaptor>
#include <QtDBus/QDBusConnection>

namespace caelestia::services {

class KWinActiveWindowBridgeAdaptor : public QDBusAbstractAdaptor {
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "dev.caelestia.KWinActiveWindow")
public:
    explicit KWinActiveWindowBridgeAdaptor(QObject *parent);
    
public slots:
    Q_NOREPLY void notifyActiveWindow(const QString &uuid, const QString &title, const QString &appClass, const QString &activeOutputName);
    Q_NOREPLY void notifyWindowList(const QString &windowsJson);
};

class KWinActiveWindowBridge : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantMap activeWindow READ activeWindow NOTIFY activeWindowChanged)
    Q_PROPERTY(QString activeOutputName READ activeOutputName NOTIFY activeWindowChanged)
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit KWinActiveWindowBridge(QObject *parent = nullptr);
    ~KWinActiveWindowBridge() override;

    QVariantMap activeWindow() const;
    QString activeOutputName() const;

    void updateActiveWindow(const QString &uuid, const QString &title, const QString &appClass, const QString &activeOutputName);
    void updateWindowList(const QString &windowsJson);

signals:
    void activeWindowChanged();

private:
    void injectKWinScript();

    QVariantMap m_activeWindow;
    QString m_activeOutputName;
    QString m_scriptName;
};

} // namespace caelestia::services
