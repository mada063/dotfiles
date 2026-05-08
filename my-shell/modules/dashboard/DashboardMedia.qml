import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    required property QtObject dashboard
    required property QtObject mediaPrevProc
    required property QtObject mediaToggleProc
    required property QtObject mediaNextProc

    implicitWidth: parent ? parent.width : 500
    implicitHeight: 300

    readonly property bool mediaActive: root.dashboard.mediaState === "Playing" || root.dashboard.mediaState === "Paused"
    readonly property bool hasArt: root.dashboard.mediaArtUrl && root.dashboard.mediaArtUrl.length > 0
    readonly property bool progressPaused: root.dashboard.mediaState === "Paused"
    readonly property real _pos: root.dashboard.mediaPositionSec
    readonly property real _len: root.dashboard.mediaLengthSec
    readonly property real _frac: (root._len > 0.01 && root._pos >= 0) ? Math.min(1, Math.max(0, root._pos / root._len)) : 0

    function _fmtTime(sec) {
        const s = Math.max(0, Math.floor(Number(sec) || 0));
        const m = Math.floor(s / 60);
        const r = s % 60;
        return String(m) + ":" + String(r).padStart(2, "0");
    }

    readonly property color _linePrimary: root.progressPaused
        ? Qt.rgba(root.dashboard.config.mutedTextColor.r, root.dashboard.config.mutedTextColor.g, root.dashboard.config.mutedTextColor.b, 0.4)
        : root.dashboard.config.mutedTextColor
    readonly property color _accentLine: root.progressPaused
        ? Qt.rgba(root.dashboard.dashboardAccent.r, root.dashboard.dashboardAccent.g, root.dashboard.dashboardAccent.b, 0.35)
        : root.dashboard.dashboardAccent

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: root.dashboard.dashboardAccent
        border.width: root.dashboard.config.overlayBorderWidth
        radius: root.dashboard.config.rounding

        Row {
            id: contentRow
            spacing: 20
            anchors.centerIn: parent

            // Column 1 — art
            Item {
                width: 176
                height: 176
                Rectangle {
                    id: artFrame
                    anchors.fill: parent
                    visible: root.hasArt
                    color: Qt.rgba(root.dashboard.config.textColor.r, root.dashboard.config.textColor.g, root.dashboard.config.textColor.b, 0.08)
                    border.width: root.dashboard.config.buttonBorderWidth
                    border.color: root.dashboard.dashboardAccent
                    radius: Math.max(0, root.dashboard.config.rounding - 2)
                    clip: true
                    Image {
                        anchors.fill: parent
                        anchors.margins: 2
                        asynchronous: true
                        source: root.hasArt ? root.dashboard.mediaArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        mipmap: true
                    }
                }
                Label {
                    anchors.centerIn: parent
                    visible: !root.hasArt
                    text: "♪"
                    color: root._linePrimary
                    font.pixelSize: root.dashboard.uiFontSize + 40
                }
            }

            // Column 2 — text / progress / controls
            Column {
                spacing: 10
                width: Math.max(200, Math.min(360, root.width > 300 ? (root.width - 220) : 320))

                // Row 1 — title (refresh top-right)
                RowLayout {
                    width: parent.width
                    spacing: 8
                    Column {
                        Layout.fillWidth: true
                        spacing: 2
                        Label {
                            text: root.dashboard.mediaInfo
                            color: root.dashboard.dashboardTextColor
                            width: parent.width
                            wrapMode: Text.WordWrap
                            font.pixelSize: root.dashboard.uiFontSize + 3
                        }
                        Label {
                            visible: root.dashboard.mediaAlbum && root.dashboard.mediaAlbum !== "-"
                            text: root.dashboard.mediaAlbum
                            color: root._linePrimary
                            width: parent.width
                            wrapMode: Text.WordWrap
                            font.pixelSize: root.dashboard.uiFontSize
                        }
                        Label {
                            text: root.dashboard.mediaState
                            color: root._linePrimary
                            font.pixelSize: Math.max(9, root.dashboard.uiFontSize - 2)
                        }
                    }
                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        color: rsh.containsMouse
                            ? Qt.rgba(root.dashboard.dashboardAccent.r, root.dashboard.dashboardAccent.g, root.dashboard.dashboardAccent.b, 0.10)
                            : "transparent"
                        border.width: root.dashboard.config.buttonBorderWidth
                        border.color: rsh.containsMouse ? root.dashboard.dashboardAccent : root.dashboard.config.overlayAccentColor
                        radius: Math.max(0, root.dashboard.dashboardSurfaceRounding - 3)
                        Label { anchors.centerIn: parent; text: "↻"; color: rsh.containsMouse ? root.dashboard.dashboardAccent : root._linePrimary; font.pixelSize: root.dashboard.uiFontSize + 6 }
                        MouseArea { id: rsh; anchors.fill: parent; hoverEnabled: true; onClicked: root.dashboard.refreshMediaState() }
                    }
                }

                // Row 2 — progress + duration
                RowLayout {
                    width: parent.width
                    spacing: 8
                    Label {
                        text: root._len > 0.01 ? root._fmtTime(root._pos) : "—"
                        color: root._linePrimary
                        font.pixelSize: root.dashboard.uiFontSize
                        Layout.preferredWidth: 52
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 8
                        color: Qt.rgba(root.dashboard.config.mutedTextColor.r, root.dashboard.config.mutedTextColor.g, root.dashboard.config.mutedTextColor.b, root.progressPaused ? 0.12 : 0.2)
                        radius: 4
                        Rectangle {
                            height: parent.height
                            width: parent.width * root._frac
                            color: root._accentLine
                            radius: 4
                            visible: root._len > 0.01
                        }
                    }
                    Label {
                        text: root._len > 0.01 ? root._fmtTime(root._len) : "—"
                        color: root._linePrimary
                        font.pixelSize: root.dashboard.uiFontSize
                        Layout.preferredWidth: 52
                        horizontalAlignment: Text.AlignRight
                    }
                }

                // Row 3 — transport
                RowLayout {
                    width: parent.width
                    spacing: 8
                    Rectangle {
                        id: prevBtn
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        color: prevArea.containsMouse
                            ? Qt.rgba(root.dashboard.dashboardAccent.r, root.dashboard.dashboardAccent.g, root.dashboard.dashboardAccent.b, 0.10)
                            : "transparent"
                        border.width: root.dashboard.config.buttonBorderWidth
                        border.color: prevArea.containsMouse ? root.dashboard.dashboardAccent : root.dashboard.config.overlayAccentColor
                        radius: Math.max(0, root.dashboard.dashboardSurfaceRounding - 3)
                        Label { anchors.centerIn: parent; text: "⏮"; color: prevArea.containsMouse ? root.dashboard.dashboardAccent : root.dashboard.dashboardTextColor; font.pixelSize: root.dashboard.uiFontSize + 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        MouseArea { id: prevArea; anchors.fill: parent; hoverEnabled: true; onClicked: root.mediaPrevProc.exec({ command: root.mediaPrevProc.command }) }
                    }
                    Rectangle {
                        id: playBtn
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        color: playArea.containsMouse
                            ? Qt.rgba(root.dashboard.dashboardAccent.r, root.dashboard.dashboardAccent.g, root.dashboard.dashboardAccent.b, 0.10)
                            : "transparent"
                        border.width: root.dashboard.config.buttonBorderWidth
                        border.color: (playArea.containsMouse || root.mediaActive) ? root.dashboard.dashboardAccent : root.dashboard.config.overlayAccentColor
                        radius: Math.max(0, root.dashboard.dashboardSurfaceRounding - 3)
                        Label { anchors.centerIn: parent; text: root.dashboard.mediaState === "Playing" ? "⏸" : "▶"; color: playArea.containsMouse ? root.dashboard.dashboardAccent : root.dashboard.dashboardTextColor; font.pixelSize: root.dashboard.uiFontSize + 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        MouseArea { id: playArea; anchors.fill: parent; hoverEnabled: true; onClicked: root.mediaToggleProc.exec({ command: root.mediaToggleProc.command }) }
                    }
                    Rectangle {
                        id: nextBtn
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        color: nextArea.containsMouse
                            ? Qt.rgba(root.dashboard.dashboardAccent.r, root.dashboard.dashboardAccent.g, root.dashboard.dashboardAccent.b, 0.10)
                            : "transparent"
                        border.width: root.dashboard.config.buttonBorderWidth
                        border.color: nextArea.containsMouse ? root.dashboard.dashboardAccent : root.dashboard.config.overlayAccentColor
                        radius: Math.max(0, root.dashboard.dashboardSurfaceRounding - 3)
                        Label { anchors.centerIn: parent; text: "⏭"; color: nextArea.containsMouse ? root.dashboard.dashboardAccent : root.dashboard.dashboardTextColor; font.pixelSize: root.dashboard.uiFontSize + 16; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        MouseArea { id: nextArea; anchors.fill: parent; hoverEnabled: true; onClicked: root.mediaNextProc.exec({ command: root.mediaNextProc.command }) }
                    }
                }

            }
        }
    }
}
