import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root
    width: 280
    height: 60

    property var sddm

    property bool sessionMenuOpen: false
    property bool powerMenuOpen: false

    function closeMenus() {
        sessionMenuOpen = false
        powerMenuOpen = false
    }

    // CLICK OUTSIDE
    MouseArea {
        anchors.fill: parent
        z: 50
        visible: sessionMenuOpen || powerMenuOpen
        onClicked: closeMenus()
    }

    // ───── TOP DIVIDER ─────
    Item {
        width: 260; height: 6
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 8

        Rectangle { width: 2; height: 4; color: accent; anchors.left: parent.left }
        Rectangle { width: 2; height: 4; color: accent; anchors.right: parent.right }

        Repeater {
            model: Math.floor((parent.width - 4) / 6)
            Rectangle {
                width: 2; height: 2
                color: accentOpacity
                x: 2 + index * 6
            }
        }
    }

    Row {
        id: row
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 20
        anchors.topMargin: 10
        spacing: 12

        // SESSION BUTTON
        Rectangle {
            id: sessionBtn
            width: sessionText.implicitWidth + 24
            height: 20
            color: panel
            border.width: sessionMenuOpen ? 1 : 0
            border.color: accent

            Text {
                id: sessionText
                anchors.centerIn: parent
                text: "SESSION"
                font.family: defaultFont
                font.pixelSize: 12
                color: sessionArea.containsMouse || sessionMenuOpen ? power : accent
            }

            MouseArea {
                id: sessionArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    powerMenuOpen = false
                    sessionMenuOpen = !sessionMenuOpen
                }
            }
        }

        // POWER BUTTON
        Rectangle {
            id: powerBtn
            width: powerText.implicitWidth + 24
            height: 20
            color: panel
            border.width: powerMenuOpen ? 1 : 0
            border.color: accent

            Text {
                id: powerText
                anchors.centerIn: parent
                text: "POWER"
                font.family: defaultFont
                font.pixelSize: 12
                color: powerArea.containsMouse || powerMenuOpen ? power : accent
            }

            MouseArea {
                id: powerArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    sessionMenuOpen = false
                    powerMenuOpen = !powerMenuOpen
                }
            }
        }
    }

    // ───── SESSION POPUP ─────
    Rectangle {
        anchors.left: sessionBtn.left
        width: 160
        clip: true
        z: 100

        property real baseY: row.y + sessionBtn.y - height - 10

        opacity: sessionMenuOpen ? 1 : 0
        enabled: sessionMenuOpen
        y: sessionMenuOpen ? baseY : baseY + 10

        Behavior on opacity { NumberAnimation { duration: 140 } }
        Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        height: Math.max(40, list.contentHeight + 10)
        color: panel
        border.color: accent

        ListView {
            id: list
            anchors.fill: parent
            anchors.margins: 5
            model: sessionModel

            delegate: ItemDelegate {
                width: parent.width
                height: 25
                background: Rectangle { color: hovered ? accentOpacity : "transparent" }

                contentItem: Text {
                    text: name
                    anchors.fill: parent
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: defaultFont
                    font.pixelSize: 11
                    color: hovered ? power : accent
                }

                onClicked: {
                    currentSessionsIndex = index
                    sessionMenuOpen = false
                }
            }
        }
    }

    // ───── POWER POPUP ─────
    Rectangle {
        anchors.left: powerBtn.left
        width: 120
        height: 55
        clip: true
        z: 100

        property real baseY: row.y + powerBtn.y - height - 10

        opacity: powerMenuOpen ? 1 : 0
        enabled: powerMenuOpen
        y: powerMenuOpen ? baseY : baseY + 10

        Behavior on opacity { NumberAnimation { duration: 140 } }
        Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        color: panel
        border.color: accent

        Column {
            anchors.fill: parent
            anchors.margins: 5
            spacing: 2

            Rectangle {
                width: parent.width
                height: 20
                color: reboot.containsMouse ? accentOpacity : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "REBOOT"
                    font.family: defaultFont
                    font.pixelSize: 11
                    color: reboot.containsMouse ? power : accent
                }

                MouseArea {
                    id: reboot
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: sddm.reboot()
                }
            }

            Rectangle {
                width: parent.width
                height: 20
                color: shutdown.containsMouse ? accentOpacity : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "SHUTDOWN"
                    font.family: defaultFont
                    font.pixelSize: 11
                    color: shutdown.containsMouse ? power : accent
                }

                MouseArea {
                    id: shutdown
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: sddm.powerOff()
                }
            }
        }
    }

    // ───── BOTTOM DIVIDER ─────
    Item {
        width: 260; height: 6
        anchors.left: parent.left
        anchors.top: row.bottom
        anchors.leftMargin: 8
        anchors.topMargin: 6

        Rectangle { width: 2; height: 4; color: accent; anchors.left: parent.left; anchors.bottom: parent.bottom }
        Rectangle { width: 2; height: 4; color: accent; anchors.right: parent.right; anchors.bottom: parent.bottom }

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
