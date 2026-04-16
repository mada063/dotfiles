import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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

    Rectangle {
        implicitWidth: root.toggleWidth
        implicitHeight: root.toggleHeight
        radius: root.host._toggleRadius(height)
        color: root.checked ? Qt.rgba(root.host.config.overlayAccentColor.r, root.host.config.overlayAccentColor.g, root.host.config.overlayAccentColor.b, 0.28) : "transparent"
        border.width: root.host.config.buttonBorderWidth
        border.color: root.checked ? root.host.config.overlayAccentColor : root.host.config.mutedTextColor

        Rectangle {
            width: root.knobSize
            height: root.knobSize
            radius: root.host._toggleKnobRadius(height)
            y: Math.max(0, Math.round((parent.height - height) / 2))
            x: root.checked ? parent.width - width - 3 : 3
            color: root.checked ? root.host.config.overlayAccentColor : root.host.config.textColor
            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.toggled()
        }
    }
}
