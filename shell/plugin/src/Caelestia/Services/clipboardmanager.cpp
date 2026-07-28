// SPDX-License-Identifier: GPL-3.0-only
#include "clipboardmanager.hpp"

#include "../Config/config.hpp"
#include "../Config/launcherconfig.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qjsonarray.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qloggingcategory.h>
#include <qregularexpression.h>

Q_LOGGING_CATEGORY(lcClipboard, "caelestia.services.clipboard", QtInfoMsg)

namespace caelestia::services {

ClipboardManager::ClipboardManager(QObject* parent)
    : QObject(parent) {
    const auto runtimeDir = qEnvironmentVariable("XDG_RUNTIME_DIR", "/tmp");
    m_imageCacheDir = runtimeDir + "/caelestia-clipboard";

    // Pins live in the state dir, not the runtime dir: they have to outlive a
    // reboot, and they must not sit inside the cache clearHistory() wipes.
    const auto stateDir = qEnvironmentVariable("XDG_STATE_HOME", QDir::homePath() + "/.local/state");
    m_pinDir = stateDir + "/caelestia/clipboard-pins";
    loadPins();
}

QVariantList ClipboardManager::items() const { return m_items; }

QString ClipboardManager::imageCacheDir() const { return m_imageCacheDir; }

bool ClipboardManager::available() const { return m_available; }

void ClipboardManager::setAvailable(bool available) {
    if (m_available == available) {
        return;
    }
    m_available = available;
    emit availableChanged();
}

QVariantList ClipboardManager::pinnedItems() const { return m_pinnedItems; }

QString ClipboardManager::pinFilePath(int pinId, bool isImage) const {
    return m_pinDir + "/" + QString::number(pinId) + (isImage ? ".png" : ".bin");
}

void ClipboardManager::loadPins() {
    QFile index(m_pinDir + "/index.json");
    if (!index.exists() || !index.open(QIODevice::ReadOnly)) {
        return;
    }

    const auto doc = QJsonDocument::fromJson(index.readAll());
    index.close();
    if (!doc.isObject()) {
        qCWarning(lcClipboard) << "Ignoring malformed clipboard pin index";
        return;
    }

    const auto obj = doc.object();
    m_nextPinId = obj.value("nextPinId").toInt(1);

    QVariantList loaded;
    const auto entries = obj.value("pins").toArray();
    for (const auto& value : entries) {
        const auto entry = value.toObject();
        const int pinId = entry.value("pinId").toInt(-1);
        if (pinId < 0) {
            continue;
        }
        const bool isImage = entry.value("isImage").toBool();

        // Drop entries whose payload went missing rather than showing a pin
        // that cannot be pasted.
        const auto path = pinFilePath(pinId, isImage);
        if (!QFileInfo::exists(path)) {
            qCWarning(lcClipboard) << "Dropping clipboard pin with missing payload:" << path;
            continue;
        }

        loaded.append(QVariantMap{
            { "pinId",     pinId                          },
            { "preview",   entry.value("preview").toString() },
            { "isImage",   isImage                        },
            { "imagePath", isImage ? path : QString()     },
        });
    }

    m_pinnedItems = loaded;
    if (!m_pinnedItems.isEmpty()) {
        emit pinnedItemsChanged();
    }
}

void ClipboardManager::savePins() {
    if (!QDir().mkpath(m_pinDir)) {
        qCWarning(lcClipboard) << "Failed to create clipboard pin directory:" << m_pinDir;
        return;
    }

    QJsonArray entries;
    for (const auto& value : std::as_const(m_pinnedItems)) {
        const auto map = value.toMap();
        entries.append(QJsonObject{
            { "pinId",   map.value("pinId").toInt()        },
            { "preview", map.value("preview").toString()   },
            { "isImage", map.value("isImage").toBool()     },
        });
    }

    const QJsonObject root{
        { "nextPinId", m_nextPinId },
        { "pins",      entries     },
    };

    QFile index(m_pinDir + "/index.json");
    if (!index.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        qCWarning(lcClipboard) << "Failed to write clipboard pin index:" << index.fileName();
        return;
    }
    index.write(QJsonDocument(root).toJson(QJsonDocument::Compact));
    index.close();
}

void ClipboardManager::pin(int id) {
    // The preview and kind come from the live list; the bytes come from
    // cliphist, since `preview` is truncated and not the real content.
    QVariantMap source;
    for (const auto& value : std::as_const(m_items)) {
        const auto map = value.toMap();
        if (map.value("id").toInt() == id) {
            source = map;
            break;
        }
    }
    if (source.isEmpty()) {
        qCWarning(lcClipboard) << "Refusing to pin unknown clipboard entry" << id;
        emit pinFailed(id);
        return;
    }

    if (!QDir().mkpath(m_pinDir)) {
        qCWarning(lcClipboard) << "Failed to create clipboard pin directory:" << m_pinDir;
        emit pinFailed(id);
        return;
    }

    const bool isImage = source.value("isImage").toBool();
    const int pinId = m_nextPinId;
    const auto path = pinFilePath(pinId, isImage);
    const auto preview = source.value("preview").toString();

    auto* proc = new QProcess(this);
    proc->setProgram("cliphist");
    proc->setArguments({ "decode", QString::number(id) });

    connect(proc, &QProcess::finished, this,
        [this, proc, id, pinId, path, preview, isImage](int exitCode, QProcess::ExitStatus status) {
            const auto data = proc->readAllStandardOutput();
            proc->deleteLater();

            if (status == QProcess::CrashExit || exitCode != 0 || data.isEmpty()) {
                qCWarning(lcClipboard) << "cliphist decode failed while pinning entry" << id;
                emit pinFailed(id);
                return;
            }

            QFile f(path);
            if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
                qCWarning(lcClipboard) << "Failed to write clipboard pin payload:" << path;
                emit pinFailed(id);
                return;
            }
            f.write(data);
            f.close();

            // Only claim the id once the payload is safely on disk.
            m_nextPinId = pinId + 1;
            m_pinnedItems.append(QVariantMap{
                { "pinId",     pinId                     },
                { "preview",   preview                   },
                { "isImage",   isImage                   },
                { "imagePath", isImage ? path : QString() },
            });
            savePins();
            emit pinnedItemsChanged();
        });

    connect(proc, &QProcess::errorOccurred, this, [this, proc, id](QProcess::ProcessError err) {
        qCWarning(lcClipboard) << "cliphist decode process error while pinning" << id << ":" << err;
        if (err == QProcess::FailedToStart) {
            setAvailable(false);
            proc->deleteLater();
            emit pinFailed(id);
        }
    });

    proc->start();
}

void ClipboardManager::unpin(int pinId) {
    for (int i = 0; i < m_pinnedItems.size(); ++i) {
        const auto map = m_pinnedItems.at(i).toMap();
        if (map.value("pinId").toInt() != pinId) {
            continue;
        }

        const auto path = pinFilePath(pinId, map.value("isImage").toBool());
        if (QFileInfo::exists(path) && !QFile::remove(path)) {
            qCWarning(lcClipboard) << "Failed to remove clipboard pin payload:" << path;
        }

        m_pinnedItems.removeAt(i);
        savePins();
        emit pinnedItemsChanged();
        return;
    }
}

void ClipboardManager::copyPinned(int pinId) {
    for (const auto& value : std::as_const(m_pinnedItems)) {
        const auto map = value.toMap();
        if (map.value("pinId").toInt() != pinId) {
            continue;
        }

        const bool isImage = map.value("isImage").toBool();
        QFile f(pinFilePath(pinId, isImage));
        if (!f.open(QIODevice::ReadOnly)) {
            qCWarning(lcClipboard) << "Failed to read clipboard pin payload:" << f.fileName();
            return;
        }
        const auto data = f.readAll();
        f.close();

        auto* proc = new QProcess(this);
        proc->setProgram("wl-copy");
        // wl-copy sniffs the type from stdin, but binary image data is exactly
        // the case where it guesses wrong, so be explicit.
        proc->setArguments(isImage ? QStringList{ "--type", "image/png" } : QStringList{});

        connect(proc, &QProcess::finished, proc, &QProcess::deleteLater);
        connect(proc, &QProcess::errorOccurred, this, [proc](QProcess::ProcessError err) {
            qCWarning(lcClipboard) << "wl-copy process error:" << err;
            if (err == QProcess::FailedToStart) {
                proc->deleteLater();
            }
        });

        proc->start();
        proc->write(data);
        proc->closeWriteChannel();
        return;
    }

    qCWarning(lcClipboard) << "Refusing to copy unknown clipboard pin" << pinId;
}

void ClipboardManager::reload() {
    // Kill any in-flight list process
    if (m_listProc && m_listProc->state() != QProcess::NotRunning) {
        m_listProc->kill();
        m_listProc->waitForFinished(200);
    }

    auto* proc = new QProcess(this);
    m_listProc = proc;
    proc->setProgram("cliphist");
    proc->setArguments({"list"});

    // Capture the process itself rather than reading m_listProc from the
    // handlers: a crashed cliphist emits errorOccurred() *and* finished() for
    // the same instance, and a superseded reload can deliver signals after
    // m_listProc has already been reassigned.
    const auto release = [this, proc] {
        if (m_listProc == proc) {
            m_listProc = nullptr;
        }
        proc->deleteLater();
    };

    connect(proc, &QProcess::finished, this, [this, proc, release](int exitCode, QProcess::ExitStatus status) {
        const bool current = m_listProc == proc;
        const auto output = proc->readAllStandardOutput();
        release();

        // A newer reload() already replaced this process; its result wins.
        if (!current) {
            return;
        }

        if (status == QProcess::CrashExit || exitCode != 0) {
            qCWarning(lcClipboard) << "cliphist list failed with exit code" << exitCode;
            m_items.clear();
            emit itemsChanged();
            return;
        }

        // Parse natively: each line is "<id>\t<preview>"
        static const QRegularExpression imageRe(
            QStringLiteral(R"(\[\[ binary data \d+ KiB png \d+x\d+ \]\])"));

        QVariantList result;
        const auto lines = output.split('\n');
        result.reserve(lines.size());

        const int maxEntries = caelestia::config::GlobalConfig::instance()->launcher()->clipboardMaxEntries();
        int count = 0;

        for (const auto& rawLine : lines) {
            if (count >= maxEntries) break;

            const auto line = QString::fromUtf8(rawLine);
            if (line.isEmpty()) continue;

            const auto tabIdx = line.indexOf('\t');
            if (tabIdx < 0) continue;

            bool ok = false;
            const int id = line.left(tabIdx).toInt(&ok);
            if (!ok) continue;

            const auto preview = line.mid(tabIdx + 1);
            const bool isImage = imageRe.match(preview).hasMatch();

            result.append(QVariantMap{
                {"id",      id},
                {"preview", preview},
                {"isImage", isImage},
            });
            count++;
        }

        m_items = result;
        emit itemsChanged();

        // Pre-warm: decode all image entries in the background so they are
        // already on disk before the user opens the launcher.
        QDir().mkpath(m_imageCacheDir);
        for (const auto& entry : std::as_const(m_items)) {
            const auto map = entry.toMap();
            if (!map.value("isImage").toBool()) continue;
            const int id = map.value("id").toInt();
            const QString outPath = m_imageCacheDir + "/" + QString::number(id) + ".png";
            // Skip if already cached from a previous reload
            if (QFileInfo::exists(outPath)) {
                emit imageReady(id, outPath);
                continue;
            }
            decodeImage(id, outPath);
        }
    });

    // started() fires exactly when the binary was found and launched, which is
    // the question `available` answers — independent of what cliphist then
    // does with its exit code.
    connect(proc, &QProcess::started, this, [this] { setAvailable(true); });

    connect(proc, &QProcess::errorOccurred, this, [this, release](QProcess::ProcessError err) {
        qCWarning(lcClipboard) << "cliphist list process error:" << err;
        // FailedToStart is the only error for which finished() is not also
        // emitted, so it is the only one this handler has to clean up after.
        if (err == QProcess::FailedToStart) {
            setAvailable(false);
            release();
        }
    });

    proc->start();
}

void ClipboardManager::decodeImage(int id, const QString& outPath) {
    // Ensure output directory exists
    const QFileInfo fi(outPath);
    QDir dir(fi.absolutePath());
    if (!dir.exists() && !dir.mkpath(".")) {
        qCWarning(lcClipboard) << "Failed to create cache directory:" << dir.absolutePath();
        return;
    }

    auto* proc = new QProcess(this);
    proc->setProgram("cliphist");
    proc->setArguments({"decode", QString::number(id)});

    connect(proc, &QProcess::finished, this, [this, proc, outPath, id](int exitCode, QProcess::ExitStatus) {
        if (exitCode != 0) {
            qCWarning(lcClipboard) << "cliphist decode failed for id" << id;
            proc->deleteLater();
            return;
        }

        const auto data = proc->readAllStandardOutput();
        proc->deleteLater();

        QFile f(outPath);
        if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
            qCWarning(lcClipboard) << "Failed to write decoded clipboard image to:" << outPath;
            return;
        }
        f.write(data);
        f.close();

        // Signal QML that this specific image is ready — no timers needed.
        emit imageReady(id, outPath);
    });

    connect(proc, &QProcess::errorOccurred, this, [proc, id](QProcess::ProcessError err) {
        qCWarning(lcClipboard) << "cliphist decode process error for id" << id << ":" << err;
        proc->deleteLater();
    });

    proc->start();
}

void ClipboardManager::clearHistory() {
    // Stop any in-flight list process before wiping history.
    if (m_listProc && m_listProc->state() != QProcess::NotRunning) {
        m_listProc->kill();
        m_listProc->waitForFinished(200);
        m_listProc->deleteLater();
        m_listProc = nullptr;
    }

    if (m_wipeProc && m_wipeProc->state() != QProcess::NotRunning) {
        qCWarning(lcClipboard) << "cliphist wipe already in progress";
        return;
    }

    m_wipeProc = new QProcess(this);
    m_wipeProc->setProgram("cliphist");
    m_wipeProc->setArguments({"wipe"});

    connect(m_wipeProc, &QProcess::finished, this, [this](int exitCode, QProcess::ExitStatus exitStatus) {
        const bool success = (exitStatus == QProcess::NormalExit && exitCode == 0);

        if (!success) {
            qCWarning(lcClipboard) << "cliphist wipe failed with exit code" << exitCode;
            // Reload to keep UI and backend state in sync when wipe fails.
            reload();
            emit clearHistoryFinished(false);
            m_wipeProc->deleteLater();
            m_wipeProc = nullptr;
            return;
        }

        m_items.clear();
        emit itemsChanged();

        QDir cacheDir(m_imageCacheDir);
        if (cacheDir.exists() && !cacheDir.removeRecursively()) {
            qCWarning(lcClipboard) << "Failed to clear clipboard image cache:" << m_imageCacheDir;
        }
        if (!QDir().mkpath(m_imageCacheDir)) {
            qCWarning(lcClipboard) << "Failed to recreate clipboard image cache directory:" << m_imageCacheDir;
        }

        emit clearHistoryFinished(true);
        m_wipeProc->deleteLater();
        m_wipeProc = nullptr;
    });

    connect(m_wipeProc, &QProcess::errorOccurred, this, [this](QProcess::ProcessError err) {
        qCWarning(lcClipboard) << "cliphist wipe process error:" << err;

        if (err == QProcess::FailedToStart && m_wipeProc) {
            // Prevent duplicate completion handling if a finished signal follows.
            m_wipeProc->disconnect(this);
            m_wipeProc->deleteLater();
            m_wipeProc = nullptr;
            reload();
            emit clearHistoryFinished(false);
        }
    });

    m_wipeProc->start();
}

} // namespace caelestia::services
