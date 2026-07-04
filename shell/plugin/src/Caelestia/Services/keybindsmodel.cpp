// SPDX-License-Identifier: GPL-3.0-only
#include "keybindsmodel.hpp"

#include <qdir.h>
#include <qjsonarray.h>
#include <qjsonobject.h>
#include <qloggingcategory.h>
#include <qprocess.h>
#include <qstandardpaths.h>

Q_LOGGING_CATEGORY(lcKeybinds, "caelestia.services.keybindsmodel", QtInfoMsg)

namespace caelestia::services {

KeybindsModel::KeybindsModel(QObject* parent)
    : QObject(parent) {
    load();
}

QVariantList KeybindsModel::keybinds() const { return m_keybinds; }
bool KeybindsModel::initialized() const { return m_initialized; }

void KeybindsModel::load() {
    if (m_process) {
        m_process->kill();
        m_process->deleteLater();
        m_process = nullptr;
    }

    m_initialized = false;
    emit initializedChanged();

    auto* process = new QProcess(this);
    m_process = process;
    const auto mockPath = QDir::homePath() + "/.local/bin/hyprctl";
    process->setProgram(QFile::exists(mockPath) ? mockPath : "hyprctl"); // In KDE this resolves to the mock ~/.local/bin/hyprctl script
    process->setArguments({"binds", "-j"});

    connect(process, &QProcess::finished, this, [this, process](int exitCode, QProcess::ExitStatus status) {
        if (m_process == process) {
            m_process = nullptr;
        }

        if (status == QProcess::CrashExit || exitCode != 0) {
            qCWarning(lcKeybinds) << "Failed to fetch keybinds, hyprctl exited with code" << exitCode;
            process->deleteLater();
            return;
        }

        const auto response = process->readAllStandardOutput();
        process->deleteLater();

        const auto doc = QJsonDocument::fromJson(response);
        if (!doc.isArray()) {
            qCWarning(lcKeybinds) << "Failed to parse keybinds JSON from hyprctl";
            return;
        }

        const auto binds = doc.array();
        QVariantList result;
        result.reserve(static_cast<int>(binds.size()));

        for (const auto& b : binds) {
            const auto obj = b.toObject();
            const auto key = obj.value("key").toString();

            if (key.isEmpty() && !obj.value("catch_all").toBool()) {
                continue;
            }

            const auto dispatcher = obj.value("dispatcher").toString();
            const auto arg = obj.value("arg").toString();
            const auto description = obj.value("description").toString();
            const auto catchAll = obj.value("catch_all").toBool();

            const auto action = dispatcher.isEmpty()
                ? obj.value("command").toString()
                : (arg.isEmpty() ? dispatcher : dispatcher + ' ' + arg);
            const auto descText = description.isEmpty() ? action : description;

            const auto m = obj.value("modmask").toInt();
            QStringList mods;
            if (m & 64) mods << "Super";
            if (m & 8)  mods << "Alt";
            if (m & 4)  mods << "Ctrl";
            if (m & 1)  mods << "Shift";

            const auto keyText = catchAll ? QStringLiteral("Catchall") : key;
            auto bindText = mods.join(" + ");
            if (!bindText.isEmpty()) bindText += " + ";
            bindText += keyText;

            result.append(QVariantMap{
                {"bind",        bindText},
                {"action",      action},
                {"description", descText},
            });
        }

        m_keybinds = result;
        m_initialized = true;
        emit keybindsChanged();
        emit initializedChanged();
        emit loaded();
    });

    connect(process, &QProcess::errorOccurred, this, [this, process](QProcess::ProcessError err) {
        qCWarning(lcKeybinds) << "hyprctl process error:" << err;
        if (m_process == process) {
            m_process = nullptr;
        }
        process->deleteLater();
    });

    m_process->start();
}

QVariantList KeybindsModel::query(const QString& searchText) const {
    if (searchText.isEmpty()) return m_keybinds;

    const auto lower = searchText.toLower();
    QVariantList result;
    for (const auto& v : m_keybinds) {
        const auto map = v.toMap();
        if (map.value("bind").toString().toLower().contains(lower)
            || map.value("description").toString().toLower().contains(lower)) {
            result.append(v);
        }
    }
    return result;
}

} // namespace caelestia::services
