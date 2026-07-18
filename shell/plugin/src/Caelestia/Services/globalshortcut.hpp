#pragma once

#include <QObject>
#include <QKeySequence>
#include <QString>
#include <QAction>
#include <qqml.h>

class GlobalShortcut : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString key READ key WRITE setKey NOTIFY keyChanged)
    Q_PROPERTY(QString description READ description WRITE setDescription NOTIFY descriptionChanged)

public:
    explicit GlobalShortcut(QObject *parent = nullptr);
    ~GlobalShortcut() override;

    QString key() const;
    void setKey(const QString &key);

    QString description() const;
    void setDescription(const QString &description);

signals:
    void keyChanged();
    void descriptionChanged();
    void activated();

private:
    void updateShortcut();

    QString m_key;
    QString m_description;
    QAction *m_action;
};
