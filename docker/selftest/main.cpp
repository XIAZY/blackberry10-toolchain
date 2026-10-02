#include "probe.h"

#include <QCoreApplication>
#include <QVariant>

extern "C" {
long long selftest_d2lz(double d);
double selftest_l2d(long long x);
}

int main(int argc, char **argv) {
    QCoreApplication app(argc, argv);
    Probe a, b;
    QObject::connect(&a, SIGNAL(valueChanged(int)), &b, SLOT(reset()));
    a.setProperty("value", (int)selftest_d2lz(selftest_l2d(42)));
    return a.value() == 42 && Probe::staticMetaObject.indexOfMethod("setValue(int)") >= 0 ? 0 : 1;
}
