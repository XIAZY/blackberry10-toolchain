#ifndef CALCULATORCONTROLLER_H
#define CALCULATORCONTROLLER_H

#include <QtDeclarative/QDeclarativePropertyMap>

class QTimerEvent;

class CalculatorController : public QDeclarativePropertyMap
{
public:
    explicit CalculatorController(QObject *parent = 0);

protected:
    void timerEvent(QTimerEvent *event);

private:
    void processCommand();
    void clear();
    void enterDigit(const QString &digit);
    void enterDecimal();
    void chooseOperator(const QString &op);
    void showResult();
    void changeSign();
    void deleteDigit();
    void setDisplay(const QString &text);
    void setExpression(const QString &text);
    QString formatResult(double value) const;
    double calculate(double left, double right, const QString &op) const;
    bool isFinite(double value) const;

    double m_accumulator;
    QString m_pendingOperator;
    bool m_startNewEntry;
    int m_lastSequence;
    int m_timerId;
};

#endif
