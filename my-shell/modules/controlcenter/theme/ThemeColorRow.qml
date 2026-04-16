import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

    required property QtObject config
    required property string labelText
    required property string colorValue
    required property var options
    signal colorChanged(string value)

    spacing: 4

    Label {
        text: root.labelText
        color: root.config.textColor
        font.pixelSize: Math.max(11, root.config.fontPixelSize - 1)
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            implicitWidth: 22
            implicitHeight: 22
            radius: Math.max(0, root.config.rounding - 4)
            color: root.colorValue
            border.width: root.config.buttonBorderWidth
            border.color: root.config.mutedTextColor
        }

        TextField {
            Layout.fillWidth: true
            text: root.colorValue
            placeholderText: "#ff8c32"
            onEditingFinished: root.colorChanged(String(text).trim() || root.colorValue)
        }
    }

    GridLayout {
        columns: 5
        rowSpacing: 4
        columnSpacing: 4

        Repeater {
            model: root.options
            delegate: Rectangle {
                required property var modelData
                implicitWidth: 18
                implicitHeight: 18
                radius: 3
                color: modelData
                border.width: root.config.buttonBorderWidth
                border.color: String(root.colorValue).toLowerCase() === String(modelData).toLowerCase()
                    ? root.config.textColor
                    : root.config.mutedTextColor

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.colorChanged(String(parent.color))
                }
            }
        }
    }
}
