import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: root
    required property QtObject control
    function _T(s) { return root.control.config.formatUiText(s); }
    property bool doNotDisturb: false
    property bool showInFullscreen: true
    property bool autoDismiss: true
    property int timeoutSeconds: 6

    function refreshDndState() {
        if (!dndStateProc.running)
            dndStateProc.exec({ command: dndStateProc.command });
    }

    function setDndState(enabled) {
        doNotDisturb = enabled;
        dndToggleProc.exec({
            command: ["bash", "-lc", "if command -v dunstctl >/dev/null 2>&1; then dunstctl set-paused " + (enabled ? "true" : "false") + "; elif command -v makoctl >/dev/null 2>&1; then if " + (enabled ? "true" : "false") + "; then makoctl mode -a do-not-disturb 2>/dev/null || makoctl set-mode do-not-disturb 2>/dev/null; else makoctl mode -r do-not-disturb 2>/dev/null || makoctl set-mode default 2>/dev/null; fi; fi"]
        });
    }

    Component.onCompleted: refreshDndState()

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 16

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: behaviorColumn.implicitHeight + 28
            radius: root.control.config.overlayRounding
            color: Qt.rgba(root.control.config.overlayBackgroundColor.r, root.control.config.overlayBackgroundColor.g, root.control.config.overlayBackgroundColor.b, 0.22)
            border.color: root.control.config.buttonBorderColor
            border.width: root.control.config.buttonBorderWidth

            ColumnLayout {
                id: behaviorColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 10
                Label { text: root._T("Notifications"); color: root.control.config.accentColor; font.bold: true; font.family: root.control.uiFontFamily }
                Label {
                    text: root._T("Control notification behavior and quick settings toast rendering.")
                    color: root.control.config.mutedTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                RowLayout {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    Label { text: root._T("Show in fullscreen"); Layout.fillWidth: true; color: root.control.config.textColor }
                    Switch {
                        checked: root.showInFullscreen
                        onToggled: root.showInFullscreen = checked
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    Label { text: root._T("Auto-dismiss"); Layout.fillWidth: true; color: root.control.config.textColor }
                    Switch { checked: root.autoDismiss; onToggled: root.autoDismiss = checked }
                }
                RowLayout {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    Label { text: root._T("Timeout duration (sec)"); Layout.fillWidth: true; color: root.control.config.textColor }
                    SpinBox {
                        from: 1
                        to: 30
                        value: root.timeoutSeconds
                        onValueModified: root.timeoutSeconds = value
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    Label { text: root._T("Do not disturb"); Layout.fillWidth: true; color: root.control.config.textColor }
                    Switch {
                        checked: root.doNotDisturb
                        onToggled: root.setDndState(checked)
                    }
                }
                Button { text: root._T("Refresh notifier state"); onClicked: root.refreshDndState() }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: visualsColumn.implicitHeight + 28
            radius: root.control.config.overlayRounding
            color: Qt.rgba(root.control.config.overlayBackgroundColor.r, root.control.config.overlayBackgroundColor.g, root.control.config.overlayBackgroundColor.b, 0.22)
            border.color: root.control.config.buttonBorderColor
            border.width: root.control.config.buttonBorderWidth

            ColumnLayout {
                id: visualsColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 10

                Label { text: root._T("Visual Details"); color: root.control.config.accentColor; font.bold: true; font.family: root.control.uiFontFamily }
                RowLayout {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    Label { text: root._T("Popup padding"); Layout.fillWidth: true; color: root.control.config.textColor }
                    SpinBox {
                        from: 0
                        to: 28
                        value: root.control.config.quickSettingsNotificationPadding
                        onValueModified: root.control.config.quickSettingsNotificationPadding = value
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    Label { text: root._T("Panel opacity (%)"); Layout.fillWidth: true; color: root.control.config.textColor }
                    SpinBox {
                        from: 55
                        to: 100
                        value: Math.round(root.control.config.panelOpacity * 100)
                        onValueModified: root.control.config.panelOpacity = Math.max(0.55, Math.min(1, value / 100))
                    }
                }
                Label {
                    text: root._T("Timeout and fullscreen toggles are wired and ready to map into overlay policy.")
                    color: root.control.config.mutedTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }
    }

    Process {
        id: dndStateProc
        command: ["bash", "-lc", "if command -v dunstctl >/dev/null 2>&1; then state=$(dunstctl is-paused 2>/dev/null | tr '[:upper:]' '[:lower:]'); [ \"$state\" = true ] && echo on || echo off; elif command -v makoctl >/dev/null 2>&1; then state=$(makoctl mode 2>/dev/null | tr '[:upper:]' '[:lower:]'); [ \"$state\" = do-not-disturb ] && echo on || echo off; else echo off; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.doNotDisturb = String(text).trim() === "on"
        }
    }

    Process { id: dndToggleProc }
}
