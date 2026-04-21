import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property QtObject shell
    required property QtObject config
    required property var availableThemes
    required property string uiFontFamily
    required property int uiFontSize
    readonly property bool shown: root.shell.themeSelectorVisible

    visible: root.shown || overlayDimmer.opacity > 0.01 || selectorPanel.opacity > 0.01
    focusable: root.shown
    WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    function _themeTextColor(theme) {
        return String((theme.general && theme.general.textColor) || theme.textColor || "#e5e7eb");
    }

    function _themeAccentColor(theme) {
        return String((theme.general && theme.general.accentColor) || theme.accentColor || "#ff8c32");
    }

    function _themeBackgroundColor(theme) {
        return String((theme.general && theme.general.panelColor)
            || (theme.general && theme.general.backgroundColor)
            || theme.panelColor
            || theme.backgroundColor
            || "#18181b");
    }

    function _themeRounding(theme) {
        const general = theme.general || {};
        const value = Number(general.rounding !== undefined ? general.rounding : theme.rounding);
        return Number.isFinite(value) ? Math.max(0, Math.round(value)) : 8;
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "#00000000"

    Rectangle {
        id: overlayDimmer
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, root.config.overlayDimOpacity)
        opacity: root.shown ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.shell.themeSelectorVisible = false
        }
    }

    Rectangle {
        id: selectorPanel
        property real offsetY: root.shown ? 0 : -24
        width: Math.min(parent.width - 48, 300)
        height: Math.min(parent.height - 48, 150)
        anchors.centerIn: parent
        anchors.verticalCenterOffset: offsetY
        color: root.config.settingsBackgroundColor
        border.color: root.config.settingsAccentColor
        border.width: root.config.overlayBorderWidth
        radius: root.config.settingsRounding
        z: 1
        opacity: root.shown ? root.config.panelOpacity : 0
        Behavior on offsetY {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            Label {
                text: "Themes"
                color: root.config.settingsTextColor
                font.family: root.uiFontFamily
                font.pixelSize: root.uiFontSize + 6
                font.bold: true
            }

            Item {
                id: selectorArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                property int themeCount: Math.max(1, (root.availableThemes || []).length)
                property int barSpacing: 10
                property int sidePadding: 12
                property int barWidth: Math.max(24, Math.min(44,
                    Math.floor((width - (sidePadding * 2) - (barSpacing * (themeCount - 1))) / themeCount)))
                property int barHeight: Math.max(80, Math.min(120, height - 24))

                Row {
                    id: selectorRow
                    anchors.centerIn: parent
                    spacing: selectorArea.barSpacing

                    Repeater {
                        model: root.availableThemes
                        delegate: Item {
                            required property var modelData
                            width: selectorArea.barWidth
                            height: selectorArea.barHeight

                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                border.width: String(root.config.activeThemeId) === String(modelData.id)
                                    ? Math.max(2, root.config.buttonBorderWidth + 1)
                                    : Math.max(1, root.config.buttonBorderWidth)
                                border.color: String(root.config.activeThemeId) === String(modelData.id)
                                    ? root._themeAccentColor(modelData)
                                    : root.config.mutedTextColor
                                radius: root._themeRounding(modelData)
                                clip: true

                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: parent.height / 2
                                    color: root._themeTextColor(modelData)
                                }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: parent.height / 2
                                    color: root._themeAccentColor(modelData)
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.shell.setActiveThemeById(modelData.id);
                                    root.shell.themeSelectorVisible = false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
