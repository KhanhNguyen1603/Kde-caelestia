#include "globalshortcut.hpp"

#include <KGlobalAccel>
#include <QKeySequence>
#include <QDebug>
#include <QProcess>
#include "../Config/config.hpp"
#include "../Config/generalconfig.hpp"

namespace {

// gdbus parses its arguments as GVariant text, where single quotes delimit
// strings. Component and action names come from other applications'
// KGlobalAccel registrations, so they are untrusted input and must be escaped
// before being placed inside a quoted GVariant string.
QString escapeGVariantString(const QString &value)
{
    QString escaped = value;
    escaped.replace('\\', QStringLiteral("\\\\"));
    escaped.replace('\'', QStringLiteral("\\'"));
    return escaped;
}

// Passes the arguments as real argv entries so no shell ever re-parses them.
void setShortcutKeys(const QString &component, const QString &action, const QString &keys)
{
    QProcess proc;
    proc.setProgram(QStringLiteral("gdbus"));
    proc.setArguments({
        QStringLiteral("call"),
        QStringLiteral("--session"),
        QStringLiteral("--dest"), QStringLiteral("org.kde.kglobalaccel"),
        QStringLiteral("--object-path"), QStringLiteral("/kglobalaccel"),
        QStringLiteral("--method"), QStringLiteral("org.kde.KGlobalAccel.setShortcutKeys"),
        QString("['%1', '%2', '', '']").arg(escapeGVariantString(component), escapeGVariantString(action)),
        keys,
        QStringLiteral("4"),
    });
    proc.setStandardOutputFile(QProcess::nullDevice());
    proc.setStandardErrorFile(QProcess::nullDevice());
    proc.start();
    if (!proc.waitForFinished(2000)) {
        proc.kill();
        proc.waitForFinished(200);
    }
}

} // namespace

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
        
        setShortcutKeys(stolen.component, stolen.action, arrayStr);
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
                setShortcutKeys(info.componentUniqueName(), info.uniqueName(),
                                QStringLiteral("[([0, 0, 0, 0],)]"));
            }
        }
    }

    // 3. Bind the new shortcut forcefully (NoAutoloading ignores cached ghost shortcuts)
    KGlobalAccel::self()->setShortcut(m_action, seqs, KGlobalAccel::NoAutoloading);
}
