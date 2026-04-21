import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: root

    required property QtObject control

    clip: true

    ColumnLayout {
        width: parent.width
        spacing: 0

        // ── Theme ──────────────────────────────────────────────────────

        Label { text: "Theme"; color: root.control.config.accentColor; font.bold: true; Layout.bottomMargin: 6 }

        Label {
            text: "Active: " + root.control.activeThemePresetName
            color: root.control.config.textColor
            Layout.fillWidth: true
            Layout.bottomMargin: 2
        }

        Label {
            text: "Themes are selected from the dashboard theme screen."
            color: root.control.config.mutedTextColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.bottomMargin: 18
        }

        // ── Appearance ────────────────────────────────────────────────

        Label { text: "Appearance"; color: root.control.config.accentColor; font.bold: true; Layout.bottomMargin: 8 }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: "Theme Mode"; color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            ComboBox {
                Layout.preferredWidth: 130
                model: ["dark", "light", "auto"]
                currentIndex: model.indexOf(root.control.config.themeMode)
                onActivated: root.control.config.themeMode = currentText
            }
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: "Font Family"; color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            TextField {
                Layout.preferredWidth: 200
                text: root.control.config.fontFamily
                placeholderText: "JetBrainsMono Nerd Font"
                onEditingFinished: root.control.config.fontFamily = String(text).trim() || "JetBrainsMono Nerd Font"
            }
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: "Font Size"; color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            SpinBox { from: 9; to: 24; value: root.control.config.fontPixelSize; onValueModified: root.control.config.fontPixelSize = value }
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: "Global Rounding"; color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            SpinBox { from: 0; to: 24; value: root.control.config.rounding; onValueModified: root.control.config.rounding = value }
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: "Border Width"; color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            SpinBox { from: 0; to: 4; value: root.control.config.borderWidth; onValueModified: root.control.config.borderWidth = value }
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: "Button Border"; color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            SpinBox { from: 0; to: 4; value: root.control.config.buttonBorderWidth; onValueModified: root.control.config.buttonBorderWidth = value }
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: "Overlay Border"; color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            SpinBox { from: 0; to: 6; value: root.control.config.overlayBorderWidth; onValueModified: root.control.config.overlayBorderWidth = value }
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: "Panel Opacity (%)"; color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            SpinBox { from: 55; to: 100; value: Math.round(root.control.config.panelOpacity * 100); onValueModified: root.control.config.panelOpacity = Math.max(0.55, Math.min(1, value / 100)) }
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: "Overlay Dim (%)"; color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            SpinBox { from: 0; to: 90; value: Math.round(root.control.config.overlayDimOpacity * 100); onValueModified: root.control.config.overlayDimOpacity = Math.max(0, Math.min(0.9, value / 100)) }
        }

        Item { implicitHeight: 18 }

        // ── Preview ───────────────────────────────────────────────────

        Label { text: "Preview"; color: root.control.config.accentColor; font.bold: true; Layout.bottomMargin: 8 }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 44
            radius: root.control.config.rounding
            color: root.control.config.backgroundColor
            border.width: root.control.config.borderWidth
            border.color: root.control.config.borderColor
            Layout.bottomMargin: 8

            Row {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 6

                Rectangle {
                    width: 34; height: 22
                    radius: root.control.config.rounding
                    color: root.control.config.workspaceAccentColor
                    border.width: root.control.config.buttonBorderWidth
                    border.color: root.control.config.borderColor
                    Label { anchors.centerIn: parent; text: "1"; color: root.control.config.workspaceColor; font.bold: true }
                }

                Rectangle {
                    width: 90; height: 22
                    radius: root.control.config.rounding
                    color: "transparent"
                    border.width: root.control.config.buttonBorderWidth
                    border.color: root.control.config.mutedTextColor
                    Label { anchors.centerIn: parent; text: "VOL ||||||"; color: root.control.config.textColor }
                }

                Rectangle {
                    width: 108; height: 22
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
            implicitHeight: 56
            radius: root.control.config.rounding
            color: "transparent"
            border.width: 1
            border.color: root.control.config.mutedTextColor
            opacity: 0.9

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

        Item { implicitHeight: 8 }
    }
}
