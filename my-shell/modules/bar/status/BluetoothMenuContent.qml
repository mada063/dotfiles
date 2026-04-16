import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Column {
    id: root

    required property QtObject host
    property int toggleWidth: 38
    property int toggleHeight: 20
    property int knobSize: 14
    property int listHeight: 170

    readonly property bool _hug: host.statusMenuHugWidth === true

    spacing: 6
    width: _hug ? host.sideMenuHugContentWidth : host.statusMenuContentWidth

    Label {
        visible: host.btDetailText.length > 0 && host.btDetailText !== "-"
        width: parent.width
        color: host.config.mutedTextColor
        wrapMode: Text.WordWrap
        text: host.btDetailText
    }

    Column {
        width: parent.width
        spacing: 4
        MenuToggle {
            width: parent.width
            host: root.host
            labelText: "Enabled"
            checked: host.btEnabled
            toggleWidth: root.toggleWidth
            toggleHeight: root.toggleHeight
            knobSize: root.knobSize
            onToggled: host.toggleBtEnabled()
        }
        MenuToggle {
            width: parent.width
            host: root.host
            labelText: "Discoverable"
            checked: host.btDiscoverable
            toggleWidth: root.toggleWidth
            toggleHeight: root.toggleHeight
            knobSize: root.knobSize
            onToggled: host.toggleBtDiscoverable()
        }
    }

    MenuSectionLabel { text: "Connected"; host: root.host }
    Label {
        width: parent.width
        color: host.config.mutedTextColor
        wrapMode: Text.WordWrap
        text: {
            let connected = 0;
            for (let i = 0; i < host.btDevices.length; i++) {
                if (host.btDevices[i].connected)
                    connected++;
            }
            return connected + " connected, " + Math.max(0, host.btDevices.length - connected) + " available";
        }
    }

    ScrollView {
        width: parent.width
        height: root.listHeight
        clip: true
        ListView {
            model: host.btDevices
            spacing: 4
            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width - 8
                height: 42
                radius: Math.max(0, host.config.rounding - 3)
                color: modelData.connected ? Qt.rgba(host.config.overlayAccentColor.r, host.config.overlayAccentColor.g, host.config.overlayAccentColor.b, 0.12) : "transparent"
                border.width: host.config.buttonBorderWidth
                border.color: host.config.mutedTextColor
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 8
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Layout.minimumWidth: 0
                        Layout.preferredWidth: 1
                        Label { text: modelData.name; color: host.config.textColor; elide: Text.ElideRight; Layout.fillWidth: true; Layout.minimumWidth: 0; Layout.preferredWidth: 1 }
                        Label { text: modelData.mac + (modelData.connected ? "  connected" : ""); color: host.config.mutedTextColor; elide: Text.ElideRight; Layout.fillWidth: true; Layout.minimumWidth: 0; Layout.preferredWidth: 1; font.pixelSize: Math.max(10, host.uiFontSize - 1) }
                    }
                    MenuButton {
                        host: root.host
                        buttonImplicitWidth: modelData.connected ? 78 : 68
                        buttonImplicitHeight: 24
                        labelText: modelData.connected ? "Disconnect" : "Connect"
                        onClicked: {
                            if (modelData.connected)
                                host.disconnectBt(modelData.mac);
                            else
                                host.connectBt(modelData.mac);
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
        onClicked: host.rescanBt()
    }
}
