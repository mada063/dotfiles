import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

/**
 * Top bar content: workspaces (1–9), centered clock, CPU/GPU + power-style slot.
 * Expects a PanelWindow parent; uses Hyprland singleton (Hyprland session).
 */
Item {
    id: root

    required property ShellScreen screen

    readonly property color barBg: "#1a1a1f"
    readonly property color barFg: "#e4e4e7"
    readonly property color accent: "#f97316"
    readonly property color muted: "#71717a"
    readonly property int barPad: 10
    readonly property int barHeight: 32
    readonly property string shellDir: Quickshell.shellDir

    readonly property var mon: Hyprland.monitorFor(screen)

    property string cpuPct: "0"
    property string gpuPct: "—"

    implicitHeight: barHeight

    Rectangle {
        anchors.fill: parent
        color: root.barBg

        Rectangle {
            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
            }
            height: 1
            color: root.accent
            opacity: 0.45
        }
    }

    RowLayout {
        id: barRow

        anchors {
            fill: parent
            leftMargin: root.barPad
            rightMargin: root.barPad
        }
        spacing: 6

        RowLayout {
            id: leftZone
            spacing: 4

            Repeater {
                model: 9

                delegate: Rectangle {
                    id: wsCell

                    required property int index

                    readonly property int wsId: index + 1
                    readonly property bool active: root.mon && root.mon.activeWorkspace && root.mon.activeWorkspace.id === wsId

                    implicitWidth: 26
                    implicitHeight: 22
                    radius: 0
                    color: active ? Qt.darker(root.accent, 1.35) : Qt.lighter(root.barBg, 1.12)
                    border.width: active ? 0 : 1
                    border.color: root.muted

                    Label {
                        anchors.centerIn: parent
                        text: String(wsId)
                        font.family: "JetBrainsMono Nerd Font, monospace"
                        font.pixelSize: 11
                        font.bold: active
                        color: active ? "#0c0c0e" : root.barFg
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Hyprland.dispatch(`workspace ${wsCell.wsId}`)
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Label {
            id: clockLabel

            Layout.alignment: Qt.AlignVCenter
            font.family: "JetBrainsMono Nerd Font, monospace"
            font.pixelSize: 12
            font.bold: false
            color: root.accent

            property date now: new Date()

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clockLabel.now = new Date()
            }

            text: Qt.formatDateTime(clockLabel.now, "ddd dd MMM  HH:mm:ss")
        }

        Item {
            Layout.fillWidth: true
        }

        RowLayout {
            id: rightZone
            spacing: 10

            Label {
                id: statsLabel
                Layout.alignment: Qt.AlignVCenter
                font.family: "JetBrainsMono Nerd Font, monospace"
                font.pixelSize: 11
                color: root.barFg
                text: `CPU ${root.cpuPct}%  GPU ${root.gpuPct}${/^[0-9]+$/.test(root.gpuPct) ? "%" : ""}`
            }

            Label {
                Layout.alignment: Qt.AlignVCenter
                text: "⏻"
                font.pixelSize: 14
                color: root.accent
                ToolTip.text: "Session / power: bind your key (e.g. loginctl) — placeholder"
                ToolTip.visible: pwrHover.containsMouse
                ToolTip.delay: 500

                MouseArea {
                    id: pwrHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }
            }
        }
    }

    Process {
        id: statsProc

        command: ["bash", root.shellDir + "/scripts/stats.sh"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const parts = String(text).trim().split(/\s+/);
                root.cpuPct = parts[0] ?? "0";
                root.gpuPct = parts[1] ?? "—";
            }
        }
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statsProc.exec({
            "command": ["bash", root.shellDir + "/scripts/stats.sh"]
        })
    }
}
