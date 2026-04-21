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
        color: root.host.config.textColor
    }

    Item { Layout.fillWidth: true }

    Shared.SwitchPill {
        switchWidth: root.toggleWidth
        switchHeight: root.toggleHeight
        knobSize: root.knobSize
        checked: root.checked
        rounding: root.host.config.rounding
        onColor: Qt.rgba(root.host.config.overlayAccentColor.r, root.host.config.overlayAccentColor.g, root.host.config.overlayAccentColor.b, 0.28)
        offColor: "transparent"
        onBorderColor: root.host.config.overlayAccentColor
        offBorderColor: root.host.config.mutedTextColor
        onKnobColor: root.host.config.overlayAccentColor
        offKnobColor: root.host.config.textColor
        onToggled: root.toggled()
    }
}
