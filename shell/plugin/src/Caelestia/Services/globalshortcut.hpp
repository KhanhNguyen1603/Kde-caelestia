#include <QtQml/qqmlregistration.h>
#pragma once

#include <QObject>
#include <QAction>
#include <QString>

class GlobalShortcut : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QString key READ key WRITE setKey NOTIFY keyChanged)
    Q_PROPERTY(QString description READ description WRITE setDescription NOTIFY descriptionChanged)

public:
    explicit GlobalShortcut(QObject *parent = nullptr);
    ~GlobalShortcut() override;

    QString name() const;
    void setName(const QString &name);

    QString key() const;
    void setKey(const QString &key);

    QString description() const;
    void setDescription(const QString &description);

signals:
    void nameChanged();
    void keyChanged();
    void descriptionChanged();
    void activated();

private:
    void updateShortcut();

    QString m_name;
    QString m_key;
    QString m_description;
    QAction *m_action;
};
