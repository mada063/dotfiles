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
    color: buttonMouse.containsPress
        ? root.host.config.buttonActiveBackgroundColor
        : (buttonMouse.containsMouse
            ? Qt.rgba(root.host.config.overlayAccentColor.r, root.host.config.overlayAccentColor.g, root.host.config.overlayAccentColor.b, 0.10)
            : root.host.config.buttonBackgroundColor)
    border.width: host.config.buttonBorderWidth
    border.color: buttonMouse.containsPress
        ? host.config.buttonActiveBorderColor
        : (buttonMouse.containsMouse ? host.config.overlayAccentColor : host.config.buttonBorderColor)
    radius: Math.max(0, host.config.rounding - 3)
    opacity: root.buttonEnabled ? 1 : 0.55

    Label {
        anchors.centerIn: parent
        text: root.labelText
        color: buttonMouse.containsPress
            ? root.host.config.buttonActiveTextColor
            : (buttonMouse.containsMouse ? root.host.config.overlayAccentColor : root.host.config.buttonTextColor)
    }

    MouseArea {
        id: buttonMouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.buttonEnabled
        onClicked: root.clicked()
    }
}
