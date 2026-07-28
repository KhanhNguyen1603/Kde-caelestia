// SPDX-License-Identifier: GPL-3.0-only
#pragma once

#include <qobject.h>
#include <qprocess.h>
#include <qqmlintegration.h>
#include <qstring.h>
#include <qvariant.h>

namespace caelestia::services {

/**
 * C++ replacement for the cliphist subprocess logic in Clipboard.qml.
 * - reload() runs `cliphist list` natively via QProcess and parses in C++
 * - decodeImage() runs `cliphist decode ID` and writes output to a file via QFile.
 *   Emits imageReady(id, path) once the file is fully written so QML can react
 *   immediately instead of relying on a blind timer.
 * - reload() proactively pre-warms all image entries so they are cached on disk
 *   before the user opens the launcher.
 */
class ClipboardManager : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QVariantList items READ items NOTIFY itemsChanged)
    Q_PROPERTY(QString imageCacheDir READ imageCacheDir CONSTANT)
    /// False once cliphist has been found to be missing or unusable, so the UI
    /// can say so instead of showing an unexplained empty list.
    Q_PROPERTY(bool available READ available NOTIFY availableChanged)

public:
    explicit ClipboardManager(QObject* parent = nullptr);

    [[nodiscard]] QVariantList items() const;
    [[nodiscard]] QString imageCacheDir() const;
    [[nodiscard]] bool available() const;

    Q_INVOKABLE void reload();
    Q_INVOKABLE void decodeImage(int id, const QString& outPath);
    Q_INVOKABLE void clearHistory();

signals:
    void itemsChanged();
    /// Emitted after the image file for `id` has been fully written to `path`.
    void imageReady(int id, const QString& path);
    /// Emitted when clearHistory() completes.
    void clearHistoryFinished(bool success);
    void availableChanged();

private:
    void setAvailable(bool available);

    QVariantList m_items;
    bool m_available = true;
    QProcess* m_listProc = nullptr;
    QProcess* m_wipeProc = nullptr;
    QString m_imageCacheDir;
};

} // namespace caelestia::services
