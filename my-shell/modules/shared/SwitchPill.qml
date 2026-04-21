import QtQuick

Rectangle {
    id: root

    property bool checked: false
    property bool enabled: true
    property int switchWidth: 32
    property int switchHeight: 18
    property int knobSize: 12
    property int rounding: 8
    property color onColor: "#7c3aed"
    property color offColor: "#00000000"
    property color onBorderColor: "#7c3aed"
    property color offBorderColor: "#6b7280"
    property color onKnobColor: "#7c3aed"
    property color offKnobColor: "#9ca3af"
    signal toggled()

    implicitWidth: root.switchWidth
    implicitHeight: root.switchHeight
    radius: Math.max(0, Math.min(height / 2, root.rounding))
    color: root.checked ? root.onColor : root.offColor
    border.width: 1
    border.color: root.checked ? root.onBorderColor : root.offBorderColor
    opacity: root.enabled ? 1 : 0.35

    Rectangle {
        width: root.knobSize
        height: root.knobSize
        radius: Math.max(0, Math.min(height / 2, root.rounding))
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 3 : 3
        color: root.checked ? root.onKnobColor : root.offKnobColor

        Behavior on x {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        onClicked: root.toggled()
    }
}
