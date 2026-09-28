#include <bb/cascades/AbstractPane>
#include <bb/cascades/Application>
#include <bb/cascades/QmlDocument>
#include "calculatorcontroller.h"

using namespace bb::cascades;

Q_DECL_EXPORT int main(int argc, char **argv)
{
    Application app(argc, argv);
    CalculatorController calculator(&app);

    QmlDocument *document = QmlDocument::create("asset:///main.qml").parent(&app);
    if (document->hasErrors()) {
        return 1;
    }

    document->documentContext()->setContextProperty("calculator", &calculator);

    AbstractPane *root = document->createRootObject<AbstractPane>();
    if (!root) {
        return 1;
    }

    app.setScene(root);
    return Application::exec();
}
