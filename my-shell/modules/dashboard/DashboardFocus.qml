import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    required property QtObject dashboard
    implicitWidth: parent ? parent.width : 400
    implicitHeight: 260
    property int focusLengthSeconds: 25 * 60
    property int focusSecondsLeft: focusLengthSeconds
    property bool focusRunning: false
    property bool dndEnabled: false

    function _formatClock(seconds) {
        const safe = Math.max(0, Number(seconds) || 0);
        const mins = Math.floor(safe / 60);
        const secs = safe % 60;
        return String(mins).padStart(2, "0") + ":" + String(secs).padStart(2, "0");
    }

    function _parseTimeToSeconds(str) {
        const s = String(str || "").trim();
        if (!s.length)
            return -1;
        const m = s.match(/^(\d+):(\d{1,2})$/);
        if (m) {
            const min = Math.min(24 * 60, Math.max(0, parseInt(m[1], 10)));
            const sec = Math.min(59, Math.max(0, parseInt(m[2], 10)));
            return min * 60 + sec;
        }
        const n = parseFloat(s.replace(",", "."));
        if (!Number.isFinite(n) || n <= 0)
            return -1;
        const min = Math.min(300, Math.max(1, Math.round(n)));
        return min * 60;
    }

    function _applyTimeText(text) {
        const sec = _parseTimeToSeconds(text);
        if (sec < 0)
            return;
        root.focusLengthSeconds = sec;
        if (!root.focusRunning)
            root.focusSecondsLeft = sec;
        timeField.text = root._formatClock(root.focusLengthSeconds);
    }

    function _setTimeTextFromState() {
        timeField.text = root._formatClock(root.focusSecondsLeft);
    }

    function _commitTimeField() {
        if (root._parseTimeToSeconds(timeField.text) < 0)
            root._setTimeTextFromState();
        else
            root._applyTimeText(timeField.text);
    }

    function _refreshDndState() {
        if (!dndStateProc.running)
            dndStateProc.exec({ command: dndStateProc.command });
    }

    Process {
        id: dndStateProc
        command: ["bash", "-lc", "if command -v dunstctl >/dev/null 2>&1; then state=$(dunstctl is-paused 2>/dev/null | tr '[:upper:]' '[:lower:]'); [ \"$state\" = true ] && echo on || echo off; elif command -v makoctl >/dev/null 2>&1; then state=$(makoctl mode 2>/dev/null | tr '[:upper:]' '[:lower:]'); [ \"$state\" = do-not-disturb ] && echo on || echo off; elif command -v swaync-client >/dev/null 2>&1; then state=$(swaync-client -D 2>/dev/null | tr '[:upper:]' '[:lower:]'); [ \"$state\" = true ] && echo on || echo off; else echo off; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.dndEnabled = String(text).trim() === "on"
        }
    }

    Process {
        id: dndToggleProc
        command: ["bash", "-lc", "if command -v dunstctl >/dev/null 2>&1; then dunstctl set-paused " + (root.dndEnabled ? "false" : "true") + "; elif command -v makoctl >/dev/null 2>&1; then if " + (!root.dndEnabled ? "true" : "false") + "; then makoctl mode -a do-not-disturb 2>/dev/null || makoctl set-mode do-not-disturb 2>/dev/null; else makoctl mode -r do-not-disturb 2>/dev/null || makoctl set-mode default 2>/dev/null; fi; elif command -v swaync-client >/dev/null 2>&1; then swaync-client -d; fi"]
    }

    Timer {
        interval: 1000
        running: root.focusRunning && root.dashboard.visible
        repeat: true
        onTriggered: {
            root.focusSecondsLeft = Math.max(0, root.focusSecondsLeft - 1);
            if (root.focusSecondsLeft <= 0)
                root.focusRunning = false;
        }
    }

    Timer {
        interval: 3000
        running: root.dashboard.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: root._refreshDndState()
    }

    RowLayout {
        anchors.fill: parent
        spacing: 10

        // Session: timer + primary controls
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "transparent"
            border.color: root.dashboard.dashboardAccent
            border.width: root.dashboard.config.overlayBorderWidth
            radius: root.dashboard.config.rounding

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 10

                Label {
                    text: root.dashboard.config.formatUiText("Focus")
                    color: root.dashboard.config.mutedTextColor
                    font.pixelSize: Math.max(10, root.dashboard.uiFontSize - 1)
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: timeField.height > 0 ? timeField.height : root.dashboard.uiFontSize + 32
                    TextField {
                        id: timeField
                        readOnly: root.focusRunning
                        activeFocusOnPress: true
                        anchors.left: parent.left
                        anchors.right: parent.right
                        topPadding: 4
                        bottomPadding: 4
                        color: root.dashboard.dashboardTextColor
                        font.family: root.dashboard.uiFontFamily
                        font.pixelSize: root.dashboard.uiFontSize + 22
                        font.bold: true
                        horizontalAlignment: TextInput.AlignHCenter
                        selectByMouse: true
                        background: Rectangle {
                            color: "transparent"
                            border.width: root.dashboard.config.buttonBorderWidth
                            border.color: root.dashboard.dashboardAccent
                            radius: Math.max(0, root.dashboard.dashboardSurfaceRounding - 4)
                        }
                        onEditingFinished: { if (!root.focusRunning) root._commitTimeField() }
                        onAccepted: { if (!root.focusRunning) root._commitTimeField() }
                        Component.onCompleted: root._setTimeTextFromState()
                    }
                }
                Label {
                    text: root.focusRunning
                        ? root.dashboard.config.formatUiText("Timer running")
                        : root.dashboard.config.formatUiText("Edit duration when stopped (MM:SS)")
                    color: root.dashboard.config.mutedTextColor
                    font.pixelSize: Math.max(9, root.dashboard.uiFontSize - 2)
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                Item { Layout.fillHeight: true; Layout.minimumHeight: 0 }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        color: "transparent"
                        border.width: root.dashboard.config.buttonBorderWidth
                        border.color: root.dashboard.dashboardAccent
                        radius: Math.max(0, root.dashboard.dashboardSurfaceRounding - 3)
                        Label { anchors.centerIn: parent; text: root.focusRunning ? "⏸" : "▶"; color: root.dashboard.dashboardTextColor; font.pixelSize: root.dashboard.uiFontSize + 20; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (!root.focusRunning && root.focusSecondsLeft <= 0)
                                    root.focusSecondsLeft = root.focusLengthSeconds;
                                root.focusRunning = !root.focusRunning;
                            }
                        }
                    }
                    Rectangle {
                        Layout.preferredWidth: 72
                        Layout.preferredHeight: 56
                        color: "transparent"
                        border.width: root.dashboard.config.buttonBorderWidth
                        border.color: root.dashboard.config.overlayAccentColor
                        radius: Math.max(0, root.dashboard.dashboardSurfaceRounding - 3)
                        Label { anchors.centerIn: parent; text: "↺"; color: root.dashboard.dashboardTextColor; font.pixelSize: root.dashboard.uiFontSize + 18; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.focusRunning = false;
                                root.focusSecondsLeft = root.focusLengthSeconds;
                                root._setTimeTextFromState();
                            }
                        }
                    }
                }
            }
        }

        // Quiet panel: DND + leave dashboard
        Rectangle {
            Layout.preferredWidth: 220
            Layout.minimumWidth: 200
            Layout.fillHeight: true
            color: "transparent"
            border.color: root.dashboard.dashboardAccent
            border.width: root.dashboard.config.overlayBorderWidth
            radius: root.dashboard.config.rounding

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Label {
                    text: root.dashboard.config.formatUiText("While focusing")
                    color: root.dashboard.config.mutedTextColor
                    font.pixelSize: Math.max(10, root.dashboard.uiFontSize - 1)
                }
                Label {
                    text: root.dashboard.config.formatUiText("Silence notifications")
                    color: root.dashboard.config.mutedTextColor
                    font.pixelSize: Math.max(9, root.dashboard.uiFontSize - 2)
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    radius: Math.max(0, root.dashboard.dashboardSurfaceRounding - 3)
                    color: root.dndEnabled
                        ? Qt.rgba(root.dashboard.dashboardAccent.r, root.dashboard.dashboardAccent.g, root.dashboard.dashboardAccent.b, 0.15)
                        : "transparent"
                    border.width: root.dashboard.config.buttonBorderWidth
                    border.color: root.dndEnabled ? root.dashboard.dashboardAccent : root.dashboard.config.overlayAccentColor
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10
                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            color: root.dndEnabled ? root.dashboard.dashboardAccent : root.dashboard.config.mutedTextColor
                        }
                        Label {
                            text: root.dndEnabled ? root.dashboard.config.formatUiText("On") : root.dashboard.config.formatUiText("Off")
                            color: root.dashboard.dashboardTextColor
                            font.pixelSize: root.dashboard.uiFontSize + 1
                            font.bold: true
                            Layout.fillWidth: true
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            dndToggleProc.exec({ command: dndToggleProc.command });
                            dndRefreshDelay.restart();
                        }
                    }
                }

                Item { Layout.fillHeight: true; Layout.minimumHeight: 4 }

                Label {
                    text: root.dashboard.config.formatUiText("Dashboard")
                    color: root.dashboard.config.mutedTextColor
                    font.pixelSize: Math.max(9, root.dashboard.uiFontSize - 2)
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    color: "transparent"
                    border.width: root.dashboard.config.buttonBorderWidth
                    border.color: root.dashboard.config.overlayAccentColor
                    radius: Math.max(0, root.dashboard.dashboardSurfaceRounding - 3)
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        Label { text: "×"; color: root.dashboard.config.mutedTextColor; font.pixelSize: root.dashboard.uiFontSize + 16; font.bold: true }
                        Label { text: root.dashboard.config.formatUiText("Close"); color: root.dashboard.dashboardTextColor; font.pixelSize: root.dashboard.uiFontSize - 1 }
                    }
                    MouseArea { anchors.fill: parent; onClicked: root.dashboard.closeDashboard() }
                }
            }
        }
    }

    Connections {
        target: root
        function onFocusRunningChanged() { root._setTimeTextFromState() }
        function onFocusSecondsLeftChanged() { if (root.focusRunning) root._setTimeTextFromState() }
    }

    Timer {
        id: dndRefreshDelay
        interval: 220
        repeat: false
        onTriggered: root._refreshDndState()
    }
}
