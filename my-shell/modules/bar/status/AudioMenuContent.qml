import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Column {
    id: root

    required property QtObject host
    property int outputListHeight: 110
    property int inputListHeight: 96
    property int menuFontBoost: 8
    property bool showMixer: false

    readonly property bool _hug: host.statusMenuHugWidth === true

    spacing: 6
    width: _hug ? host.sideMenuHugContentWidth : host.statusMenuContentWidth

    Text {
        width: parent.width
        text: host._volumeMenuRichText(host.volumePercent, host.volumeMuted, width)
        color: host.config.textColor
        textFormat: Text.RichText
        font.family: host.uiFontFamily
        font.pixelSize: host.uiFontSize + root.menuFontBoost
        wrapMode: Text.NoWrap
    }

    Row {
        spacing: 6
        MenuButton { host: root.host; buttonImplicitWidth: 26; buttonImplicitHeight: 24; labelText: "-"; onClicked: host.audioStep(-5) }
        MenuButton { host: root.host; buttonImplicitWidth: 26; buttonImplicitHeight: 24; labelText: "+"; onClicked: host.audioStep(5) }
        MenuButton { host: root.host; buttonImplicitWidth: 56; buttonImplicitHeight: 24; labelText: "Mute"; onClicked: host.audioToggleMute() }
        MenuButton { visible: root.showMixer; host: root.host; buttonImplicitWidth: 56; buttonImplicitHeight: 24; labelText: "Mixer"; onClicked: host.audioOpenMixer() }
    }

    MenuSectionLabel { text: "Output Devices"; host: root.host }
    ScrollView {
        width: parent.width
        height: root.outputListHeight
        clip: true
        ListView {
            model: host.audioOutputs
            spacing: 4
            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width - 8
                height: 38
                radius: Math.max(0, host.config.rounding - 3)
                color: modelData.default ? Qt.rgba(host.config.overlayAccentColor.r, host.config.overlayAccentColor.g, host.config.overlayAccentColor.b, 0.12) : "transparent"
                border.width: host.config.buttonBorderWidth
                border.color: host.config.mutedTextColor
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 8
                    Label { text: modelData.description; color: host.config.textColor; Layout.fillWidth: true; elide: Text.ElideRight }
                    MenuButton {
                        host: root.host
                        buttonImplicitWidth: modelData.default ? 64 : 72
                        buttonImplicitHeight: 22
                        labelText: modelData.default ? "Default" : "Use"
                        buttonEnabled: !modelData.default
                        onClicked: host.setDefaultAudioSink(modelData.name)
                    }
                }
            }
        }
    }

    MenuSectionLabel { text: "Input Devices"; host: root.host }
    ScrollView {
        width: parent.width
        height: root.inputListHeight
        clip: true
        ListView {
            model: host.audioInputs
            spacing: 4
            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width - 8
                height: 38
                radius: Math.max(0, host.config.rounding - 3)
                color: modelData.default ? Qt.rgba(host.config.overlayAccentColor.r, host.config.overlayAccentColor.g, host.config.overlayAccentColor.b, 0.12) : "transparent"
                border.width: host.config.buttonBorderWidth
                border.color: host.config.mutedTextColor
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 8
                    Label { text: modelData.description; color: host.config.textColor; Layout.fillWidth: true; elide: Text.ElideRight }
                    MenuButton {
                        host: root.host
                        buttonImplicitWidth: modelData.default ? 64 : 72
                        buttonImplicitHeight: 22
                        labelText: modelData.default ? "Default" : "Use"
                        buttonEnabled: !modelData.default
                        onClicked: host.setDefaultAudioSource(modelData.name)
                    }
                }
            }
        }
    }
}
