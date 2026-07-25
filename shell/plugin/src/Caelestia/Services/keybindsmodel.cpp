// SPDX-License-Identifier: GPL-3.0-only
#include "keybindsmodel.hpp"

#include <QFile>
#include <QRegularExpression>
#include <QTextStream>
#include <qdir.h>
#include <qjsonarray.h>
#include <qjsonobject.h>
#include <qloggingcategory.h>
#include <qprocess.h>
#include <qsettings.h>
#include <qstandardpaths.h>

Q_LOGGING_CATEGORY(lcKeybinds, "caelestia.services.keybindsmodel", QtInfoMsg)

namespace caelestia::services {

KeybindsModel::KeybindsModel(QObject* parent)
    : QObject(parent) {
    load();
}

QVariantList KeybindsModel::keybinds() const {
    return m_keybinds;
}

bool KeybindsModel::initialized() const {
    return m_initialized;
}

void KeybindsModel::load() {
    if (m_process) {
        m_process->kill();
        m_process->deleteLater();
        m_process = nullptr;
    }

    m_initialized = false;
    emit initializedChanged();

    QVariantList result;

    QString configPath =
        QStandardPaths::locate(QStandardPaths::GenericConfigLocation, "quickshell/caelestia/modules/Shortcuts.qml");
    if (configPath.isEmpty()) {
        configPath = QDir::currentPath() + "/shell/modules/Shortcuts.qml";
    }

    QFile file(configPath);
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&file);

        int braceCount = 0;
        bool inShortcut = false;
        QString name, bind, desc;

        QRegularExpression nameRe(R"(name:\s*["`]([^"`]+)["`])");
        QRegularExpression bindRe(R"(key:\s*["`]([^"`]+)["`])");
        QRegularExpression descRe(R"(description:\s*["`]([^"`]+)["`])");

        while (!in.atEnd()) {
            QString line = in.readLine().trimmed();

            if (line.startsWith("CustomShortcut {")) {
                inShortcut = true;
                braceCount = 1;
                name.clear();
                bind.clear();
                desc.clear();
                continue;
            }

            if (inShortcut) {
                if (line.contains("{"))
                    braceCount += line.count("{");
                if (line.contains("}"))
                    braceCount -= line.count("}");

                if (braceCount == 1) {
                    auto nameMatch = nameRe.match(line);
                    if (nameMatch.hasMatch())
                        name = nameMatch.captured(1);

                    auto bindMatch = bindRe.match(line);
                    if (bindMatch.hasMatch())
                        bind = bindMatch.captured(1);

                    auto descMatch = descRe.match(line);
                    if (descMatch.hasMatch())
                        desc = descMatch.captured(1);
                }

                if (braceCount == 0) {
                    inShortcut = false;

                    if (name.contains("${"))
                        continue; // Skip template items

                    if (!name.isEmpty()) {
                        if (bind.isEmpty() || bind == "none") {
                            continue; // Skip unbound keybinds
                        } else {
                            // Format the binding to look like hyprland keys for consistency
                            bind.replace("Meta", "Super");
                            bind = bind.replace("+", " + ");
                            // Handle cases with semicolon like "Meta+Space; Meta"
                            bind = bind.split(";").first().trimmed();
                        }

                        if (desc.isEmpty())
                            desc = name;

                        result.append(QVariantMap{
                            { "bind", bind },
                            { "action", name },
                            { "description", desc },
                        });
                    }
                }
            }
        }

        // Add workspace shortcuts manually since they are templated in QML
        for (int i = 1; i <= 10; ++i) {
            int keyNum = (i == 10) ? 0 : i;
            result.append(QVariantMap{
                { "bind", QString("Super + %1").arg(keyNum) },
                { "action", QString("workspace%1").arg(i) },
                { "description", QString("Switch to workspace %1").arg(i) },
            });
        }
    } else {
        qWarning(lcKeybinds) << "Failed to open Shortcuts.qml at" << configPath;
    }

    m_keybinds = result;
    m_initialized = true;
    emit keybindsChanged();
    emit initializedChanged();
    emit loaded();
}

QVariantList KeybindsModel::query(const QString& searchText) const {
    if (searchText.isEmpty())
        return m_keybinds;

    const auto lower = searchText.toLower();
    QVariantList result;
    for (const auto& v : m_keybinds) {
        const auto map = v.toMap();
        if (map.value("bind").toString().toLower().contains(lower) ||
            map.value("description").toString().toLower().contains(lower)) {
            result.append(v);
        }
    }
    return result;
}

} // namespace caelestia::services
