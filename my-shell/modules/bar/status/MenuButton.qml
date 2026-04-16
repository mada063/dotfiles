import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    required property QtObject host
    property string labelText: ""
    property bool buttonEnabled: true
    property real buttonImplicitWidth: 70
    property real buttonImplicitHeight: 24
    signal clicked()

    implicitWidth: buttonImplicitWidth
    implicitHeight: buttonImplicitHeight
    color: "transparent"
    border.width: host.config.buttonBorderWidth
    border.color: host.config.mutedTextColor
    radius: Math.max(0, host.config.rounding - 3)
    opacity: root.buttonEnabled ? 1 : 0.55

    Label {
        anchors.centerIn: parent
        text: root.labelText
        color: root.host.config.textColor
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.buttonEnabled
        onClicked: root.clicked()
    }
}
