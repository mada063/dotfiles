import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: root

    required property QtObject control

    clip: true

    ColumnLayout {
        width: parent.width
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: themeSection.implicitHeight + 20
            color: Qt.rgba(root.control.config.accentColor.r, root.control.config.accentColor.g, root.control.config.accentColor.b, 0.06)
            border.width: root.control.config.overlayBorderWidth
            border.color: root.control.config.accentColor
            radius: root.control.config.rounding

            ColumnLayout {
                id: themeSection
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label { text: "Themes"; color: root.control.config.textColor; font.bold: true }
                        Label {
                            text: "Choose and apply a saved theme here. Detailed color editing now lives in Theme Studio."
                            color: root.control.config.mutedTextColor
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    Button {
                        text: "Open Theme Studio"
                        onClicked: root.control.shell.themeWindowVisible = true
                    }
                }

                Label {
                    text: "Current: " + root.control.activeThemePresetName
                    color: root.control.config.mutedTextColor
                }

                Item {
                    Layout.fillWidth: true
                    implicitHeight: themePresetFlow.implicitHeight

                    Flow {
                        id: themePresetFlow
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: root.control.availableThemes
                            delegate: Rectangle {
                                required property var modelData
                                implicitWidth: 176
                                implicitHeight: 64
                                radius: root.control.config.rounding
                                color: "transparent"
                                border.width: root.control.config.buttonBorderWidth
                                border.color: root.control.activeThemePresetName === modelData.name
                                    ? root.control.config.accentColor
                                    : root.control.config.mutedTextColor

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 6

                                    Label {
                                        text: modelData.name
                                        color: root.control.config.textColor
                                        font.bold: true
                                    }

                                    Row {
                                        spacing: 6

                                        Repeater {
                                            model: [
                                                modelData.backgroundColor,
                                                modelData.accentColor,
                                                modelData.textColor,
                                                modelData.workspaceAccentColor,
                                                modelData.overlayAccentColor
                                            ]
                                            delegate: Rectangle {
                                                required property var modelData
                                                width: 16
                                                height: 16
                                                radius: 4
                                                color: modelData
                                                border.width: 1
                                                border.color: root.control.config.mutedTextColor
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root.control._applyThemePreset(parent.modelData)
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: shellAppearanceSection.implicitHeight + 20
            color: Qt.rgba(root.control.config.accentColor.r, root.control.config.accentColor.g, root.control.config.accentColor.b, 0.06)
            border.width: root.control.config.overlayBorderWidth
            border.color: root.control.config.accentColor
            radius: root.control.config.rounding

            ColumnLayout {
                id: shellAppearanceSection
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Label { text: "Shell Appearance"; color: root.control.config.overlayAccentColor; font.bold: true }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    rowSpacing: 8
                    columnSpacing: 10

                    Label { text: "Theme Mode"; color: root.control.config.textColor }
                    ComboBox {
                        model: ["dark", "light", "auto"]
                        currentIndex: model.indexOf(root.control.config.themeMode)
                        onActivated: root.control.config.themeMode = currentText
                    }
                    Label { text: "Global Rounding"; color: root.control.config.textColor }
                    SpinBox {
                        from: 0; to: 24
                        value: root.control.config.rounding
                        onValueModified: root.control.config.rounding = value
                    }

                    Label { text: "Border Width"; color: root.control.config.textColor }
                    SpinBox {
                        from: 0; to: 4
                        value: root.control.config.borderWidth
                        onValueModified: root.control.config.borderWidth = value
                    }
                    Label { text: "Button Border"; color: root.control.config.textColor }
                    SpinBox {
                        from: 0; to: 4
                        value: root.control.config.buttonBorderWidth
                        onValueModified: root.control.config.buttonBorderWidth = value
                    }

                    Label { text: "Overlay Border"; color: root.control.config.textColor }
                    SpinBox {
                        from: 0; to: 6
                        value: root.control.config.overlayBorderWidth
                        onValueModified: root.control.config.overlayBorderWidth = value
                    }
                    Label { text: "Panel Opacity (%)"; color: root.control.config.textColor }
                    SpinBox {
                        from: 55; to: 100
                        value: Math.round(root.control.config.panelOpacity * 100)
                        onValueModified: root.control.config.panelOpacity = Math.max(0.55, Math.min(1, value / 100))
                    }

                    Label { text: "Overlay Dim (%)"; color: root.control.config.textColor }
                    SpinBox {
                        from: 0; to: 90
                        value: Math.round(root.control.config.overlayDimOpacity * 100)
                        onValueModified: root.control.config.overlayDimOpacity = Math.max(0, Math.min(0.9, value / 100))
                    }
                    Label { text: "Font Size (px)"; color: root.control.config.textColor }
                    SpinBox {
                        from: 9; to: 24
                        value: root.control.config.fontPixelSize
                        onValueModified: root.control.config.fontPixelSize = value
                    }
                }

                Label { text: "Font Family"; color: root.control.config.textColor }
                TextField {
                    Layout.fillWidth: true
                    text: root.control.config.fontFamily
                    placeholderText: "JetBrainsMono Nerd Font"
                    onEditingFinished: root.control.config.fontFamily = String(text).trim() || "JetBrainsMono Nerd Font"
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: previewSection.implicitHeight + 20
            color: Qt.rgba(root.control.config.accentColor.r, root.control.config.accentColor.g, root.control.config.accentColor.b, 0.06)
            border.width: root.control.config.overlayBorderWidth
            border.color: root.control.config.accentColor
            radius: root.control.config.rounding

            ColumnLayout {
                id: previewSection
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Label { text: "Live Preview"; color: root.control.config.accentColor; font.bold: true }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 48
                    radius: root.control.config.rounding
                    color: root.control.config.backgroundColor
                    border.width: root.control.config.borderWidth
                    border.color: root.control.config.borderColor

                    Row {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 6

                        Rectangle {
                            width: 34
                            height: 22
                            radius: root.control.config.rounding
                            color: root.control.config.workspaceAccentColor
                            border.width: root.control.config.buttonBorderWidth
                            border.color: root.control.config.borderColor
                            Label { anchors.centerIn: parent; text: "1"; color: root.control.config.workspaceColor; font.bold: true }
                        }

                        Rectangle {
                            width: 90
                            height: 22
                            radius: root.control.config.rounding
                            color: "transparent"
                            border.width: root.control.config.buttonBorderWidth
                            border.color: root.control.config.mutedTextColor
                            Label { anchors.centerIn: parent; text: "VOL ||||||"; color: root.control.config.textColor }
                        }

                        Rectangle {
                            width: 108
                            height: 22
                            radius: root.control.config.rounding
                            color: "transparent"
                            border.width: root.control.config.buttonBorderWidth
                            border.color: root.control.config.overlayAccentColor
                            Label { anchors.centerIn: parent; text: "Overlay"; color: root.control.config.textColor }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 62
                    radius: root.control.config.rounding
                    color: "transparent"
                    border.width: 1
                    border.color: root.control.config.mutedTextColor

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Label {
                            text: "Font Preview"
                            color: root.control.config.accentColor
                            font.family: root.control.config.fontFamily
                            font.pixelSize: root.control.config.fontPixelSize + 1
                            font.bold: true
                        }
                        Label {
                            text: "The quick brown fox jumps over 0123456789"
                            color: root.control.config.textColor
                            font.family: root.control.config.fontFamily
                            font.pixelSize: root.control.config.fontPixelSize
                        }
                    }
                }
            }
        }
    }
}
