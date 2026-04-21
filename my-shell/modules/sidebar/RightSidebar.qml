import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

PanelWindow {
    id: root

    required property QtObject shell
    required property QtObject config

    anchors {
        top: true
        bottom: true
        right: true
    }

    color: "transparent"
    readonly property real sidebarHiddenOffset: panel.implicitWidth + 8
    property bool sidebarWindowActive: sidebarActive
    implicitWidth: sidebarWindowActive ? (panel.implicitWidth + 8) : Math.max(1, root.config.sidebarEdgeThresholdPx)
    exclusiveZone: 0

    readonly property bool sidebarActive: root.shell.rightSidebarVisible || root.shell.rightSidebarTriggerHovered || root.shell.rightSidebarOverlayHovered
    property int targetOffset: sidebarActive ? 0 : sidebarHiddenOffset
    property int volumeValue: 50
    property bool volumeMuted: false
    property int brightnessValue: 40
    property bool suppressEdgeTrigger: false
    readonly property int triggerZoneHeight: Math.min(root.height, Math.max(180, Math.min(320, panel.implicitHeight)))
    readonly property string uiFontFamily: root.config.fontFamily
    readonly property int uiFontSize: root.config.fontPixelSize

    function _flippedBars(percent, muted, accentColor) {
        const p = Math.max(0, Math.min(100, Number(percent)));
        const total = 10;
        const on = Math.round((p / 100) * total);
        const inactive = Qt.rgba(root.config.textColor.r, root.config.textColor.g, root.config.textColor.b, 0.5);
        let out = "";
        for (let i = 1; i <= total; i++) {
            const active = i <= on;
            let color = inactive;
            if (active) {
                if (muted)
                    color = "#6b7280";
                else
                    color = i > Math.max(1, total - 3) ? accentColor : root.config.textColor;
            }
            out += "<span style=\"letter-spacing:-2px; color:" + color + ";\">|</span>";
        }
        return out;
    }

    function _setLocalVolume(percent) {
        volumeValue = Math.max(0, Math.min(100, Math.round(percent)));
        volInteractionLock.restart();
    }

    function _setLocalBrightness(percent) {
        brightnessValue = Math.max(1, Math.min(100, Math.round(percent)));
        briInteractionLock.restart();
    }

    function _applyFontRecursive(node) {
        if (!node)
            return;
        try {
            if (node.font !== undefined) {
                node.font.family = root.uiFontFamily;
                node.font.pixelSize = root.uiFontSize;
            }
        } catch (e) {}
        const kids = node.children || [];
        for (let i = 0; i < kids.length; i++)
            _applyFontRecursive(kids[i]);
        if (node.contentItem)
            _applyFontRecursive(node.contentItem);
    }

    onUiFontFamilyChanged: _applyFontRecursive(root)
    onUiFontSizeChanged: _applyFontRecursive(root)
    onSidebarActiveChanged: {
        if (sidebarActive) {
            sidebarWindowActive = true;
            sidebarHideTimer.stop();
        } else if (sidebarWindowActive) {
            sidebarHideTimer.restart();
        }
    }
    Component.onCompleted: {
        _applyFontRecursive(root);
        suppressEdgeTrigger = true;
        startupEdgeGuard.start();
    }

    readonly property int _cardHeight: Math.max(70, Math.min(200, root.config.sidebarSliderHeight))

    Rectangle {
        id: panel
        implicitWidth: contentCol.implicitWidth + 6
        implicitHeight: contentCol.implicitHeight + 6
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        x: root.targetOffset
        color: root.config.sidebarBackgroundColor
        opacity: root.config.panelOpacity
        border.color: root.config.quickSidebarColor
        border.width: root.config.overlayBorderWidth
        radius: root.config.sidebarRounding

        Behavior on x {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 2
            spacing: 0

            ColumnLayout {
                spacing: 6
                Layout.alignment: Qt.AlignHCenter

                Rectangle {
                    implicitWidth: 40
                    implicitHeight: root._cardHeight
                    color: "transparent"
                    radius: root.config.sidebarRounding
                    border.width: root.config.buttonBorderWidth
                    border.color: root.config.quickSidebarColor
                    Layout.alignment: Qt.AlignHCenter
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 2
                        spacing: 0

                        Label {
                            text: "VOL"
                            color: root.config.sidebarTextColor
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 18
                            implicitHeight: Math.max(40, root._cardHeight - 22)

                            Text {
                                anchors.centerIn: parent
                                text: root._flippedBars(root.volumeValue, root.volumeMuted, root.config.quickSidebarColor)
                                color: root.config.sidebarTextColor
                                textFormat: Text.RichText
                                rotation: -90
                                transformOrigin: Item.Center
                                renderType: Text.NativeRendering
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.AllButtons
                        hoverEnabled: true
                        onClicked: mouse => {
                            const ratio = 1 - Math.max(0, Math.min(1, mouse.y / Math.max(1, parent.height)));
                            const pct = Math.round(ratio * 100);
                            root._setLocalVolume(pct);
                            volSet.exec({ command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then pactl set-sink-volume @DEFAULT_SINK@ " + pct + "%; fi"] });
                            volRefresh.start();
                        }
                        onWheel: wheel => {
                            const delta = wheel.angleDelta.y > 0 ? 2 : -2;
                            root._setLocalVolume(root.volumeValue + delta);
                            volSet.exec({ command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then pactl set-sink-volume @DEFAULT_SINK@ " + root.volumeValue + "%; fi"] });
                            volRefresh.start();
                            wheel.accepted = true;
                        }
                    }
                }

                Rectangle {
                    implicitWidth: 40
                    implicitHeight: root._cardHeight
                    color: "transparent"
                    radius: root.config.sidebarRounding
                    border.width: root.config.buttonBorderWidth
                    border.color: root.config.quickSidebarColor
                    Layout.alignment: Qt.AlignHCenter
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 2
                        spacing: 0

                        Label {
                            text: "BRT"
                            color: root.config.sidebarTextColor
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 18
                            implicitHeight: Math.max(40, root._cardHeight - 22)

                            Text {
                                anchors.centerIn: parent
                                text: root._flippedBars(root.brightnessValue, false, root.config.quickSidebarColor)
                                color: root.config.sidebarTextColor
                                textFormat: Text.RichText
                                rotation: -90
                                transformOrigin: Item.Center
                                renderType: Text.NativeRendering
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.AllButtons
                        hoverEnabled: true
                        onClicked: mouse => {
                            const ratio = 1 - Math.max(0, Math.min(1, mouse.y / Math.max(1, parent.height)));
                            const pct = Math.max(1, Math.round(ratio * 100));
                            root._setLocalBrightness(pct);
                            briSet.exec({ command: ["bash", "-lc", "if command -v brightnessctl >/dev/null 2>&1; then brightnessctl set " + pct + "%; fi"] });
                            briRefresh.start();
                        }
                        onWheel: wheel => {
                            const delta = wheel.angleDelta.y > 0 ? 2 : -2;
                            root._setLocalBrightness(root.brightnessValue + delta);
                            briSet.exec({ command: ["bash", "-lc", "if command -v brightnessctl >/dev/null 2>&1; then brightnessctl set " + root.brightnessValue + "%; fi"] });
                            briRefresh.start();
                            wheel.accepted = true;
                        }
                    }
                }
            }
        }

        HoverHandler {
            onHoveredChanged: {
                if (hovered) {
                    overlayReleaseTimer.stop();
                    root.shell.rightSidebarOverlayHovered = true;
                } else {
                    overlayReleaseTimer.start();
                }
            }
        }
    }

    MouseArea {
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        width: parent.width
        height: root.triggerZoneHeight
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onEntered: {
            if (!root.config.sidebarEnabled || root.suppressEdgeTrigger || root.sidebarActive) {
                return;
            }
            edgeHold.start();
        }
        onExited: {
            edgeHold.stop();
            if (root.shell.rightSidebarTriggerHovered && !root.shell.rightSidebarVisible) {
                triggerReleaseTimer.start();
            }
        }
        onPositionChanged: {
            // Intentionally left empty: enter/exit timers drive trigger behavior.
        }
    }

    Timer {
        id: sidebarHideTimer
        interval: 170
        repeat: false
        onTriggered: {
            if (!root.sidebarActive)
                root.sidebarWindowActive = false;
        }
    }

    Timer {
        id: edgeHold
        interval: root.config.sidebarEdgeHoldMs
        repeat: false
        onTriggered: root.shell.rightSidebarTriggerHovered = true
    }

    Timer {
        id: edgeSuppressRestart
        interval: 450
        repeat: false
        onTriggered: root.suppressEdgeTrigger = false
    }

    Timer {
        id: startupEdgeGuard
        interval: 700
        repeat: false
        onTriggered: root.suppressEdgeTrigger = false
    }

    Timer {
        id: triggerReleaseTimer
        interval: root.config.hoverReleaseMs
        repeat: false
        onTriggered: {
            if (!root.shell.rightSidebarVisible) {
                root.shell.rightSidebarTriggerHovered = false;
            }
        }
    }

    Timer {
        id: overlayReleaseTimer
        interval: root.config.hoverReleaseMs
        repeat: false
        onTriggered: {
            if (!root.shell.rightSidebarVisible) {
                root.shell.rightSidebarOverlayHovered = false;
            }
        }
    }

    Process {
        id: volGet
        command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then v=$(pactl get-sink-volume @DEFAULT_SINK@ | awk '{print $5}' | tr -d '%' | head -n1); m=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}'); echo \"${v:-50} ${m:-no}\"; else echo '50 no'; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (volInteractionLock.running)
                    return;
                const parts = String(text).trim().split(/\s+/);
                root.volumeValue = Number(parts[0] || "50") || root.volumeValue;
                root.volumeMuted = String(parts[1] || "no") === "yes";
            }
        }
    }

    Process {
        id: briGet
        command: ["bash", "-lc", "if command -v brightnessctl >/dev/null 2>&1; then brightnessctl -m | awk -F, '{gsub(\"%\",\"\",$4); print $4}'; else echo '40'; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (briInteractionLock.running)
                    return;
                root.brightnessValue = Number(String(text).trim()) || root.brightnessValue;
            }
        }
    }

    Process {
        id: volSet
    }

    Process {
        id: briSet
    }

    Timer {
        interval: root.config.quickSidebarPollMs
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            volGet.exec({ command: volGet.command });
            briGet.exec({ command: briGet.command });
        }
    }

    Timer {
        id: volRefresh
        interval: 140
        repeat: false
        onTriggered: volGet.exec({ command: volGet.command })
    }

    Timer {
        id: briRefresh
        interval: 140
        repeat: false
        onTriggered: briGet.exec({ command: briGet.command })
    }

    Timer {
        id: volInteractionLock
        interval: 320
        repeat: false
    }

    Timer {
        id: briInteractionLock
        interval: 320
        repeat: false
    }
}
