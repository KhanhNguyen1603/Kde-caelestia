// SPDX-License-Identifier: GPL-3.0-only
#pragma once

#include <qprocess.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qvariant.h>
#include <qjsondocument.h>

namespace caelestia::services {

class KeybindsModel : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QVariantList keybinds READ keybinds NOTIFY keybindsChanged)
    Q_PROPERTY(bool initialized READ initialized NOTIFY initializedChanged)

public:
    explicit KeybindsModel(QObject* parent = nullptr);

    [[nodiscard]] QVariantList keybinds() const;
    [[nodiscard]] bool initialized() const;

    Q_INVOKABLE void load();
    Q_INVOKABLE QVariantList query(const QString& searchText) const;

signals:
    void keybindsChanged();
    void initializedChanged();
    void loaded();

private:
    QVariantList m_keybinds;
    bool m_initialized = false;

    QProcess* m_process = nullptr;
};

} // namespace caelestia::services
