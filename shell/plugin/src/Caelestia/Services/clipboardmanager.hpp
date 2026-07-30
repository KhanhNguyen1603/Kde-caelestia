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
    /// Entries kept outside cliphist's rotation. Each is a map of pinId,
    /// preview, isImage and imagePath, the last only for images.
    Q_PROPERTY(QVariantList pinnedItems READ pinnedItems NOTIFY pinnedItemsChanged)

public:
    explicit ClipboardManager(QObject* parent = nullptr);

    [[nodiscard]] QVariantList items() const;
    [[nodiscard]] QString imageCacheDir() const;
    [[nodiscard]] bool available() const;
    [[nodiscard]] QVariantList pinnedItems() const;

    Q_INVOKABLE void reload();
    Q_INVOKABLE void decodeImage(int id, const QString& outPath);
    Q_INVOKABLE void clearHistory();

    /// Decodes the cliphist entry `id` in full and stores its bytes, so the
    /// entry survives cliphist's rotation and clearHistory().
    Q_INVOKABLE void pin(int id);
    Q_INVOKABLE void unpin(int pinId);
    /// Pinned entries are no longer in cliphist, so `cliphist decode` cannot
    /// bring them back — the stored bytes go to wl-copy directly.
    Q_INVOKABLE void copyPinned(int pinId);

signals:
    void itemsChanged();
    /// Emitted after the image file for `id` has been fully written to `path`.
    void imageReady(int id, const QString& path);
    /// Emitted when clearHistory() completes.
    void clearHistoryFinished(bool success);
    void availableChanged();
    void pinnedItemsChanged();
    /// Emitted when pin() fails, so the UI can say the entry was not kept.
    void pinFailed(int id);

private:
    void setAvailable(bool available);

    void loadPins();
    void savePins();
    QString pinFilePath(int pinId, bool isImage) const;

    QVariantList m_items;
    bool m_available = true;
    QProcess* m_listProc = nullptr;
    QProcess* m_wipeProc = nullptr;
    QString m_imageCacheDir;

    QVariantList m_pinnedItems;
    QString m_pinDir;
    int m_nextPinId = 1;
};

} // namespace caelestia::services
