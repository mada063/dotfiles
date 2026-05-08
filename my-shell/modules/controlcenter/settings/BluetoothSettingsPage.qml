import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: root
    required property QtObject control
    function _T(s) { return root.control.config.formatUiText(s); }
    property bool bluetoothEnabled: false
    property var pairedDevices: []
    property string adapterName: "hci0"
    property string currentDevice: "none"

    function refresh() {
        if (!stateProc.running)
            stateProc.exec({ command: stateProc.command });
        if (!pairedProc.running)
            pairedProc.exec({ command: pairedProc.command });
    }

    function setPower(enabled) {
        bluetoothEnabled = enabled;
        toggleProc.exec({ command: ["bash", "-lc", "if command -v bluetoothctl >/dev/null 2>&1; then bluetoothctl power " + (enabled ? "on" : "off") + "; fi"] });
        refreshTimer.restart();
    }

    function showPaired() {
        pairedProc.exec({ command: pairedProc.command });
    }

    Component.onCompleted: refresh()

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 16

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: controlsColumn.implicitHeight + 28
            radius: root.control.config.overlayRounding
            color: Qt.rgba(root.control.config.overlayBackgroundColor.r, root.control.config.overlayBackgroundColor.g, root.control.config.overlayBackgroundColor.b, 0.22)
            border.color: root.control.config.buttonBorderColor
            border.width: root.control.config.buttonBorderWidth

            ColumnLayout {
                id: controlsColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 10
                Label { text: root._T("Bluetooth Controls"); color: root.control.config.accentColor; font.family: root.control.uiFontFamily; font.bold: true }
                RowLayout {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    Label { text: root._T("Enabled"); Layout.fillWidth: true; color: root.control.config.textColor; font.family: root.control.uiFontFamily }
                    Switch { checked: root.bluetoothEnabled; onToggled: root.setPower(checked) }
                }
                Button { text: root._T("Disable"); onClicked: root.setPower(false) }
                Button {
                    text: root._T("Discoverable")
                    onClicked: discoverableProc.exec({ command: discoverableProc.command })
                }
                Button { text: root._T("Paired"); onClicked: root.showPaired() }
                Button { text: root._T("Scan"); onClicked: scanProc.exec({ command: scanProc.command }) }
                Button { text: root._T("Refresh"); onClicked: root.refresh() }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: deviceColumn.implicitHeight + 28
            radius: root.control.config.overlayRounding
            color: Qt.rgba(root.control.config.overlayBackgroundColor.r, root.control.config.overlayBackgroundColor.g, root.control.config.overlayBackgroundColor.b, 0.22)
            border.color: root.control.config.buttonBorderColor
            border.width: root.control.config.buttonBorderWidth

            ColumnLayout {
                id: deviceColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 10
                Label { text: root._T("Adapter / Device"); color: root.control.config.accentColor; font.family: root.control.uiFontFamily; font.bold: true }
                Label { text: root._T("Adapter:") + " " + root.adapterName; color: root.control.config.textColor; font.family: root.control.uiFontFamily }
                Label { text: root._T("Current device:") + " " + root.currentDevice; color: root.control.config.textColor; font.family: root.control.uiFontFamily }
                Label { text: root._T("Paired devices"); color: root.control.config.textColor; font.bold: true; font.family: root.control.uiFontFamily }
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: root.pairedDevices
                    delegate: Label {
                        required property string modelData
                        text: String(modelData)
                        color: root.control.config.textColor
                        font.family: root.control.uiFontFamily
                        font.pixelSize: root.control.uiFontSize
                    }
                }
            }
        }
    }

    Process {
        id: stateProc
        command: ["bash", "-lc", "if command -v bluetoothctl >/dev/null 2>&1; then adapter=$(bluetoothctl list | awk '{print $2; exit}'); powered=$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered:/ {print tolower($2); exit}'); connected=$(bluetoothctl devices Connected 2>/dev/null | sed 's/^Device [^ ]* //;q'); echo \"${adapter:-hci0}|${powered:-no}|${connected:-none}\"; else echo \"hci0|no|none\"; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const parts = String(text).trim().split("|");
                root.adapterName = parts[0] || "hci0";
                root.bluetoothEnabled = (parts[1] || "").toLowerCase() === "yes";
                root.currentDevice = parts[2] || "none";
            }
        }
    }

    Process {
        id: pairedProc
        command: ["bash", "-lc", "if command -v bluetoothctl >/dev/null 2>&1; then bluetoothctl paired-devices 2>/dev/null | sed 's/^Device [^ ]* //'; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const lines = String(text).trim().split('\n').filter(line => line.length > 0);
                root.pairedDevices = lines.length > 0 ? lines : [root._T("No paired devices")];
            }
        }
    }

    Process { id: toggleProc }
    Process { id: discoverableProc; command: ["bash", "-lc", "if command -v bluetoothctl >/dev/null 2>&1; then bluetoothctl discoverable on; fi"] }
    Process { id: scanProc; command: ["bash", "-lc", "if command -v bluetoothctl >/dev/null 2>&1; then bluetoothctl --timeout 4 scan on; fi"] }

    Timer {
        id: refreshTimer
        interval: 350
        repeat: false
        onTriggered: root.refresh()
    }
}
