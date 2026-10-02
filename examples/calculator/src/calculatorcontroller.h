#ifndef CALCULATORCONTROLLER_H
#define CALCULATORCONTROLLER_H

#include <QtCore/QObject>
#include <QtCore/QString>

class CalculatorController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString display READ display NOTIFY displayChanged)
    Q_PROPERTY(QString expression READ expression NOTIFY expressionChanged)

public:
    explicit CalculatorController(QObject *parent = 0);

    QString display() const { return m_display; }
    QString expression() const { return m_expression; }

    // Called from QML: command is clear, digit, decimal, operator, equals,
    // sign or delete; argument is the digit or operator.
    Q_INVOKABLE void send(const QString &command, const QString &argument);

signals:
    void displayChanged();
    void expressionChanged();

private:
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

    QString m_display;
    QString m_expression;
    double m_accumulator;
    QString m_pendingOperator;
    bool m_startNewEntry;
};

#endif
