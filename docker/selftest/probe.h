#pragma once

#include <QObject>

// Exercises moc: a property, a signal, a slot and an invokable method.
class Probe : public QObject {
    Q_OBJECT
    Q_PROPERTY(int value READ value WRITE setValue NOTIFY valueChanged)

public:
    explicit Probe(QObject *parent = 0) : QObject(parent), m_value(0) {}
    int value() const { return m_value; }
    Q_INVOKABLE void setValue(int value) {
        if (value != m_value) {
            m_value = value;
            emit valueChanged(value);
        }
    }

public slots:
    void reset() { setValue(0); }

signals:
    void valueChanged(int value);

private:
    int m_value;
};
