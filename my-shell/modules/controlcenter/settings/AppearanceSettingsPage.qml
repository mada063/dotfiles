import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ".." as LegacyTabs

Item {
    id: root
    required property QtObject control
    property int scalingPercent: 100

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 16

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredWidth: parent.width * 0.7
            implicitHeight: appearancePane.implicitHeight
            radius: root.control.config.overlayRounding
            color: "transparent"
            border.width: 0

            // Keep old appearance page so styling/behavior remains consistent.
            LegacyTabs.AppearanceTab {
                id: appearancePane
                anchors.fill: parent
                control: root.control
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredWidth: parent.width * 0.3
            implicitHeight: extrasColumn.implicitHeight + 28
            radius: root.control.config.overlayRounding
            color: Qt.rgba(root.control.config.overlayBackgroundColor.r, root.control.config.overlayBackgroundColor.g, root.control.config.overlayBackgroundColor.b, 0.22)
            border.color: root.control.config.buttonBorderColor
            border.width: root.control.config.buttonBorderWidth

            ColumnLayout {
                id: extrasColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 10

                Label { text: root.control.config.formatUiText("Extras"); color: root.control.config.accentColor; font.bold: true; font.family: root.control.uiFontFamily }
                RowLayout {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    Label { text: root.control.config.formatUiText("Animations"); Layout.fillWidth: true; color: root.control.config.textColor }
                    Switch {
                        checked: root.control.config.uiAnimationsEnabled
                        onToggled: root.control.config.uiAnimationsEnabled = checked
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    Label { text: root.control.config.formatUiText("Overlay slide (ms)"); Layout.fillWidth: true; color: root.control.config.textColor }
                    SpinBox {
                        from: 80
                        to: 800
                        stepSize: 20
                        value: root.control.config.overlaySlideDurationMs
                        onValueModified: root.control.config.overlaySlideDurationMs = value
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    Label { text: root.control.config.formatUiText("Scaling (%)"); Layout.fillWidth: true; color: root.control.config.textColor }
                    SpinBox {
                        from: 75
                        to: 150
                        value: root.scalingPercent
                        onValueModified: root.scalingPercent = value
                    }
                }
                Label {
                    text: root.control.config.formatUiText("Theme, font, and borders stay in the main Appearance pane.")
                    color: root.control.config.mutedTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                Item { Layout.fillHeight: true }
            }
        }
    }
}
