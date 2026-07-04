// SPDX-License-Identifier: GPL-3.0-only
#pragma once

#include <qobject.h>
#include <qprocess.h>
#include <qqmlintegration.h>
#include <qvariant.h>

namespace caelestia::services {

/**
 * C++ replacement for the cliphist subprocess logic in Clipboard.qml.
 * - reload() runs `cliphist list` natively via QProcess and parses in C++
 * - decodeImage() runs `cliphist decode ID` and writes output to a file via QFile,
 *   replacing the `sh -c "cliphist decode ID > /tmp/..."` shell wrapper
 */
class ClipboardManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QVariantList items READ items NOTIFY itemsChanged)

public:
    explicit ClipboardManager(QObject* parent = nullptr);

    [[nodiscard]] QVariantList items() const;

    Q_INVOKABLE void reload();
    Q_INVOKABLE void decodeImage(int id, const QString& outPath);

signals:
    void itemsChanged();

private:
    QVariantList m_items;
    QProcess* m_listProc = nullptr;
};

} // namespace caelestia::services
