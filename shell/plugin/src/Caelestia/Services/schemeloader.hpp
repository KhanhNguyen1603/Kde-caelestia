// SPDX-License-Identifier: GPL-3.0-only
#pragma once

#include <qobject.h>
#include <qqmlintegration.h>
#include <qvariant.h>

class QFileSystemWatcher;

namespace caelestia::services {

/**
 * Replaces `caelestia scheme list` and `caelestia scheme get` subprocess calls
 * in Schemes.qml with native QFile + QJsonDocument reads.
 *
 * Scheme data directory: /usr/lib/python3.x/site-packages/caelestia/data/schemes/
 * Current scheme state:  $XDG_STATE_HOME/caelestia/scheme.json
 */
class SchemeLoader : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_MOC_INCLUDE(<qfilesystemwatcher.h>)

    Q_PROPERTY(QVariantList schemes READ schemes NOTIFY schemesChanged)
    Q_PROPERTY(QString currentScheme READ currentScheme NOTIFY currentSchemeChanged)
    Q_PROPERTY(QString currentVariant READ currentVariant NOTIFY currentSchemeChanged)

public:
    explicit SchemeLoader(QObject* parent = nullptr);
    ~SchemeLoader() override;

    [[nodiscard]] QVariantList schemes() const;
    [[nodiscard]] QString currentScheme() const;
    [[nodiscard]] QString currentVariant() const;

    Q_INVOKABLE void reloadCurrent();

signals:
    void schemesChanged();
    void currentSchemeChanged();

private:
    void loadSchemes();
    void loadCurrentScheme();

    QFileSystemWatcher* m_watcher;
    QVariantList m_schemes;
    QString m_currentScheme;
    QString m_currentVariant;
    QString m_schemeStatePath;
};

} // namespace caelestia::services
