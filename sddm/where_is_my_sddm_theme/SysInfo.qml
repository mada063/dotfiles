// RIGHT TOP DIVIDER

import QtQuick 2.15

Item {
    id: sysInfoRoot
    width: 280
    height: 150
Item {
        id: topDivider
        width: 260; height: 6
        anchors.left: parent.left; anchors.top: parent.top
        anchors.leftMargin: 8; anchors.topMargin: 0

        // Venstre stolpe - nå ankret til toppen
        Rectangle { width: 2; height: 4; color: accent; anchors.left: parent.left; anchors.top: parent.top }

        // Høyre stolpe - nå ankret til toppen
        Rectangle { width: 2; height: 4; color: accent; anchors.right: parent.right; anchors.top: parent.top }

        // Prikkene i midten - nå ankret til toppen
        Repeater {
            model: Math.floor((parent.width - 4) / 6)
            Rectangle { 
                width: 2; height: 2; color: accentOpacity; 
                x: 2 + index * 6; anchors.top: parent.top 
            }
        }
    }

// HEADER
Text {
    id: sysHeader
    anchors.right: parent.right
    anchors.top: topDivider.bottom // Endret fra rightDividerTop til topDivider
    anchors.rightMargin: 20
    anchors.topMargin: 6

    text: "SDDM AUTH INTERFACE"
    font.family: defaultFont
    font.pixelSize: 12
    color: accent
}

// CLOCK BADGE
Rectangle {
    id: clockBadge
    radius: 0
    color: panel

    anchors.right: parent.right
    anchors.top: sysHeader.bottom
    anchors.rightMargin: 20
    anchors.topMargin: 4

    property int pad: 24
    width: clockText.width + pad
    height: clockText.height

    Text {
        id: clockText
        anchors.centerIn: parent
        font.family: defaultFont
        font.pixelSize: 12
        color: accent
    }
}

// STATUS ROW
Row {
    id: statusRow
    spacing: 6

    anchors.right: parent.right
    anchors.top: clockBadge.bottom
    anchors.rightMargin: 20
    anchors.topMargin: 4

    Text {
        text: "STATUS"
        font.family: defaultFont
        font.pixelSize: 12
        color: accent
    }

    Rectangle {
        radius: 0
        color: panel

        property int pad: 24
        width: readyText.width + pad
        height: readyText.height

        Text {
            id: readyText
            anchors.centerIn: parent
            text: "READY"
            font.family: defaultFont
            font.pixelSize: 12
            color: power
        }
    }
}

// RIGHT BOTTOM DIVIDER
Item {
    width: topDivider.width
    height: topDivider.height
    anchors.right: parent.right
    anchors.top: statusRow.bottom
    anchors.rightMargin: 8
    anchors.topMargin: 6

    Rectangle {
        width: 2
        height: 4
        color: accent
        anchors.left: parent.left
        anchors.bottom: parent.bottom
    }

    Rectangle {
        width: 2
        height: 4
        color: accent
        anchors.right: parent.right
        anchors.bottom: parent.bottom
    }

    Repeater {
        model: Math.floor((parent.width - 4) / 6)
        Rectangle {
            width: 2
            height: 2
            color: accentOpacity
            x: 2 + index * 6
            anchors.bottom: parent.bottom
        }
    }
}

// TIMER
Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: clockText.text = Qt.formatTime(new Date(), "hh:mm:ss")
}

}