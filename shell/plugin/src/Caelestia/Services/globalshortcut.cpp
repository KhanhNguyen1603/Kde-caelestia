#include "globalshortcut.hpp"

#include <KGlobalAccel>
#include <QKeySequence>
#include <QDebug>
#include <cstdlib>

GlobalShortcut::GlobalShortcut(QObject *parent)
    : QObject(parent), m_action(new QAction(this))
{
    connect(m_action, &QAction::triggered, this, &GlobalShortcut::activated);
}

GlobalShortcut::~GlobalShortcut()
{
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

    QKeySequence seq(m_key);

    // 1. Find system-wide collisions
    QList<KGlobalShortcutInfo> conflicts = KGlobalAccel::globalShortcutsByKey(seq);
    for (const auto &info : conflicts) {
        if (info.componentUniqueName() != "caelestia") {
            // 2. Unbind foreign shortcuts natively via gdbus
            QString cmd = QString("gdbus call --session --dest org.kde.kglobalaccel "
                                  "--object-path /kglobalaccel "
                                  "--method org.kde.KGlobalAccel.setShortcutKeys "
                                  "\"['%1', '%2', '', '']\" \"[([0, 0, 0, 0],)]\" 4")
                                  .arg(info.componentUniqueName())
                                  .arg(info.uniqueName());
            system(cmd.toUtf8().constData());
        }
    }

    // 3. Bind the new shortcut forcefully (NoAutoloading ignores cached ghost shortcuts)
    KGlobalAccel::self()->setShortcut(m_action, QList<QKeySequence>() << seq, KGlobalAccel::NoAutoloading);
}
