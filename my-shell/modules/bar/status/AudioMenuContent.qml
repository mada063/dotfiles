import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Column {
    id: root

    required property QtObject host
    property int outputListHeight: 110
    property int inputListHeight: 96
    property int menuFontBoost: 8
    property bool showMixer: false

    readonly property bool _hug: host.statusMenuHugWidth === true

    spacing: 6
    width: _hug ? host.sideMenuHugContentWidth : host.statusMenuContentWidth

    Item {
        id: volBarWrap
        width: parent.width
        height: Math.max(1, volBarRow.implicitHeight)
        clip: false

        readonly property int volPipeFontPx: Math.max(7, host.uiFontSize + root.menuFontBoost - 5)
        readonly property int volPipeCount: 33
        readonly property int volPipeStepPct: 3
        readonly property int volPipeGapPx: 1
        readonly property int volWheelStepPct: 1
        /// Shorter dt between wheel events ⇒ larger multiplier (capped).
        readonly property int volWheelBoostReferenceMs: 48
        readonly property real volWheelBoostMax: 16
        property real _lastWheelMs: 0

        /// Smoothly follows host.volumePercent so the bar visibly sweeps when scrolling.
        property real volumeVisual: 0
        property bool volumeVisualReady: false

        Behavior on volumeVisual {
            enabled: volBarWrap.volumeVisualReady
            NumberAnimation {
                duration: 260
                easing.type: Easing.OutCubic
            }
        }

        Connections {
            target: host
            function onVolumePercentChanged() {
                if (!volBarWrap.volumeVisualReady)
                    return;
                volBarWrap.volumeVisual = Math.max(0, Math.min(100, host.volumePercent));
            }
        }

        Component.onCompleted: {
            volBarWrap.volumeVisual = Math.max(0, Math.min(100, host.volumePercent));
            volBarWrap.volumeVisualReady = true;
        }

        TextMetrics {
            id: volPctTm
            font.family: host.uiFontFamily
            font.pixelSize: volBarWrap.volPipeFontPx
            font.bold: true
            text: "100%"
        }

        /// Stable before Repeater pipes exist — avoids implicitHeight 0→N jump that reflows the menu over the border.
        readonly property int volPipeLineHint: Math.max(Math.ceil(volPctTm.height), volPipeFontPx + 4)

        /// Pipe k (1…33): steps of 3% (3…99); last pipe snaps to 100%.
        function _volFromPipeIndex(idx0) {
            if (idx0 >= volPipeCount - 1)
                return 100;
            return (idx0 + 1) * volPipeStepPct;
        }

        function _volumePctFromBarX(mx) {
            let lx = pipeRow.mapFromItem(volBarWrap, mx, 0).x;
            const wRow = Math.max(1, pipeRow.width);
            lx = Math.max(0, Math.min(wRow, lx));

            const pipes = [];
            for (let i = 0; i < pipeRow.children.length; i++) {
                const ch = pipeRow.children[i];
                if (!ch || typeof ch.index !== "number")
                    continue;
                pipes.push({
                    idx: ch.index,
                    left: ch.x,
                    right: ch.x + ch.width,
                    cx: ch.x + ch.width / 2
                });
            }
            if (pipes.length === 0)
                return 0;
            pipes.sort((a, b) => a.idx - b.idx);

            const last = pipes[pipes.length - 1];
            if (lx >= last.right)
                return 100;

            for (let p = 0; p < pipes.length; p++) {
                const it = pipes[p];
                if (lx >= it.left && lx <= it.right)
                    return _volFromPipeIndex(it.idx);
            }

            let best = 0;
            let bestD = 1e18;
            for (let p = 0; p < pipes.length; p++) {
                const it = pipes[p];
                const d = Math.abs(lx - it.cx);
                if (d < bestD) {
                    bestD = d;
                    best = it.idx;
                }
            }
            return Math.min(100, _volFromPipeIndex(best));
        }

        function _pipeColor(pipeIndex1) {
            const i = pipeIndex1;
            if (host.volumeMuted)
                return "#6b7280";
            const pVis = Math.max(0, Math.min(100, volBarWrap.volumeVisual));
            const fillThr = (pVis / 100) * volPipeCount;
            const dim = Qt.rgba(host.config.textColor.r, host.config.textColor.g, host.config.textColor.b, 0.45);
            if (fillThr <= i - 1)
                return dim;
            const full = i > 28 ? host.config.volumeColor : host.config.textColor;
            if (fillThr >= i)
                return full;
            const frac = fillThr - (i - 1);
            return Qt.rgba(
                dim.r + (full.r - dim.r) * frac,
                dim.g + (full.g - dim.g) * frac,
                dim.b + (full.b - dim.b) * frac,
                dim.a + (full.a - dim.a) * frac
            );
        }

        Timer {
            id: barSingleClickTimer
            interval: 220
            repeat: false
            property real pendingX: 0
            onTriggered: host.audioSetVolumePercent(volBarWrap._volumePctFromBarX(pendingX))
        }

        Timer {
            id: wheelCoastTimer
            interval: 160
            repeat: false
            onTriggered: volBarWrap._lastWheelMs = 0
        }

        RowLayout {
            id: volBarRow
            width: parent.width
            spacing: 6

            Label {
                text: "VOL"
                color: host.config.textColor
                font.family: host.uiFontFamily
                font.pixelSize: volBarWrap.volPipeFontPx
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
            }

            Item {
                id: pipeSlot
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                implicitWidth: 0
                implicitHeight: Math.max(volBarWrap.volPipeLineHint, pipeRow.implicitHeight)
                clip: true

                Row {
                    id: pipeRow
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: volBarWrap.volPipeGapPx

                    Repeater {
                        model: volBarWrap.volPipeCount
                        delegate: Text {
                            required property int index
                            text: "|"
                            color: volBarWrap._pipeColor(index + 1)
                            font.family: host.uiFontFamily
                            font.pixelSize: volBarWrap.volPipeFontPx
                        }
                    }
                }
            }

            Label {
                text: Math.round(Math.max(0, Math.min(100, volBarWrap.volumeVisual))) + "%"
                color: host.volumeMuted ? host.config.mutedTextColor : host.config.overlayAccentColor
                font.family: host.uiFontFamily
                font.pixelSize: volBarWrap.volPipeFontPx
                font.bold: true
                horizontalAlignment: Text.AlignRight
                Layout.alignment: Qt.AlignVCenter
                Layout.minimumWidth: volPctTm.advanceWidth
                Layout.maximumWidth: volPctTm.advanceWidth
            }
        }

        MouseArea {
            z: 1
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (barSingleClickTimer.running) {
                    barSingleClickTimer.stop();
                    host.audioToggleMute();
                } else {
                    barSingleClickTimer.pendingX = mouse.x;
                    barSingleClickTimer.restart();
                }
            }
            onWheel: wheel => {
                const y = wheel.angleDelta.y;
                if (y === 0)
                    return;
                wheelCoastTimer.restart();
                const now = Date.now();
                const dt = volBarWrap._lastWheelMs > 0 ? Math.max(12, now - volBarWrap._lastWheelMs) : 120;
                volBarWrap._lastWheelMs = now;
                const boost = Math.min(volBarWrap.volWheelBoostMax, Math.max(1, volBarWrap.volWheelBoostReferenceMs / dt));
                let delta = Math.round(y / 120 * volBarWrap.volWheelStepPct * boost);
                if (delta === 0)
                    delta = y > 0 ? 1 : -1;
                host.audioStep(delta);
                wheel.accepted = true;
            }
        }
    }

    Row {
        spacing: 6
        MenuButton { host: root.host; buttonImplicitWidth: 26; buttonImplicitHeight: 24; labelText: "-"; onClicked: host.audioStep(-5) }
        MenuButton { host: root.host; buttonImplicitWidth: 26; buttonImplicitHeight: 24; labelText: "+"; onClicked: host.audioStep(5) }
        MenuButton { host: root.host; buttonImplicitWidth: 56; buttonImplicitHeight: 24; labelText: host.config.formatUiText("Mute"); onClicked: host.audioToggleMute() }
        MenuButton { visible: root.showMixer; host: root.host; buttonImplicitWidth: 56; buttonImplicitHeight: 24; labelText: host.config.formatUiText("Mixer"); onClicked: host.audioOpenMixer() }
    }

    MenuSectionLabel { text: host.config.formatUiText("Output devices"); host: root.host }
    ScrollView {
        width: parent.width
        height: root.outputListHeight
        clip: true
        ListView {
            model: host.audioOutputs
            spacing: 4
            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width - 8
                height: 38
                radius: Math.max(0, host.config.rounding - 3)
                color: modelData.default
                    ? Qt.rgba(host.config.overlayAccentColor.r, host.config.overlayAccentColor.g, host.config.overlayAccentColor.b, 0.12)
                    : (_outRowHover.hovered ? Qt.rgba(host.config.overlayAccentColor.r, host.config.overlayAccentColor.g, host.config.overlayAccentColor.b, 0.10) : "transparent")
                border.width: host.config.buttonBorderWidth
                border.color: (modelData.default || _outRowHover.hovered) ? host.config.overlayAccentColor : host.config.mutedTextColor

                HoverHandler { id: _outRowHover }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 8
                    Label { text: modelData.description; color: _outRowHover.hovered ? host.config.overlayAccentColor : host.config.textColor; Layout.fillWidth: true; elide: Text.ElideRight }
                    MenuButton {
                        host: root.host
                        buttonImplicitWidth: modelData.default ? 64 : 72
                        buttonImplicitHeight: 22
                        labelText: modelData.default ? "Default" : "Use"
                        buttonEnabled: !modelData.default
                        onClicked: host.setDefaultAudioSink(modelData.name)
                    }
                }
            }
        }
    }

    MenuSectionLabel { text: host.config.formatUiText("Input devices"); host: root.host }
    ScrollView {
        width: parent.width
        height: root.inputListHeight
        clip: true
        ListView {
            model: host.audioInputs
            spacing: 4
            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width - 8
                height: 38
                radius: Math.max(0, host.config.rounding - 3)
                color: modelData.default
                    ? Qt.rgba(host.config.overlayAccentColor.r, host.config.overlayAccentColor.g, host.config.overlayAccentColor.b, 0.12)
                    : (_inRowHover.hovered ? Qt.rgba(host.config.overlayAccentColor.r, host.config.overlayAccentColor.g, host.config.overlayAccentColor.b, 0.10) : "transparent")
                border.width: host.config.buttonBorderWidth
                border.color: (modelData.default || _inRowHover.hovered) ? host.config.overlayAccentColor : host.config.mutedTextColor

                HoverHandler { id: _inRowHover }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 8
                    Label { text: modelData.description; color: _inRowHover.hovered ? host.config.overlayAccentColor : host.config.textColor; Layout.fillWidth: true; elide: Text.ElideRight }
                    MenuButton {
                        host: root.host
                        buttonImplicitWidth: modelData.default ? 64 : 72
                        buttonImplicitHeight: 22
                        labelText: modelData.default ? "Default" : "Use"
                        buttonEnabled: !modelData.default
                        onClicked: host.setDefaultAudioSource(modelData.name)
                    }
                }
            }
        }
    }
}
