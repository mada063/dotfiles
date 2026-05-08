import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../shared" as Shared

RowLayout {
    id: root

    required property QtObject host
    property string labelText: ""
    property bool checked: false
    property int toggleWidth: 38
    property int toggleHeight: 20
    property int knobSize: 14
    signal toggled()

    width: parent ? parent.width : implicitWidth

    Label {
        text: root.labelText
        color: root.host.config.buttonTextColor
    }

    Item { Layout.fillWidth: true }

    Shared.SwitchPill {
        switchWidth: root.toggleWidth
        switchHeight: root.toggleHeight
        knobSize: root.knobSize
        checked: root.checked
        rounding: root.host.config.rounding
        onColor: root.host.config.buttonActiveBackgroundColor
        offColor: root.host.config.buttonBackgroundColor
        onBorderColor: root.host.config.buttonActiveBorderColor
        offBorderColor: root.host.config.buttonBorderColor
        onKnobColor: root.host.config.buttonActiveTextColor
        offKnobColor: root.host.config.buttonTextColor
        onToggled: root.toggled()
    }
}
