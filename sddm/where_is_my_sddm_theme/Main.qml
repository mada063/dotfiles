import QtQuick 2.15
import QtQuick.Controls 2.0
import SddmComponents 2.0

Rectangle {
    id: root
    color: "#0f0f12"
    
    // --- Properties ---
    property color accent: "#BE5103"
    property color power: "#ff8c32"
    property color accentOpacity: Qt.rgba(190/255,81/255,3/255,0.3)
    property color panel: Qt.rgba(37/255,37/255,44/255,1)
    readonly property color textColor: config.stringValue("basicTextColor")

    property int currentUsersIndex: userModel.lastIndex
    property int currentSessionsIndex: sessionModel.lastIndex
    property int usernameRole: Qt.UserRole + 1
    property int realNameRole: Qt.UserRole + 2
    property int sessionNameRole: Qt.UserRole + 4

    property string currentUsername:
        userModel.data(userModel.index(currentUsersIndex, 0), config.boolValue("showUserRealNameByDefault") ? realNameRole : usernameRole)

    property string currentSession:
        sessionModel.data(sessionModel.index(currentSessionsIndex, 0), sessionNameRole)

    // Font instillinger
    property string passwordFontSize: config.intValue("passwordFontSize") || 96
    property string usersFontSize: config.intValue("usersFontSize") || 48
    property string sessionsFontSize: config.intValue("sessionsFontSize") || 24
    property string helpFontSize: config.intValue("helpFontSize") || 18
    property string defaultFont: config.stringValue("font") || "monospace"

    // --- Funksjoner ---
    function usersCycleSelectPrev() { currentUsersIndex = currentUsersIndex - 1 < 0 ? userModel.count - 1 : currentUsersIndex - 1 }
    function usersCycleSelectNext() { currentUsersIndex = currentUsersIndex >= userModel.count - 1 ? 0 : currentUsersIndex + 1 }
    function sessionsCycleSelectPrev() { currentSessionsIndex = currentSessionsIndex - 1 < 0 ? sessionModel.rowCount() - 1 : currentSessionsIndex - 1 }
    function sessionsCycleSelectNext() { currentSessionsIndex = currentSessionsIndex >= sessionModel.rowCount() - 1 ? 0 : currentSessionsIndex + 1 }

    Connections {
        target: sddm
        function onLoginFailed() {
            backgroundBorder.border.width = 5
            animateBorder.restart()
            // Sjekker at aliaset fra Login.qml eksisterer før vi tømmer
            if (loginComponent.passwordInput) loginComponent.passwordInput.clear()
        }
        function onLoginSucceeded() {
            backgroundBorder.border.width = 0
            animateBorder.stop()
        }
    }

   Item {
        id: mainFrame
        anchors.fill: parent

        Image {
            anchors.fill: parent
            source: config.stringValue("background")
            fillMode: Image.PreserveAspectCrop
        }

        // Feil-indikator
        Rectangle {
            id: backgroundBorder
            anchors.fill: parent
            color: "transparent"
            border.color: "#ff3117"
            border.width: 0
            z: 101 // Sørg for at denne ikke blokkerer musen hvis den ikke skal
            enabled: false // Gjør at den ikke stjeler klikk
        }

        // 1. TOPP VENSTRE
        SessionInfo {
            id: sessionInfoComponent
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 0
        }

        // 2. TOPP HØYRE
        SysInfo {
            id: sysInfoComponent
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 0
        }

        // 3. MIDTEN (Brukernavn og Login)
        Column {
            anchors.centerIn: parent
            spacing: 12
            width: userSelector.implicitWidth

            UsersChoose {
                id: userSelector
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.currentUsername
                onPrevClicked: root.usersCycleSelectPrev()
                onNextClicked: root.usersCycleSelectNext()
            }

            Login {
                id: loginComponent
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    Loader {
        active: config.boolValue("hideCursor") || false
        anchors.fill: parent
        sourceComponent: MouseArea { enabled: false; cursorShape: Qt.BlankCursor }
    }

    Component.onCompleted: {
        if (loginComponent.passwordInput) loginComponent.passwordInput.forceActiveFocus()
    }

    // Funksjonen som styrer tastaturet (oppdater din eksisterende i root)
    function toggleKeyboard() {
        keyboard.active = !keyboard.active
    }
}