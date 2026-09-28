#include "calculatorcontroller.h"

#include <QtCore/QTimerEvent>
#include <float.h>
#include <math.h>
#include <limits>

CalculatorController::CalculatorController(QObject *parent)
    : QDeclarativePropertyMap(parent),
      m_accumulator(0.0),
      m_pendingOperator(),
      m_startNewEntry(true),
      m_lastSequence(0),
      m_timerId(0)
{
    insert("display", QString("0"));
    insert("expression", QString());
    insert("command", QString());
    insert("argument", QString());
    insert("sequence", m_lastSequence);

    // QDeclarativePropertyMap provides the dynamic properties consumed by QML.
    // A short timer lets this class receive QML property writes without needing
    // a separately generated Qt meta-object (moc), which the BB10 Linux SDK omits.
    m_timerId = startTimer(16);
}

void CalculatorController::timerEvent(QTimerEvent *event)
{
    if (event->timerId() == m_timerId) {
        processCommand();
        return;
    }

    QDeclarativePropertyMap::timerEvent(event);
}

void CalculatorController::processCommand()
{
    const int sequence = value("sequence").toInt();
    if (sequence == m_lastSequence) {
        return;
    }

    m_lastSequence = sequence;
    const QString command = value("command").toString();
    const QString argument = value("argument").toString();

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
    QString current = value("display").toString();
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
    const QString current = value("display").toString();
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
    if (op == "−") return left - right;
    if (op == "×") return left * right;
    if (op == "÷") {
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
    if (value("display").toString() == "Error") {
        clear();
    }

    bool ok = false;
    double current = value("display").toString().toDouble(&ok);
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
    const QString display = value("display").toString();
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
    const QString current = value("display").toString();
    if (current != "0" && current != "Error") {
        setDisplay(current.startsWith('-') ? current.mid(1) : "-" + current);
    }
}

void CalculatorController::deleteDigit()
{
    const QString current = value("display").toString();
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
    insert("display", text);
}

void CalculatorController::setExpression(const QString &text)
{
    insert("expression", text);
}
