import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: root
    required property QtObject control
    function _T(s) { return root.control.config.formatUiText(s); }
    property var outputDevices: []
    property var inputDevices: []
    property int masterVolume: 50
    property int micVolume: 50

    function refresh() {
        if (!sinkProc.running)
            sinkProc.exec({ command: sinkProc.command });
        if (!sourceProc.running)
            sourceProc.exec({ command: sourceProc.command });
        if (!volumeProc.running)
            volumeProc.exec({ command: volumeProc.command });
    }

    function setMasterVolume(value) {
        masterVolume = value;
        volumeSetProc.exec({ command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then pactl set-sink-volume @DEFAULT_SINK@ " + Number(value) + "%; fi"] });
    }

    function setMicVolume(value) {
        micVolume = value;
        micSetProc.exec({ command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then pactl set-source-volume @DEFAULT_SOURCE@ " + Number(value) + "%; fi"] });
    }

    Component.onCompleted: refresh()

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 16

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: devicesColumn.implicitHeight + 28
            radius: root.control.config.overlayRounding
            color: Qt.rgba(root.control.config.overlayBackgroundColor.r, root.control.config.overlayBackgroundColor.g, root.control.config.overlayBackgroundColor.b, 0.22)
            border.color: root.control.config.buttonBorderColor
            border.width: root.control.config.buttonBorderWidth

            ColumnLayout {
                id: devicesColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 10

                Label { text: root._T("Output Devices"); color: root.control.config.accentColor; font.family: root.control.uiFontFamily; font.bold: true }
                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    clip: true
                    model: root.outputDevices
                    delegate: Label { required property string modelData; text: String(modelData); color: root.control.config.textColor; font.family: root.control.uiFontFamily }
                }

                Label { text: root._T("Input Devices"); color: root.control.config.accentColor; font.family: root.control.uiFontFamily; font.bold: true }
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: root.inputDevices
                    delegate: Label { required property string modelData; text: String(modelData); color: root.control.config.textColor; font.family: root.control.uiFontFamily }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: mixerColumn.implicitHeight + 28
            radius: root.control.config.overlayRounding
            color: Qt.rgba(root.control.config.overlayBackgroundColor.r, root.control.config.overlayBackgroundColor.g, root.control.config.overlayBackgroundColor.b, 0.22)
            border.color: root.control.config.buttonBorderColor
            border.width: root.control.config.buttonBorderWidth

            ColumnLayout {
                id: mixerColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 10
                Label { text: root._T("Mixer"); color: root.control.config.accentColor; font.family: root.control.uiFontFamily; font.bold: true }
                Label { text: root._T("Master Volume"); color: root.control.config.textColor; font.family: root.control.uiFontFamily }
                Slider {
                    from: 0
                    to: 100
                    value: root.masterVolume
                    Layout.fillWidth: true
                    onMoved: root.setMasterVolume(value)
                }
                Label { text: root._T("Mic Gain"); color: root.control.config.textColor; font.family: root.control.uiFontFamily }
                Slider {
                    from: 0
                    to: 100
                    value: root.micVolume
                    Layout.fillWidth: true
                    onMoved: root.setMicVolume(value)
                }
                Button { text: root._T("Refresh"); onClicked: root.refresh() }
            }
        }
    }

    Process {
        id: sinkProc
        command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then pactl list short sinks | awk '{print $2 \"  \" $NF}'; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const lines = String(text).trim().split('\n').filter(line => line.length > 0);
                root.outputDevices = lines.length > 0 ? lines : [root._T("No output devices")];
            }
        }
    }

    Process {
        id: sourceProc
        command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then pactl list short sources | awk '$2 !~ /monitor/ {print $2 \"  \" $NF}'; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const lines = String(text).trim().split('\n').filter(line => line.length > 0);
                root.inputDevices = lines.length > 0 ? lines : [root._T("No input devices")];
            }
        }
    }

    Process {
        id: volumeProc
        command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then sink=$(pactl get-sink-volume @DEFAULT_SINK@ | awk 'NR==1{for(i=1;i<=NF;i++) if($i ~ /%/){gsub(/%/,\"\",$i); print $i; exit}}'); src=$(pactl get-source-volume @DEFAULT_SOURCE@ | awk 'NR==1{for(i=1;i<=NF;i++) if($i ~ /%/){gsub(/%/,\"\",$i); print $i; exit}}'); echo \"${sink:-50}|${src:-50}\"; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const parts = String(text).trim().split("|");
                root.masterVolume = Number(parts[0]) || 50;
                root.micVolume = Number(parts[1]) || 50;
            }
        }
    }

    Process { id: volumeSetProc }
    Process { id: micSetProc }
}
