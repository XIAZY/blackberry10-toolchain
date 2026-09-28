import bb.cascades 1.3

Page {
    titleBar: TitleBar {
        title: "Calculator"
    }

    function send(command, argument) {
        calculator.argument = argument
        calculator.command = command
        calculator.sequence = calculator.sequence + 1
    }

    Container {
        leftPadding: 20
        rightPadding: 20
        topPadding: 20
        bottomPadding: 20

        layout: StackLayout {
            orientation: LayoutOrientation.TopToBottom
        }

        Label {
            text: calculator.expression === "" ? " " : calculator.expression
            horizontalAlignment: HorizontalAlignment.Right
        }

        Label {
            text: calculator.display
            textStyle.base: SystemDefaults.TextStyles.BigText
            horizontalAlignment: HorizontalAlignment.Right
        }

        Container {
            layout: StackLayout {
                orientation: LayoutOrientation.LeftToRight
            }
            Button {
                text: "C"
                onClicked: send("clear", "")
            }
            Button {
                text: "DEL"
                onClicked: send("delete", "")
            }
            Button {
                text: "+/−"
                onClicked: send("sign", "")
            }
            Button {
                text: "÷"
                onClicked: send("operator", "÷")
            }
        }
        Container {
            layout: StackLayout {
                orientation: LayoutOrientation.LeftToRight
            }
            Button {
                text: "7"
                onClicked: send("digit", "7")
            }
            Button {
                text: "8"
                onClicked: send("digit", "8")
            }
            Button {
                text: "9"
                onClicked: send("digit", "9")
            }
            Button {
                text: "×"
                onClicked: send("operator", "×")
            }
        }
        Container {
            layout: StackLayout {
                orientation: LayoutOrientation.LeftToRight
            }
            Button {
                text: "4"
                onClicked: send("digit", "4")
            }
            Button {
                text: "5"
                onClicked: send("digit", "5")
            }
            Button {
                text: "6"
                onClicked: send("digit", "6")
            }
            Button {
                text: "−"
                onClicked: send("operator", "−")
            }
        }
        Container {
            layout: StackLayout {
                orientation: LayoutOrientation.LeftToRight
            }
            Button {
                text: "1"
                onClicked: send("digit", "1")
            }
            Button {
                text: "2"
                onClicked: send("digit", "2")
            }
            Button {
                text: "3"
                onClicked: send("digit", "3")
            }
            Button {
                text: "+"
                onClicked: send("operator", "+")
            }
        }
        Container {
            layout: StackLayout {
                orientation: LayoutOrientation.LeftToRight
            }
            Button {
                text: "0"
                onClicked: send("digit", "0")
            }
            Button {
                text: "."
                onClicked: send("decimal", "")
            }
            Button {
                text: "="
                onClicked: send("equals", "")
            }
        }
    }
}
