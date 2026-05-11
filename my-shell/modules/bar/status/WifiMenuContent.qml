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
        labelText: host.config.formatUiText("Enabled")
        checked: host.networkEnabled
        onToggled: host.toggleWifiEnabled()
    }

    MenuSectionLabel {
        text: host.config.formatUiText("Networks")
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
                height: wifiDelegateInner.implicitHeight + 12
                radius: Math.max(0, host.config.rounding - 3)
                color: modelData.active
                    ? Qt.rgba(host.config.overlayAccentColor.r, host.config.overlayAccentColor.g, host.config.overlayAccentColor.b, 0.12)
                    : (_wifiRowHover.hovered ? Qt.rgba(host.config.overlayAccentColor.r, host.config.overlayAccentColor.g, host.config.overlayAccentColor.b, 0.10) : "transparent")
                border.width: host.config.buttonBorderWidth
                border.color: (modelData.active || _wifiRowHover.hovered) ? host.config.overlayAccentColor : host.config.mutedTextColor

                HoverHandler { id: _wifiRowHover }

                ColumnLayout {
                    id: wifiDelegateInner
                    x: 6
                    y: 6
                    width: parent.width - 12
                    spacing: 6
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Item {
                            Layout.fillWidth: true
                            implicitHeight: wifiLabelColumn.implicitHeight
                            Column {
                                id: wifiLabelColumn
                                width: parent.width
                                spacing: 0
                                Label {
                                    width: parent.width
                                    text: modelData.ssid
                                    color: _wifiRowHover.hovered ? host.config.overlayAccentColor : host.config.textColor
                                    elide: Text.ElideRight
                                }
                                Label {
                                    width: parent.width
                                    text: modelData.security + "  " + modelData.signal + "%"
                                    color: host.config.mutedTextColor
                                    elide: Text.ElideRight
                                    font.pixelSize: Math.max(10, host.uiFontSize - 1)
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                onClicked: host.clickWifiNetwork(modelData)
                            }
                        }
                        MenuButton {
                            host: root.host
                            buttonImplicitWidth: modelData.active ? 84 : 70
                            buttonImplicitHeight: 24
                            labelText: modelData.active ? host.config.formatUiText("Disconnect")
                                : modelData.secured && host.wifiConnectSsid === modelData.ssid ? host.config.formatUiText("Cancel")
                                : host.config.formatUiText("Connect")
                            buttonEnabled: modelData.active || !host.wifiConnecting || host.wifiConnectSsid !== modelData.ssid
                                || (modelData.secured && host.wifiConnectSsid === modelData.ssid)
                            onClicked: host.clickWifiNetwork(modelData)
                        }
                    }
                    Label {
                        visible: host.wifiConnecting && host.wifiConnectSsid === modelData.ssid && !modelData.active
                        Layout.fillWidth: true
                        text: host.config.formatUiText("Connecting…")
                        color: host.config.mutedTextColor
                        wrapMode: Text.WordWrap
                        font.pixelSize: Math.max(10, host.uiFontSize - 1)
                    }
                    Label {
                        visible: host.wifiConnectSsid === modelData.ssid && !modelData.active
                            && host.wifiConnectError.length > 0 && !host.wifiConnecting
                        Layout.fillWidth: true
                        text: host.wifiConnectError
                        color: host.config.dashboardWifiDownColor
                        wrapMode: Text.WordWrap
                        font.pixelSize: Math.max(10, host.uiFontSize - 1)
                    }
                    RowLayout {
                        id: wifiPasswordRow
                        visible: modelData.secured && host.wifiConnectSsid === modelData.ssid && !modelData.active
                        Layout.fillWidth: true
                        spacing: 6
                        onVisibleChanged: {
                            if (visible && !host.wifiConnecting)
                                Qt.callLater(function () {
                                    wifiPasswordInput.forceActiveFocus();
                                });
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 30
                            radius: Math.max(0, host.config.rounding - 3)
                            color: "transparent"
                            border.width: host.config.buttonBorderWidth
                            border.color: host.config.mutedTextColor

                            TextInput {
                                id: wifiPasswordInput
                                anchors.fill: parent
                                anchors.margins: 6
                                text: host.wifiConnectSsid === modelData.ssid ? host.wifiConnectPassword : ""
                                color: host.config.textColor
                                echoMode: TextInput.Password
                                selectByMouse: true
                                readOnly: host.wifiConnecting
                                clip: true
                                verticalAlignment: TextInput.AlignVCenter
                                onTextChanged: {
                                    if (host.wifiConnectSsid === modelData.ssid) {
                                        host.wifiConnectPassword = text;
                                        if (host.wifiConnectError.length > 0)
                                            host.wifiConnectError = "";
                                    }
                                }
                                onActiveFocusChanged: {
                                    host.statusMenuInputFocused = activeFocus;
                                    if (activeFocus)
                                        host.activeStatusMenu = "wifi";
                                }
                                Keys.onReturnPressed: function (ev) {
                                    if (!host.wifiConnecting && host.wifiConnectPassword.length > 0) {
                                        host.submitWifiPassword(modelData);
                                        ev.accepted = true;
                                    }
                                }
                                Keys.onEnterPressed: function (ev) {
                                    if (!host.wifiConnecting && host.wifiConnectPassword.length > 0) {
                                        host.submitWifiPassword(modelData);
                                        ev.accepted = true;
                                    }
                                }
                                Keys.onEscapePressed: function (ev) {
                                    host.dismissWifiPasswordEntry();
                                    ev.accepted = true;
                                }
                            }
                        }
                        MenuButton {
                            host: root.host
                            buttonImplicitWidth: 70
                            buttonImplicitHeight: 28
                            labelText: host.config.formatUiText("Connect")
                            buttonEnabled: host.wifiConnectSsid === modelData.ssid && host.wifiConnectPassword.length > 0 && !host.wifiConnecting
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
        labelText: host.config.formatUiText("Rescan")
        onClicked: host.rescanWifi()
    }
}
