// SPDX-License-Identifier: GPL-3.0-only
#include "schemeloader.hpp"

#include <algorithm>

#include <qdir.h>
#include <qfile.h>
#include <qfilesystemwatcher.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qloggingcategory.h>
#include <qprocess.h>

Q_LOGGING_CATEGORY(lcSchemeLoader, "caelestia.services.schemeloader", QtInfoMsg)

namespace caelestia::services {

SchemeLoader::SchemeLoader(QObject* parent)
    : QObject(parent)
    , m_watcher(new QFileSystemWatcher(this)) {
    // scheme.json state path: $XDG_STATE_HOME/caelestia/scheme.json
    const auto stateDir = qEnvironmentVariable("XDG_STATE_HOME",
        QDir::homePath() + "/.local/state");
    m_schemeStatePath = stateDir + "/caelestia/scheme.json";

    // Watch for changes to scheme.json
    if (QFile::exists(m_schemeStatePath)) {
        m_watcher->addPath(m_schemeStatePath);
    }
    connect(m_watcher, &QFileSystemWatcher::fileChanged, this, [this](const QString&) {
        loadCurrentScheme();
        // Re-add path because some editors replace files atomically
        if (!m_watcher->files().contains(m_schemeStatePath)) {
            m_watcher->addPath(m_schemeStatePath);
        }
    });

    loadSchemes();
    loadCurrentScheme();
}

SchemeLoader::~SchemeLoader() = default;

QVariantList SchemeLoader::schemes() const { return m_schemes; }
QString SchemeLoader::currentScheme() const { return m_currentScheme; }
QString SchemeLoader::currentVariant() const { return m_currentVariant; }

void SchemeLoader::reloadCurrent() {
    loadCurrentScheme();
}

void SchemeLoader::loadSchemes() {
    auto process = new QProcess(this);
    process->setProgram("caelestia");
    process->setArguments({"scheme", "list"});
    
    connect(process, &QProcess::finished, this, [this, process](int exitCode, QProcess::ExitStatus status) {
        process->deleteLater();
        if (status == QProcess::CrashExit || exitCode != 0) {
            qCWarning(lcSchemeLoader) << "Failed to fetch schemes list";
            return;
        }

        const auto response = process->readAllStandardOutput();
        const auto doc = QJsonDocument::fromJson(response);
        if (!doc.isObject()) return;
        
        const auto obj = doc.object();
        QVariantList flat;
        
        for (auto it = obj.begin(); it != obj.end(); ++it) {
            const auto schemeName = it.key();
            const auto flavours = it.value().toObject();
            for (auto fit = flavours.begin(); fit != flavours.end(); ++fit) {
                const auto flavourName = fit.key();
                const auto colours = fit.value().toObject();
                
                flat.append(QVariantMap{
                    {"name", schemeName},
                    {"flavour", flavourName},
                    {"colours", colours.toVariantMap()}
                });
            }
        }
        
        std::sort(flat.begin(), flat.end(), [](const QVariant& a, const QVariant& b) {
            const auto ma = a.toMap();
            const auto mb = b.toMap();
            const auto ka = ma.value("name").toString() + ma.value("flavour").toString();
            const auto kb = mb.value("name").toString() + mb.value("flavour").toString();
            return ka.localeAwareCompare(kb) < 0;
        });

        m_schemes = flat;
        emit schemesChanged();
    });
    
    process->start();
}

void SchemeLoader::loadCurrentScheme() {
    QFile f(m_schemeStatePath);
    if (!f.exists() || !f.open(QIODevice::ReadOnly)) {
        return;
    }

    const auto doc = QJsonDocument::fromJson(f.readAll());
    if (!doc.isObject()) return;

    const auto obj = doc.object();
    const auto name = obj.value("name").toString();
    const auto flavour = obj.value("flavour").toString();
    const auto variant = obj.value("variant").toString();

    m_currentScheme = QString("%1 %2").arg(name, flavour);
    m_currentVariant = variant;

    emit currentSchemeChanged();
}

} // namespace caelestia::services
