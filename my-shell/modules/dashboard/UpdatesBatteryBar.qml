import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    required property int segmentPercent
    required property color segmentColor
    required property string barTitle
    required property string bigValue
    required property string smallLabel
    required property color titleColor
    required property color mutedTextColor
    required property color panelBorder
    required property real borderW
    required property int barRounding
    required property int valuePixelSize
    property bool useSegmentSteps: true
    property real fillOpacity: 0.30

    Layout.preferredWidth: 200
    Layout.preferredHeight: 200
    Layout.fillHeight: false
    color: "transparent"
    border.color: panelBorder
    border.width: borderW
    radius: barRounding

    Rectangle {
        id: segLayer
        anchors.fill: parent
        color: "transparent"
        radius: root.barRounding
        clip: true
        z: 0
        readonly property real segGap: 2
        readonly property real segH: height > 0 ? Math.max(0, (height - 9 * segGap) / 10) : 0

        Repeater {
            model: 10
            delegate: Rectangle {
                required property int index
                width: segLayer.width
                height: segLayer.segH
                x: 0
                y: segLayer.height - (index + 1) * segLayer.segH - index * segLayer.segGap
                radius: Math.min(segLayer.segH / 2, root.barRounding)
                color: root.useSegmentSteps && root.segmentPercent > index * 10
                    ? Qt.rgba(root.segmentColor.r, root.segmentColor.g, root.segmentColor.b, 0.30)
                    : "transparent"
            }
        }

        Rectangle {
            visible: !root.useSegmentSteps
            x: 0
            width: segLayer.width
            height: Math.max(0, segLayer.height * Math.max(0, Math.min(1, root.segmentPercent / 100)))
            y: segLayer.height - height
            radius: root.barRounding
            color: Qt.rgba(root.segmentColor.r, root.segmentColor.g, root.segmentColor.b, Math.max(0, Math.min(1, root.fillOpacity)))
        }
    }

    ColumnLayout {
        z: 1
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        Label { text: root.barTitle; color: root.titleColor; font.bold: true }
        Item { Layout.fillHeight: true; Layout.minimumHeight: 24 }
        Label {
            property bool qsKeepPixelSize: true
            text: root.bigValue
            color: root.titleColor
            font.pixelSize: root.valuePixelSize
            font.bold: true
        }
        Label { text: root.smallLabel; color: root.mutedTextColor; font.pixelSize: 12 }
    }
}
