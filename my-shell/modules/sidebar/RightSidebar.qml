import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

PanelWindow {
    id: root

    required property QtObject shell
    // Not named "config": PanelWindow reserves/uses `config`; shadowing it breaks bindings (null at runtime).
    required property QtObject shellConfig
    required property var anchorScreen

    screen: root.anchorScreen
    readonly property string myName: root.anchorScreen ? String(root.anchorScreen.name) : ""

    anchors {
        top: true
        bottom: true
        right: true
    }

    color: "transparent"
    readonly property real sidebarHiddenOffset: panel.implicitWidth + 8
    property bool sidebarWindowActive: sidebarActive
    implicitWidth: sidebarWindowActive ? (panel.implicitWidth + 8) : Math.max(1, root.shellConfig.sidebarEdgeThresholdPx)
    exclusiveZone: 0

    readonly property bool sidebarActive: root.myName.length > 0 && (
        (root.shell.rightSidebarVisible && root.shell.rightSidebarAnchorName === root.myName)
        || (root.shell.rightSidebarTriggerHovered && root.shell.rightSidebarAnchorName === root.myName)
        || (root.shell.rightSidebarOverlayHovered && root.shell.rightSidebarAnchorName === root.myName)
    )
    property int targetOffset: sidebarActive ? 0 : sidebarHiddenOffset
    property int volumeValue: 50
    property bool volumeMuted: false
    property int brightnessValue: 40
    property bool suppressEdgeTrigger: false

    property real volumeVisual: 0
    property bool volumeVisualReady: false
    property real brightnessVisual: 0
    property bool brightnessVisualReady: false

    Behavior on volumeVisual {
        enabled: root.volumeVisualReady
        NumberAnimation {
            duration: 260
            easing.type: Easing.OutCubic
        }
    }

    Behavior on brightnessVisual {
        enabled: root.brightnessVisualReady
        NumberAnimation {
            duration: 260
            easing.type: Easing.OutCubic
        }
    }

    Connections {
        target: root
        function onVolumeValueChanged() {
            if (!root.volumeVisualReady)
                return;
            root.volumeVisual = Math.max(0, Math.min(100, root.volumeValue));
        }
        function onBrightnessValueChanged() {
            if (!root.brightnessVisualReady)
                return;
            root.brightnessVisual = Math.max(1, Math.min(100, root.brightnessValue));
        }
    }
    readonly property int triggerZoneHeight: Math.min(root.height, Math.max(180, Math.min(320, panel.implicitHeight)))
    readonly property string uiFontFamily: root.shellConfig.fontFamily
    readonly property int uiFontSize: root.shellConfig.fontPixelSize

    function _cssRgba(c) {
        return "rgba(" + Math.round(255 * c.r) + "," + Math.round(255 * c.g) + "," + Math.round(255 * c.b) + "," + c.a + ")";
    }

    function _flippedBars(percent, muted, accentColor) {
        const p = Math.max(0, Math.min(100, Number(percent)));
        const total = 10;
        const fillThr = (p / 100) * total;
        const inactive = Qt.rgba(root.shellConfig.textColor.r, root.shellConfig.textColor.g, root.shellConfig.textColor.b, 0.5);
        const base = root.shellConfig.textColor;
        const hi = accentColor;
        const mutedFull = Qt.color("#6b7280");
        let out = "";
        for (let i = 1; i <= total; i++) {
            const full = muted ? mutedFull : (i > Math.max(1, total - 3) ? hi : base);
            let color;
            if (fillThr <= i - 1)
                color = inactive;
            else if (fillThr >= i)
                color = full;
            else {
                const frac = fillThr - (i - 1);
                color = Qt.rgba(
                    inactive.r + (full.r - inactive.r) * frac,
                    inactive.g + (full.g - inactive.g) * frac,
                    inactive.b + (full.b - inactive.b) * frac,
                    inactive.a + (full.a - inactive.a) * frac
                );
            }
            out += "<span style=\"letter-spacing:-2px; color:" + root._cssRgba(color) + ";\">|</span>";
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

    function refreshSidebarStates() {
        if (!volGet.running)
            volGet.exec({ command: volGet.command });
        if (!briGet.running)
            briGet.exec({ command: briGet.command });
    }

    onUiFontFamilyChanged: _applyFontRecursive(root)
    onUiFontSizeChanged: _applyFontRecursive(root)
    onSidebarActiveChanged: {
        if (sidebarActive) {
            sidebarWindowActive = true;
            sidebarHideTimer.stop();
            refreshSidebarStates();
        } else if (sidebarWindowActive) {
            sidebarHideTimer.restart();
        }
    }
    Component.onCompleted: {
        root.volumeVisual = Math.max(0, Math.min(100, root.volumeValue));
        root.brightnessVisual = Math.max(1, Math.min(100, root.brightnessValue));
        root.volumeVisualReady = true;
        root.brightnessVisualReady = true;
        _applyFontRecursive(root);
        suppressEdgeTrigger = true;
        startupEdgeGuard.start();
    }

    readonly property int _cardHeight: Math.max(70, Math.min(200, root.shellConfig.sidebarSliderHeight))

    Rectangle {
        id: panel
        implicitWidth: contentCol.implicitWidth + 6
        implicitHeight: contentCol.implicitHeight + 6
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        // Translate avoids anchor+Item.x conflict (x is ignored when horizontal anchor is set).
        transform: Translate {
            x: root.targetOffset
            Behavior on x {
                enabled: root.shellConfig.uiAnimationsEnabled
                NumberAnimation {
                    duration: root.shellConfig.overlaySlideDurationMs
                    easing.type: Easing.OutCubic
                }
            }
        }
        color: root.shellConfig.sidebarBackgroundColor
        opacity: root.shellConfig.panelOpacity
        border.color: root.shellConfig.quickSidebarColor
        border.width: root.shellConfig.overlayBorderWidth
        radius: root.shellConfig.sidebarRounding

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
                    radius: root.shellConfig.sidebarRounding
                    border.width: root.shellConfig.buttonBorderWidth
                    border.color: root.shellConfig.quickSidebarColor
                    Layout.alignment: Qt.AlignHCenter
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 2
                        spacing: 0

                        Label {
                            text: "VOL"
                            color: root.shellConfig.sidebarTextColor
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 18
                            implicitHeight: Math.max(40, root._cardHeight - 22)

                            Text {
                                anchors.centerIn: parent
                                text: root._flippedBars(root.volumeVisual, root.volumeMuted, root.shellConfig.quickSidebarColor)
                                color: root.shellConfig.sidebarTextColor
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
                    radius: root.shellConfig.sidebarRounding
                    border.width: root.shellConfig.buttonBorderWidth
                    border.color: root.shellConfig.quickSidebarColor
                    Layout.alignment: Qt.AlignHCenter
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 2
                        spacing: 0

                        Label {
                            text: "BRT"
                            color: root.shellConfig.sidebarTextColor
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            implicitWidth: 18
                            implicitHeight: Math.max(40, root._cardHeight - 22)

                            Text {
                                anchors.centerIn: parent
                                text: root._flippedBars(root.brightnessVisual, false, root.shellConfig.quickSidebarColor)
                                color: root.shellConfig.sidebarTextColor
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
            if (!root.shellConfig.sidebarEnabled || root.suppressEdgeTrigger || root.sidebarActive) {
                return;
            }
            root.shell.rightSidebarAnchorName = root.myName;
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
        interval: root.shellConfig.uiAnimationsEnabled ? root.shellConfig.overlaySlideDurationMs + 20 : 1
        repeat: false
        onTriggered: {
            if (!root.sidebarActive)
                root.sidebarWindowActive = false;
        }
    }

    Timer {
        id: edgeHold
        interval: root.shellConfig.sidebarEdgeHoldMs
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
        interval: root.shellConfig.hoverReleaseMs
        repeat: false
        onTriggered: {
            if (!root.shell.rightSidebarVisible) {
                root.shell.rightSidebarTriggerHovered = false;
            }
        }
    }

    Timer {
        id: overlayReleaseTimer
        interval: root.shellConfig.hoverReleaseMs
        repeat: false
        onTriggered: {
            if (!root.shell.rightSidebarVisible) {
                root.shell.rightSidebarOverlayHovered = false;
            }
        }
    }

    Process {
        id: volGet
        command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then v=$(pactl get-sink-volume @DEFAULT_SINK@ | awk 'NR==1{last=\"\";for(i=1;i<=NF;i++)if($i ~ /%/){v=$i;gsub(/%/,\"\",v);last=v}if(last!=\"\")print last}'); m=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}'); echo \"${v:-50} ${m:-no}\"; else echo '50 no'; fi"]
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
        interval: root.shellConfig.quickSidebarPollMs
        running: root.sidebarWindowActive
        repeat: true
        triggeredOnStart: false
        onTriggered: root.refreshSidebarStates()
    }

    Timer {
        id: volRefresh
        interval: 140
        repeat: false
        onTriggered: root.refreshSidebarStates()
    }

    Timer {
        id: briRefresh
        interval: 140
        repeat: false
        onTriggered: root.refreshSidebarStates()
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
