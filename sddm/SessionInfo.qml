import QtQuick 2.15

Item {
    id: sysInfoRoot
    width: 280
    height: 150
// TOP DIVIDER
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

// USER
Row {
    id: sysUserInfo
    anchors.left: parent.left
    anchors.top: topDivider.bottom
    anchors.leftMargin: 20
    anchors.topMargin: 6
    spacing: 6

    Text {
        text: "USER"
        font.family: defaultFont
        font.pixelSize: 12
        color: accent
    }

    Rectangle {
        radius: 0
        color: panel

        property int pad: 24
        width: userInfo.width + pad
        height: userInfo.height

        Text {
            id: userInfo
            anchors.centerIn: parent
            font.family: defaultFont
            font.pixelSize: 12
            color: accent

            text:
                currentUsername
        }
    }
}

// USER
Row {
    id: sysSessionInfo
    anchors.left: parent.left
    anchors.top: sysUserInfo.bottom
    anchors.leftMargin: 20
    anchors.topMargin: 4
    spacing: 6

    Text {
        text: "SESSION"
        font.family: defaultFont
        font.pixelSize: 12
        color: accent
    }

    Rectangle {
        radius: 0
        color: panel

        property int pad: 24
        width: currentSessionInfo.width + pad
        height: currentSessionInfo.height

        Text {
            id: currentSessionInfo
            anchors.centerIn: parent
            font.family: defaultFont
            font.pixelSize: 12
            color: accent

            text:
                currentSession
        }
    }
}

// BOTTOM DIVIDER
Item {
    width: topDivider.width
    height: topDivider.height
    anchors.left: topDivider.left
    anchors.top: sysSessionInfo.bottom
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
}