import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

PanelWindow {
    id: root

    required property QtObject shell
    required property QtObject config

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusiveZone: 0

    readonly property string uiFontFamily: root.config.fontFamily
    readonly property int uiFontSize: root.config.fontPixelSize
    property bool wifiEnabled: false
    property bool bluetoothEnabled: false
    property bool notificationsSilenced: false

    function _applyFontRecursive(node) {
        if (!node)
            return;
        try {
            if (node.font !== undefined) {
                node.font.family = root.uiFontFamily;
                node.font.pixelSize = root.uiFontSize;
            }
        } catch (e) {}
        const kids = node.children || [];
        for (let i = 0; i < kids.length; i++)
            _applyFontRecursive(kids[i]);
        if (node.contentItem)
            _applyFontRecursive(node.contentItem);
    }

    function refreshStates() {
        wifiStateProc.exec({ command: wifiStateProc.command });
        bluetoothStateProc.exec({ command: bluetoothStateProc.command });
        notificationsStateProc.exec({ command: notificationsStateProc.command });
    }

    function toggleWifi() {
        const next = !root.wifiEnabled;
        root.wifiEnabled = next;
        wifiToggleProc.exec({ command: ["bash", "-lc", "if command -v nmcli >/dev/null 2>&1; then nmcli radio wifi " + (next ? "on" : "off") + "; fi"] });
        refreshTimer.restart();
    }

    function toggleBluetooth() {
        const next = !root.bluetoothEnabled;
        root.bluetoothEnabled = next;
        bluetoothToggleProc.exec({ command: ["bash", "-lc", "if command -v bluetoothctl >/dev/null 2>&1; then bluetoothctl power " + (next ? "on" : "off") + "; fi"] });
        refreshTimer.restart();
    }

    function toggleNotificationsSilenced() {
        const next = !root.notificationsSilenced;
        root.notificationsSilenced = next;
        notificationsToggleProc.exec({ command: ["bash", "-lc", "if command -v dunstctl >/dev/null 2>&1; then dunstctl set-paused " + (next ? "true" : "false") + "; elif command -v makoctl >/dev/null 2>&1; then if " + (next ? "true" : "false") + "; then makoctl mode -a do-not-disturb 2>/dev/null || makoctl set-mode do-not-disturb 2>/dev/null; else makoctl mode -r do-not-disturb 2>/dev/null || makoctl set-mode default 2>/dev/null; fi; elif command -v swaync-client >/dev/null 2>&1; then swaync-client -d; fi"] });
        refreshTimer.restart();
    }

    onUiFontFamilyChanged: _applyFontRecursive(root)
    onUiFontSizeChanged: _applyFontRecursive(root)
    Component.onCompleted: {
        _applyFontRecursive(root);
        refreshStates();
    }

    Rectangle {
        anchors.fill: parent
        visible: root.shell.quickSettingsVisible
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            enabled: root.shell.quickSettingsVisible
            onClicked: root.shell.quickSettingsVisible = false
        }
    }

    Rectangle {
        id: quickMenu
        width: 292
        height: 158
        anchors.right: triggerButton.right
        anchors.bottom: triggerButton.top
        anchors.bottomMargin: 8
        visible: root.shell.quickSettingsVisible || opacity > 0.01
        color: root.config.overlayBackgroundColor
        border.color: root.config.overlayAccentColor
        border.width: root.config.overlayBorderWidth
        radius: root.config.overlayRounding
        opacity: root.shell.quickSettingsVisible ? 1 : 0
        y: root.shell.quickSettingsVisible ? 0 : 8

        Behavior on opacity {
            NumberAnimation { duration: 110 }
        }
        Behavior on y {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Label {
                text: "Disable lock"
                color: root.config.overlayTextColor
                font.family: root.uiFontFamily
                font.pixelSize: root.uiFontSize + 2
                font.bold: true
            }

            Label {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: "Keep locking disabled here and use the window manager if you need stricter session control."
                color: root.config.mutedTextColor
                font.family: root.uiFontFamily
                font.pixelSize: root.uiFontSize - 1
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(root.config.overlayAccentColor.r, root.config.overlayAccentColor.g, root.config.overlayAccentColor.b, 0.25)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Repeater {
                    model: [
                        {
                            icon: root.wifiEnabled ? "📶" : "⨯",
                            active: root.wifiEnabled,
                            action: () => root.toggleWifi()
                        },
                        {
                            icon: root.bluetoothEnabled ? "ᛒ" : "×",
                            active: root.bluetoothEnabled,
                            action: () => root.toggleBluetooth()
                        },
                        {
                            icon: root.notificationsSilenced ? "🔕" : "🔔",
                            active: root.notificationsSilenced,
                            action: () => root.toggleNotificationsSilenced()
                        },
                        {
                            icon: "◐",
                            active: false,
                            action: () => root.shell.openThemeSelector()
                        },
                        {
                            icon: "⚙",
                            active: false,
                            action: () => root.shell.openControlCenter()
                        }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        color: modelData.active
                            ? Qt.rgba(root.config.overlayAccentColor.r, root.config.overlayAccentColor.g, root.config.overlayAccentColor.b, 0.22)
                            : Qt.rgba(root.config.overlayTextColor.r, root.config.overlayTextColor.g, root.config.overlayTextColor.b, 0.06)
                        border.color: modelData.active ? root.config.overlayAccentColor : root.config.mutedTextColor
                        border.width: root.config.buttonBorderWidth
                        radius: Math.max(0, root.config.overlayRounding - 2)

                        Label {
                            anchors.centerIn: parent
                            text: modelData.icon
                            color: modelData.active ? root.config.overlayAccentColor : root.config.overlayTextColor
                            font.family: root.uiFontFamily
                            font.pixelSize: root.uiFontSize + 7
                            font.bold: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: modelData.action()
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: triggerButton
        width: 42
        height: 42
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 14
        anchors.bottomMargin: 14
        color: root.shell.quickSettingsVisible
            ? Qt.rgba(root.config.overlayAccentColor.r, root.config.overlayAccentColor.g, root.config.overlayAccentColor.b, 0.22)
            : root.config.sidebarBackgroundColor
        border.color: root.shell.quickSettingsVisible ? root.config.overlayAccentColor : root.config.quickSidebarColor
        border.width: root.config.overlayBorderWidth
        radius: root.config.sidebarRounding
        opacity: root.config.panelOpacity

        Label {
            anchors.centerIn: parent
            text: "⚙"
            color: root.shell.quickSettingsVisible ? root.config.overlayAccentColor : root.config.sidebarTextColor
            font.family: root.uiFontFamily
            font.pixelSize: root.uiFontSize + 6
            font.bold: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.shell.quickSettingsVisible = !root.shell.quickSettingsVisible
        }
    }

    Process {
        id: wifiStateProc
        command: ["bash", "-lc", "if command -v nmcli >/dev/null 2>&1; then state=$(nmcli radio wifi | head -n1 | tr '[:upper:]' '[:lower:]'); [ \"$state\" = enabled ] && echo on || echo off; else echo off; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.wifiEnabled = String(text).trim() === "on"
        }
    }

    Process {
        id: bluetoothStateProc
        command: ["bash", "-lc", "if command -v bluetoothctl >/dev/null 2>&1; then state=$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered:/ {print tolower($2); exit}'); [ \"$state\" = yes ] && echo on || echo off; else echo off; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.bluetoothEnabled = String(text).trim() === "on"
        }
    }

    Process {
        id: notificationsStateProc
        command: ["bash", "-lc", "if command -v dunstctl >/dev/null 2>&1; then state=$(dunstctl is-paused 2>/dev/null | tr '[:upper:]' '[:lower:]'); [ \"$state\" = true ] && echo on || echo off; elif command -v makoctl >/dev/null 2>&1; then state=$(makoctl mode 2>/dev/null | tr '[:upper:]' '[:lower:]'); [ \"$state\" = do-not-disturb ] && echo on || echo off; elif command -v swaync-client >/dev/null 2>&1; then state=$(swaync-client -D 2>/dev/null | tr '[:upper:]' '[:lower:]'); [ \"$state\" = true ] && echo on || echo off; else echo off; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.notificationsSilenced = String(text).trim() === "on"
        }
    }

    Process { id: wifiToggleProc }
    Process { id: bluetoothToggleProc }
    Process { id: notificationsToggleProc }

    Timer {
        id: refreshTimer
        interval: 220
        repeat: false
        onTriggered: root.refreshStates()
    }

    Timer {
        interval: Math.max(1200, root.config.quickSidebarPollMs)
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshStates()
    }
}
