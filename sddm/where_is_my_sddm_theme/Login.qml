import QtQuick 2.15
import QtQuick.Controls 2.0

Item {
    id: loginRoot
    // Gjør passwordInput tilgjengelig for Main.qml
    property alias passwordInput: passwordField
    
    width: passwordField.width
    height: passwordField.height + 24 // Litt ekstra plass for brukernavn over

    TextInput {
    id: passwordField
    z: 10
    width: 600
    anchors.centerIn: parent
    font.pointSize: passwordFontSize
    font.bold: true
    font.family: defaultFont
    color: textColor
    horizontalAlignment: TextInput.AlignHCenter
    verticalAlignment: TextInput.AlignVCenter
    
    echoMode: TextInput.Password
    passwordCharacter: "#"  // <--- HER bytter du til stjerne
    passwordMaskDelay: 0 // Valgfritt: viser tegnet et halvt sekund før det blir *

    // Oppdatert Caps Lock sjekk for Qt6
    property bool capsLockOn: false
    
    Keys.onPressed: (event) => {
        // Oppdaterer Caps Lock status ved hvert tastetrykk
        capsLockOn = (event.modifiers & Qt.CapsLockModifier)
        
        if (event.key === Qt.Key_Left) usersCycleSelectPrev();
        else if (event.key === Qt.Key_Right) usersCycleSelectNext();
        else if (event.key === Qt.Key_Up) sessionsCycleSelectPrev();
        else if (event.key === Qt.Key_Down) sessionsCycleSelectNext();
    }

    onAccepted: {
        sddm.login(
            userModel.data(userModel.index(currentUsersIndex,0), usernameRole),
            text,
            currentSessionsIndex
        )
    }
}

// CAPS LOCK ADVARSEL
Rectangle {
    id: capsLockWarning
    // Bruker den nye propertyen fra passwordField
    visible: passwordField.capsLockOn 
    
    anchors.top: loginBox.bottom
    anchors.topMargin: 12
    anchors.horizontalCenter: parent.horizontalCenter
    
    color: "#ff3117"
    width: capsLockText.implicitWidth + 24
    height: capsLockText.implicitHeight + 6

    Text {
        id: capsLockText
        anchors.centerIn: parent
        text: "CAPS LOCK ACTIVE"
        font.family: defaultFont
        font.pixelSize: 12
        font.bold: true
        color: "#000000"
    }
}

    Rectangle {
        id: loginBox
        z: 5
        width: passwordField.width
        height: passwordField.height + 12
        anchors.centerIn: passwordField
        color: "transparent"
        border.color: accent
        border.width: 2
    }
}