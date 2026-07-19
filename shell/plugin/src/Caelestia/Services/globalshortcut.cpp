#include "globalshortcut.hpp"

#include <KGlobalAccel>
#include <QKeySequence>
#include <QDebug>
#include <cstdlib>
#include "../Config/config.hpp"
#include "../Config/generalconfig.hpp"

GlobalShortcut::GlobalShortcut(QObject *parent)
    : QObject(parent), m_action(new QAction(this))
{
    connect(m_action, &QAction::triggered, this, &GlobalShortcut::activated);
}

GlobalShortcut::~GlobalShortcut()
{
    // Restore any KDE shortcuts we stole on startup
    for (const auto &stolen : m_stolenShortcuts) {
        QStringList seqStrings;
        for (const QKeySequence &seq : stolen.keys) {
            int k1 = seq.count() > 0 ? seq[0].toCombined() : 0;
            int k2 = seq.count() > 1 ? seq[1].toCombined() : 0;
            int k3 = seq.count() > 2 ? seq[2].toCombined() : 0;
            int k4 = seq.count() > 3 ? seq[3].toCombined() : 0;
            seqStrings.append(QString("([%1, %2, %3, %4],)").arg(k1).arg(k2).arg(k3).arg(k4));
        }
        
        QString arrayStr = "[" + seqStrings.join(", ") + "]";
        if (seqStrings.isEmpty()) {
            arrayStr = "[([0, 0, 0, 0],)]";
        }
        
        QString cmd = QString("gdbus call --session --dest org.kde.kglobalaccel "
                              "--object-path /kglobalaccel "
                              "--method org.kde.KGlobalAccel.setShortcutKeys "
                              "\"['%1', '%2', '', '']\" \"%3\" 4 > /dev/null 2>&1")
                              .arg(stolen.component)
                              .arg(stolen.action)
                              .arg(arrayStr);
        system(cmd.toUtf8().constData());
    }
}

QString GlobalShortcut::name() const
{
    return m_name;
}

void GlobalShortcut::setName(const QString &name)
{
    if (m_name == name)
        return;

    m_name = name;
    m_action->setObjectName("caelestia-shortcut-" + m_name);
    emit nameChanged();
    updateShortcut();
}

QString GlobalShortcut::key() const
{
    return m_key;
}

void GlobalShortcut::setKey(const QString &key)
{
    if (m_key == key)
        return;

    m_key = key;
    emit keyChanged();
    updateShortcut();
}

QString GlobalShortcut::description() const
{
    return m_description;
}

void GlobalShortcut::setDescription(const QString &description)
{
    if (m_description == description)
        return;

    m_description = description;
    emit descriptionChanged();
    updateShortcut();
}

void GlobalShortcut::updateShortcut()
{
    if (m_name.isEmpty()) {
        return;
    }

    if (m_key.isEmpty()) {
        KGlobalAccel::self()->setShortcut(m_action, QList<QKeySequence>(), KGlobalAccel::NoAutoloading);
        return;
    }

    m_action->setText(m_description.isEmpty() ? "Caelestia Action" : m_description);

    QList<QKeySequence> seqs;
    QStringList parts = m_key.split(";");
    for (const QString &part : parts) {
        QString trimmed = part.trimmed();
        if (!trimmed.isEmpty()) {
            seqs.append(QKeySequence(trimmed));
        }
    }

    if (seqs.isEmpty()) {
        KGlobalAccel::self()->setShortcut(m_action, QList<QKeySequence>(), KGlobalAccel::NoAutoloading);
        return;
    }

    // 1. Find system-wide collisions for all sequences
    for (const QKeySequence &seq : seqs) {
        QList<KGlobalShortcutInfo> conflicts = KGlobalAccel::globalShortcutsByKey(seq);
        for (const auto &info : conflicts) {
            if (info.componentUniqueName() != "caelestia") {
                // Store it to restore on destruction
                m_stolenShortcuts.append({info.componentUniqueName(), info.uniqueName(), info.keys()});
                
                if (caelestia::config::GlobalConfig::instance()->general()->debugLogs()) {
                    qDebug() << "[Caelestia] Unbinding shortcut" << seq.toString() << "from component:" << info.componentUniqueName();
                }

                // 2. Unbind foreign shortcuts natively via gdbus
                QString cmd = QString("gdbus call --session --dest org.kde.kglobalaccel "
                                      "--object-path /kglobalaccel "
                                      "--method org.kde.KGlobalAccel.setShortcutKeys "
                                      "\"['%1', '%2', '', '']\" \"[([0, 0, 0, 0],)]\" 4 > /dev/null 2>&1")
                                      .arg(info.componentUniqueName())
                                      .arg(info.uniqueName());
                system(cmd.toUtf8().constData());
            }
        }
    }

    // 3. Bind the new shortcut forcefully (NoAutoloading ignores cached ghost shortcuts)
    KGlobalAccel::self()->setShortcut(m_action, seqs, KGlobalAccel::NoAutoloading);
}
