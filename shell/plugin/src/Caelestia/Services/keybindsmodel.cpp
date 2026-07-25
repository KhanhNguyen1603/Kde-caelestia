// SPDX-License-Identifier: GPL-3.0-only
#include "keybindsmodel.hpp"

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

    QVariantList result;
    const QString configPath = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + "/kglobalshortcutsrc";
    QSettings settings(configPath, QSettings::IniFormat);

    for (const QString& group : settings.childGroups()) {
        settings.beginGroup(group);
        for (const QString& key : settings.childKeys()) {
            if (key == "_k_friendly_name") continue;
            
            const QString value = settings.value(key).toString();
            const QStringList parts = value.split(',');
            if (parts.size() >= 3) {
                QString bind = parts[0];
                if (bind.isEmpty() || bind == "none") continue;
                
                QString desc = parts[2];
                if (desc.isEmpty()) desc = key;
                
                // Format the binding to look like hyprland keys for consistency (e.g. Super + Space)
                bind.replace("Meta", "Super");
                bind = bind.replace("+", " + ");
                
                result.append(QVariantMap{
                    {"bind", bind},
                    {"action", key},
                    {"description", desc},
                });
            }
        }
        settings.endGroup();
    }

    m_keybinds = result;
    m_initialized = true;
    emit keybindsChanged();
    emit initializedChanged();
    emit loaded();
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
