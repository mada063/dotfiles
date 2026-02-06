import QtQuick 2.15

Item {
    id: userRoot
    implicitWidth: mainLayout.width
    implicitHeight: mainLayout.height
    
    property string text: ""
    signal prevClicked()
    signal nextClicked()

    Row {
        id: mainLayout
        spacing: 30
        
        // VENSTRE PIL
        Text {
            text: "<"
            anchors.verticalCenter: parent.verticalCenter // SENTRERER VERTIKALT
            font.pointSize: usersFontSize * 0.5
            font.family: defaultFont
            color: accent
            MouseArea { anchors.fill: parent; onClicked: userRoot.prevClicked() }
        }

        // BRUKERBOKS
        Rectangle {
            width: usernameDisplay.implicitWidth + 40
            height: usernameDisplay.implicitHeight
            color: accentOpacity
            anchors.verticalCenter: parent.verticalCenter // SENTRERER VERTIKALT

            Text {
                id: usernameDisplay
                text: userRoot.text
                anchors.centerIn: parent
                font.pointSize: usersFontSize
                font.family: defaultFont
                color: textColor
            }
        }

        // HØYRE PIL
        Text {
            text: ">"
            anchors.verticalCenter: parent.verticalCenter // SENTRERER VERTIKALT
            font.pointSize: usersFontSize * 0.5
            font.family: defaultFont
            color: accent
            MouseArea { anchors.fill: parent; onClicked: userRoot.nextClicked() }
        }
    }
}