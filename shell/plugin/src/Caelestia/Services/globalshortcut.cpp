#include "globalshortcut.hpp"

#include <KGlobalAccel>
#include <QKeySequence>
#include <QUuid>
#include <QDebug>

GlobalShortcut::GlobalShortcut(QObject *parent)
    : QObject(parent), m_action(new QAction(this))
{
    // Ensure we have a unique object name for KGlobalAccel so multiple shortcuts don't collide.
    m_action->setObjectName("caelestia-shortcut-" + QUuid::createUuid().toString(QUuid::WithoutBraces));
    
    // Connect QAction trigger to our activated signal
    connect(m_action, &QAction::triggered, this, &GlobalShortcut::activated);
}

GlobalShortcut::~GlobalShortcut()
{
    // Cleanup if needed (QAction is a child, so it's deleted automatically).
    // KGlobalAccel will unregister automatically when the action is destroyed.
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
    if (m_key.isEmpty()) {
        KGlobalAccel::self()->removeAllShortcuts(m_action);
        return;
    }

    m_action->setText(m_description.isEmpty() ? "Caelestia Action" : m_description);

    QKeySequence seq(m_key);
    KGlobalAccel::self()->setGlobalShortcut(m_action, seq);
}
