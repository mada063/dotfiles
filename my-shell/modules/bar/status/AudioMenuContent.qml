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
        MenuButton { host: root.host; buttonImplicitWidth: 56; buttonImplicitHeight: 24; labelText: host.config.formatUiText("Mute"); onClicked: host.audioToggleMute() }
        MenuButton { visible: root.showMixer; host: root.host; buttonImplicitWidth: 56; buttonImplicitHeight: 24; labelText: host.config.formatUiText("Mixer"); onClicked: host.audioOpenMixer() }
    }

    MenuSectionLabel { text: host.config.formatUiText("Output devices"); host: root.host }
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
                color: modelData.default
                    ? Qt.rgba(host.config.overlayAccentColor.r, host.config.overlayAccentColor.g, host.config.overlayAccentColor.b, 0.12)
                    : (_outRowHover.hovered ? Qt.rgba(host.config.overlayAccentColor.r, host.config.overlayAccentColor.g, host.config.overlayAccentColor.b, 0.10) : "transparent")
                border.width: host.config.buttonBorderWidth
                border.color: (modelData.default || _outRowHover.hovered) ? host.config.overlayAccentColor : host.config.mutedTextColor

                HoverHandler { id: _outRowHover }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 8
                    Label { text: modelData.description; color: _outRowHover.hovered ? host.config.overlayAccentColor : host.config.textColor; Layout.fillWidth: true; elide: Text.ElideRight }
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

    MenuSectionLabel { text: host.config.formatUiText("Input devices"); host: root.host }
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
                color: modelData.default
                    ? Qt.rgba(host.config.overlayAccentColor.r, host.config.overlayAccentColor.g, host.config.overlayAccentColor.b, 0.12)
                    : (_inRowHover.hovered ? Qt.rgba(host.config.overlayAccentColor.r, host.config.overlayAccentColor.g, host.config.overlayAccentColor.b, 0.10) : "transparent")
                border.width: host.config.buttonBorderWidth
                border.color: (modelData.default || _inRowHover.hovered) ? host.config.overlayAccentColor : host.config.mutedTextColor

                HoverHandler { id: _inRowHover }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 8
                    Label { text: modelData.description; color: _inRowHover.hovered ? host.config.overlayAccentColor : host.config.textColor; Layout.fillWidth: true; elide: Text.ElideRight }
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
