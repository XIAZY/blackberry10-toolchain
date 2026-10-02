#include "calculatorcontroller.h"

#include <float.h>
#include <math.h>
#include <limits>

CalculatorController::CalculatorController(QObject *parent)
    : QObject(parent),
      m_display("0"),
      m_accumulator(0.0),
      m_pendingOperator(),
      m_startNewEntry(true)
{
}

void CalculatorController::send(const QString &command, const QString &argument)
{
    if (command == "clear") {
        clear();
    } else if (command == "digit") {
        enterDigit(argument);
    } else if (command == "decimal") {
        enterDecimal();
    } else if (command == "operator") {
        chooseOperator(argument);
    } else if (command == "equals") {
        showResult();
    } else if (command == "sign") {
        changeSign();
    } else if (command == "delete") {
        deleteDigit();
    }
}

void CalculatorController::clear()
{
    setDisplay("0");
    m_accumulator = 0.0;
    m_pendingOperator.clear();
    m_startNewEntry = true;
    setExpression(QString());
}

void CalculatorController::enterDigit(const QString &digit)
{
    QString current = m_display;
    if (current == "Error" || m_startNewEntry) {
        setDisplay(digit);
        m_startNewEntry = false;
        setExpression(QString());
        return;
    }

    if (current.length() < 14) {
        setDisplay(current == "0" ? digit : current + digit);
    }
}

void CalculatorController::enterDecimal()
{
    const QString current = m_display;
    if (current == "Error" || m_startNewEntry) {
        setDisplay("0.");
        m_startNewEntry = false;
        setExpression(QString());
    } else if (!current.contains('.')) {
        setDisplay(current + ".");
    }
}

QString CalculatorController::formatResult(double value) const
{
    if (!isFinite(value)) {
        return "Error";
    }

    const double rounded = floor(value * 10000000000.0 + 0.5) / 10000000000.0;
    if (!isFinite(rounded)) {
        return QString::number(value, 'g', 8);
    }

    QString result = QString::number(rounded, 'g', 15);
    if (result.length() > 14) {
        result = QString::number(rounded, 'g', 8);
    }
    return result;
}

double CalculatorController::calculate(double left, double right, const QString &op) const
{
    if (op == "+") return left + right;
    // Qt 4 reads plain C string literals as Latin-1, so compare the UTF-8
    // operator symbols explicitly.
    if (op == QString::fromUtf8("−")) return left - right;
    if (op == QString::fromUtf8("×")) return left * right;
    if (op == QString::fromUtf8("÷")) {
        return right == 0.0 ? std::numeric_limits<double>::quiet_NaN() : left / right;
    }
    return right;
}

bool CalculatorController::isFinite(double value) const
{
    return value == value && value <= DBL_MAX && value >= -DBL_MAX;
}

void CalculatorController::chooseOperator(const QString &op)
{
    if (m_display == "Error") {
        clear();
    }

    bool ok = false;
    double current = m_display.toDouble(&ok);
    if (!ok) {
        current = 0.0;
    }

    if (!m_pendingOperator.isEmpty() && !m_startNewEntry) {
        current = calculate(m_accumulator, current, m_pendingOperator);
        setDisplay(formatResult(current));
    }

    if (!isFinite(current)) {
        clear();
        setDisplay("Error");
        return;
    }

    m_accumulator = current;
    m_pendingOperator = op;
    m_startNewEntry = true;
    setExpression(formatResult(current) + "  " + op);
}

void CalculatorController::showResult()
{
    const QString display = m_display;
    if (m_pendingOperator.isEmpty() || display == "Error") {
        return;
    }

    setExpression(formatResult(m_accumulator) + "  " + m_pendingOperator +
                  "  " + display + "  =");

    bool ok = false;
    const double right = display.toDouble(&ok);
    const double result = calculate(m_accumulator, ok ? right : 0.0, m_pendingOperator);
    setDisplay(formatResult(result));
    m_pendingOperator.clear();
    m_startNewEntry = true;
}

void CalculatorController::changeSign()
{
    const QString current = m_display;
    if (current != "0" && current != "Error") {
        setDisplay(current.startsWith('-') ? current.mid(1) : "-" + current);
    }
}

void CalculatorController::deleteDigit()
{
    const QString current = m_display;
    if (current == "Error" || m_startNewEntry || current.length() <= 1 ||
        (current.length() == 2 && current.startsWith('-'))) {
        setDisplay("0");
        m_startNewEntry = true;
    } else {
        setDisplay(current.left(current.length() - 1));
    }
}

void CalculatorController::setDisplay(const QString &text)
{
    if (text != m_display) {
        m_display = text;
        emit displayChanged();
    }
}

void CalculatorController::setExpression(const QString &text)
{
    if (text != m_expression) {
        m_expression = text;
        emit expressionChanged();
    }
}
