import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Column {
    id: root

    required property QtObject host
    property int listHeight: 260

    readonly property bool _hug: host.statusMenuHugWidth === true

    spacing: 6
    width: _hug ? host.sideMenuHugContentWidth : host.statusMenuContentWidth

    Label { text: host.wifiDetailText; color: host.config.mutedTextColor; width: parent.width; wrapMode: Text.WordWrap }

    MenuToggle {
        width: parent.width
        host: root.host
        labelText: "Enabled"
        checked: host.networkEnabled
        onToggled: host.toggleWifiEnabled()
    }

    MenuSectionLabel {
        text: "Networks"
        host: root.host
    }

    ScrollView {
        width: parent.width
        height: root.listHeight
        clip: true

        ListView {
            model: host.wifiNetworks
            spacing: 4
            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width - 8
                height: modelData.secured && host.wifiConnectSsid === modelData.ssid && !modelData.active ? 76 : 42
                radius: Math.max(0, host.config.rounding - 3)
                color: modelData.active ? Qt.rgba(host.config.overlayAccentColor.r, host.config.overlayAccentColor.g, host.config.overlayAccentColor.b, 0.12) : "transparent"
                border.width: host.config.buttonBorderWidth
                border.color: host.config.mutedTextColor
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 6
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Label { text: modelData.ssid; color: host.config.textColor; elide: Text.ElideRight; Layout.fillWidth: true }
                            Label { text: modelData.security + "  " + modelData.signal + "%"; color: host.config.mutedTextColor; elide: Text.ElideRight; Layout.fillWidth: true; font.pixelSize: Math.max(10, host.uiFontSize - 1) }
                        }
                        MenuButton {
                            host: root.host
                            buttonImplicitWidth: modelData.active ? 84 : 70
                            buttonImplicitHeight: 24
                            labelText: modelData.active ? "Disconnect"
                                : modelData.secured && host.wifiConnectSsid === modelData.ssid ? "Cancel"
                                : "Connect"
                            onClicked: host.clickWifiNetwork(modelData)
                        }
                    }
                    RowLayout {
                        visible: modelData.secured && host.wifiConnectSsid === modelData.ssid && !modelData.active
                        Layout.fillWidth: true
                        spacing: 6
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 30
                            radius: Math.max(0, host.config.rounding - 3)
                            color: "transparent"
                            border.width: host.config.buttonBorderWidth
                            border.color: host.config.mutedTextColor

                            TextInput {
                                anchors.fill: parent
                                anchors.margins: 6
                                text: host.wifiConnectSsid === modelData.ssid ? host.wifiConnectPassword : ""
                                color: host.config.textColor
                                echoMode: TextInput.Password
                                selectByMouse: true
                                clip: true
                                verticalAlignment: TextInput.AlignVCenter
                                onTextChanged: {
                                    if (host.wifiConnectSsid === modelData.ssid)
                                        host.wifiConnectPassword = text;
                                }
                                onActiveFocusChanged: {
                                    host.statusMenuInputFocused = activeFocus;
                                    if (activeFocus)
                                        host.activeStatusMenu = "wifi";
                                }
                            }
                        }
                        MenuButton {
                            host: root.host
                            buttonImplicitWidth: 70
                            buttonImplicitHeight: 28
                            labelText: "Connect"
                            buttonEnabled: host.wifiConnectSsid === modelData.ssid && host.wifiConnectPassword.length > 0
                            onClicked: host.submitWifiPassword(modelData)
                        }
                    }
                }
            }
        }
    }

    MenuButton {
        width: parent.width
        host: root.host
        buttonImplicitHeight: 24
        labelText: "Rescan"
        onClicked: host.rescanWifi()
    }
}
