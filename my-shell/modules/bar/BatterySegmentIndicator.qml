import QtQuick

// Four 25% segments with quarter-step fill. Vertical (default): stacked horizontal bars, top = 75–100%.
// Horizontal: row of vertical bars, left = 0–25% … right = 75–100%.
Item {
    id: root

    property real percent: 0
    property color textColor: "#ffffff"
    property bool horizontal: false
    property int barRadius: 0

    // Vertical stack: each segment is a wide short bar
    property int segmentWidth: 16
    property int segmentHeight: 5
    property int segmentSpacing: 3

    readonly property int _r: Math.max(0, Math.min(barRadius, Math.floor(Math.min(segmentWidth, segmentHeight) / 2)))

    implicitWidth: horizontal ? hRow.implicitWidth : vCol.implicitWidth
    implicitHeight: horizontal ? hRow.implicitHeight : vCol.implicitHeight

    function segmentFill(pct, segmentIndex) {
        const p = Math.max(0, Math.min(100, Number(pct)));
        const start = (3 - Number(segmentIndex)) * 25;
        const relative = Math.max(0, Math.min(1, (p - start) / 25));
        if (relative <= 0)
            return 0;
        return Math.max(0.25, Math.min(1, Math.ceil(relative * 4) / 4));
    }

    Column {
        id: vCol
        visible: !root.horizontal
        spacing: root.segmentSpacing

        Repeater {
            model: 4
            delegate: Rectangle {
                required property int index
                readonly property int barW: root.segmentWidth
                readonly property int barH: root.segmentHeight
                readonly property real fillRatio: root.segmentFill(root.percent, index)
                width: barW
                height: barH
                radius: root._r
                color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.5)

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.round(parent.barW * parent.fillRatio)
                    height: parent.height
                    radius: root._r
                    color: root.textColor
                }
            }
        }
    }

    Row {
        id: hRow
        visible: root.horizontal
        spacing: root.segmentSpacing

        Repeater {
            model: 4
            delegate: Rectangle {
                required property int index
                readonly property int logicalSeg: 3 - index
                readonly property int barW: root.segmentWidth
                readonly property int barH: root.segmentHeight
                readonly property real fillRatio: root.segmentFill(root.percent, logicalSeg)
                width: barW
                height: barH
                radius: root._r
                color: Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b, 0.5)

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    height: Math.round(parent.barH * parent.fillRatio)
                    radius: root._r
                    color: root.textColor
                }
            }
        }
    }
}
