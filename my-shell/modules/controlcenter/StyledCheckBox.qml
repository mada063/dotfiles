import QtQuick
import QtQuick.Controls

CheckBox {
    id: root

    required property QtObject control

    contentItem: Text {
        text: root.text
        color: root.control.config.textColor
        verticalAlignment: Text.AlignVCenter
        leftPadding: root.indicator.width + root.spacing
    }
}
