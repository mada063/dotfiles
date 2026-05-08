import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: root

    required property QtObject control

    function _T(s) { return root.control.config.formatUiText(s); }
    property bool wifiEnabled: false
    property string adapterName: "wlan0"
    property string currentNetwork: "Disconnected"
    property string ipv4Address: "-"
    property string signalStrength: "-"
    property var ethernetDevices: []
    property var wifiNetworks: []

    function refresh() {
        if (!wifiStateProc.running)
            wifiStateProc.exec({ command: wifiStateProc.command });
        if (!wifiListProc.running)
            wifiListProc.exec({ command: wifiListProc.command });
        if (!ethernetListProc.running)
            ethernetListProc.exec({ command: ethernetListProc.command });
        if (!wifiInfoProc.running)
            wifiInfoProc.exec({ command: wifiInfoProc.command });
    }

    function scan() {
        wifiScanProc.exec({ command: wifiScanProc.command });
        refreshTimer.restart();
    }

    function toggleWifi(enabled) {
        wifiEnabled = enabled;
        wifiToggleProc.exec({ command: ["bash", "-lc", "if command -v nmcli >/dev/null 2>&1; then nmcli radio wifi " + (enabled ? "on" : "off") + "; fi"] });
        refreshTimer.restart();
    }

    Component.onCompleted: refresh()

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 16

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredWidth: parent.width * 0.48
            implicitHeight: wifiColumn.implicitHeight + 28
            radius: root.control.config.overlayRounding
            color: Qt.rgba(root.control.config.overlayBackgroundColor.r, root.control.config.overlayBackgroundColor.g, root.control.config.overlayBackgroundColor.b, 0.22)
            border.color: root.control.config.buttonBorderColor
            border.width: root.control.config.buttonBorderWidth

            ColumnLayout {
                id: wifiColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 10

                Label { text: root._T("Wifi Controls"); color: root.control.config.accentColor; font.family: root.control.uiFontFamily; font.bold: true }
                RowLayout {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    Label { text: root._T("Enabled"); Layout.fillWidth: true; color: root.control.config.textColor; font.family: root.control.uiFontFamily }
                    Switch { checked: root.wifiEnabled; onToggled: root.toggleWifi(checked) }
                }
                Button { text: root._T("Scan"); onClicked: root.scan() }
                Button { text: root._T("Disable"); onClicked: root.toggleWifi(false) }
                Button { text: root._T("Refresh"); onClicked: root.refresh() }

                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(root.control.config.accentColor.r, root.control.config.accentColor.g, root.control.config.accentColor.b, 0.2) }

                Label { text: root._T("Ethernet"); color: root.control.config.textColor; font.family: root.control.uiFontFamily; font.pixelSize: root.control.uiFontSize }
                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    clip: true
                    model: root.ethernetDevices
                    delegate: Label {
                        required property string modelData
                        text: String(modelData)
                        color: root.control.config.textColor
                        font.family: root.control.uiFontFamily
                        font.pixelSize: root.control.uiFontSize
                    }
                }

                Label { text: root._T("Wifi Networks"); color: root.control.config.textColor; font.family: root.control.uiFontFamily; font.pixelSize: root.control.uiFontSize }
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: root.wifiNetworks
                    delegate: Rectangle {
                        required property string modelData
                        width: ListView.view.width
                        height: 30
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(root.control.config.borderColor.r, root.control.config.borderColor.g, root.control.config.borderColor.b, 0.4)
                        radius: Math.max(0, root.control.config.overlayRounding - 2)

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            text: String(modelData)
                            color: root.control.config.textColor
                            font.family: root.control.uiFontFamily
                            font.pixelSize: root.control.uiFontSize
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredWidth: parent.width * 0.52
            implicitHeight: detailColumn.implicitHeight + 28
            radius: root.control.config.overlayRounding
            color: Qt.rgba(root.control.config.overlayBackgroundColor.r, root.control.config.overlayBackgroundColor.g, root.control.config.overlayBackgroundColor.b, 0.22)
            border.color: root.control.config.buttonBorderColor
            border.width: root.control.config.buttonBorderWidth

            ColumnLayout {
                id: detailColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 10

                Label { text: root._T("Connection Details"); color: root.control.config.accentColor; font.family: root.control.uiFontFamily; font.bold: true }
                Label { text: root._T("Current network:") + " " + root.currentNetwork; color: root.control.config.textColor; font.family: root.control.uiFontFamily }
                Label { text: root._T("Adapter:") + " " + root.adapterName; color: root.control.config.textColor; font.family: root.control.uiFontFamily }
                Label { text: root._T("IPv4:") + " " + root.ipv4Address; color: root.control.config.textColor; font.family: root.control.uiFontFamily }
                Label { text: root._T("Signal:") + " " + root.signalStrength; color: root.control.config.textColor; font.family: root.control.uiFontFamily }
                Label {
                    text: root._T("Use this pane for network diagnostics and adapter metadata.")
                    color: root.control.config.mutedTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    font.family: root.control.uiFontFamily
                }
            }
        }
    }

    Process {
        id: wifiStateProc
        command: ["bash", "-lc", "if command -v nmcli >/dev/null 2>&1; then nmcli radio wifi | head -n1; else echo disabled; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.wifiEnabled = String(text).trim().toLowerCase() === "enabled"
        }
    }

    Process {
        id: wifiListProc
        command: ["bash", "-lc", "if command -v nmcli >/dev/null 2>&1; then nmcli -t -f SSID,SIGNAL dev wifi list 2>/dev/null | sed '/^$/d' | head -n 12; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const lines = String(text).trim().split('\n').filter(line => line.length > 0);
                root.wifiNetworks = lines.length > 0 ? lines : [root._T("No networks found")];
            }
        }
    }

    Process {
        id: ethernetListProc
        command: ["bash", "-lc", "if command -v nmcli >/dev/null 2>&1; then nmcli -t -f DEVICE,TYPE,STATE dev status | awk -F: '$2==\"ethernet\" {print $1 \"  \" $3}'; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const lines = String(text).trim().split('\n').filter(line => line.length > 0);
                root.ethernetDevices = lines.length > 0 ? lines : [root._T("No ethernet adapters")];
            }
        }
    }

    Process {
        id: wifiInfoProc
        command: ["bash", "-lc", "if command -v nmcli >/dev/null 2>&1; then ifname=$(nmcli -t -f DEVICE,TYPE,STATE dev status | awk -F: '$2==\"wifi\" {print $1; exit}'); ssid=$(nmcli -t -f ACTIVE,SSID dev wifi | awk -F: '$1==\"yes\"{print $2; exit}'); ip=$(nmcli -g IP4.ADDRESS dev show \"$ifname\" 2>/dev/null | head -n1 | cut -d/ -f1); sig=$(nmcli -t -f IN-USE,SIGNAL dev wifi | awk -F: '$1==\"*\"{print $2 \"%\"; exit}'); echo \"$ifname|${ssid:-Disconnected}|${ip:--}|${sig:--}\"; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const parts = String(text).trim().split("|");
                root.adapterName = parts[0] || "wlan0";
                root.currentNetwork = parts[1] || "Disconnected";
                root.ipv4Address = parts[2] || "-";
                root.signalStrength = parts[3] || "-";
            }
        }
    }

    Process { id: wifiToggleProc }
    Process { id: wifiScanProc; command: ["bash", "-lc", "if command -v nmcli >/dev/null 2>&1; then nmcli dev wifi rescan; fi"] }

    Timer {
        id: refreshTimer
        interval: 350
        repeat: false
        onTriggered: root.refresh()
    }
}
