import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Column {
    id: root

    required property QtObject host
    property int menuFontBoost: 8

    readonly property bool _hug: host.statusMenuHugWidth === true

    spacing: 6
    width: _hug ? host.sideMenuHugContentWidth : host.statusMenuContentWidth

    Item {
        id: briBarWrap
        width: parent.width
        height: Math.max(1, briBarRow.implicitHeight)
        clip: false

        readonly property int briPipeFontPx: Math.max(7, host.uiFontSize + root.menuFontBoost - 5)
        readonly property int briPipeCount: 33
        readonly property int briPipeStepPct: 3
        readonly property int briPipeGapPx: 1
        readonly property int briWheelStepPct: 1
        readonly property int briWheelBoostReferenceMs: 48
        readonly property real briWheelBoostMax: 16
        property real _lastWheelMs: 0

        property real brightnessVisual: 0
        property bool brightnessVisualReady: false

        Behavior on brightnessVisual {
            enabled: briBarWrap.brightnessVisualReady
            NumberAnimation {
                duration: 260
                easing.type: Easing.OutCubic
            }
        }

        Connections {
            target: host
            function onBrightnessPercentChanged() {
                if (!briBarWrap.brightnessVisualReady)
                    return;
                briBarWrap.brightnessVisual = Math.max(1, Math.min(100, host.brightnessPercent));
            }
        }

        Component.onCompleted: {
            briBarWrap.brightnessVisual = Math.max(1, Math.min(100, host.brightnessPercent));
            briBarWrap.brightnessVisualReady = true;
        }

        TextMetrics {
            id: briPctTm
            font.family: host.uiFontFamily
            font.pixelSize: briBarWrap.briPipeFontPx
            font.bold: true
            text: "100%"
        }

        readonly property int briPipeLineHint: Math.max(Math.ceil(briPctTm.height), briPipeFontPx + 4)

        function _briFromPipeIndex(idx0) {
            if (idx0 >= briPipeCount - 1)
                return 100;
            return Math.max(1, (idx0 + 1) * briPipeStepPct);
        }

        function _brightnessPctFromBarX(mx) {
            let lx = pipeRow.mapFromItem(briBarWrap, mx, 0).x;
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
                return 1;
            pipes.sort((a, b) => a.idx - b.idx);

            const last = pipes[pipes.length - 1];
            if (lx >= last.right)
                return 100;

            for (let p = 0; p < pipes.length; p++) {
                const it = pipes[p];
                if (lx >= it.left && lx <= it.right)
                    return _briFromPipeIndex(it.idx);
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
            return Math.min(100, Math.max(1, _briFromPipeIndex(best)));
        }

        function _pipeColor(pipeIndex1) {
            const pVis = Math.max(1, Math.min(100, briBarWrap.brightnessVisual));
            const fillThr = ((pVis - 1) / 99) * briPipeCount;
            const i = pipeIndex1;
            const dim = Qt.rgba(host.config.textColor.r, host.config.textColor.g, host.config.textColor.b, 0.45);
            if (fillThr <= i - 1)
                return dim;
            const full = i > 28 ? host.config.overlayAccentColor : host.config.textColor;
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
            id: wheelCoastTimer
            interval: 160
            repeat: false
            onTriggered: briBarWrap._lastWheelMs = 0
        }

        RowLayout {
            id: briBarRow
            width: parent.width
            spacing: 6

            Label {
                text: "BRT"
                color: host.config.textColor
                font.family: host.uiFontFamily
                font.pixelSize: briBarWrap.briPipeFontPx
                font.bold: true
                Layout.alignment: Qt.AlignVCenter
            }

            Item {
                id: pipeSlot
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                implicitWidth: 0
                implicitHeight: Math.max(briBarWrap.briPipeLineHint, pipeRow.implicitHeight)
                clip: true

                Row {
                    id: pipeRow
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: briBarWrap.briPipeGapPx

                    Repeater {
                        model: briBarWrap.briPipeCount
                        delegate: Text {
                            required property int index
                            text: "|"
                            color: briBarWrap._pipeColor(index + 1)
                            font.family: host.uiFontFamily
                            font.pixelSize: briBarWrap.briPipeFontPx
                        }
                    }
                }
            }

            Label {
                text: Math.round(Math.max(1, Math.min(100, briBarWrap.brightnessVisual))) + "%"
                color: host.config.overlayAccentColor
                font.family: host.uiFontFamily
                font.pixelSize: briBarWrap.briPipeFontPx
                font.bold: true
                horizontalAlignment: Text.AlignRight
                Layout.alignment: Qt.AlignVCenter
                Layout.minimumWidth: briPctTm.advanceWidth
                Layout.maximumWidth: briPctTm.advanceWidth
            }
        }

        MouseArea {
            z: 1
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => host.brightnessSetPercent(briBarWrap._brightnessPctFromBarX(mouse.x))
            onWheel: wheel => {
                const y = wheel.angleDelta.y;
                if (y === 0)
                    return;
                wheelCoastTimer.restart();
                const now = Date.now();
                const dt = briBarWrap._lastWheelMs > 0 ? Math.max(12, now - briBarWrap._lastWheelMs) : 120;
                briBarWrap._lastWheelMs = now;
                const boost = Math.min(briBarWrap.briWheelBoostMax, Math.max(1, briBarWrap.briWheelBoostReferenceMs / dt));
                let delta = Math.round(y / 120 * briBarWrap.briWheelStepPct * boost);
                if (delta === 0)
                    delta = y > 0 ? 1 : -1;
                host.brightnessStep(delta);
                wheel.accepted = true;
            }
        }
    }

    Row {
        spacing: 6
        MenuButton { host: root.host; buttonImplicitWidth: 26; buttonImplicitHeight: 24; labelText: "-"; onClicked: host.brightnessStep(-5) }
        MenuButton { host: root.host; buttonImplicitWidth: 26; buttonImplicitHeight: 24; labelText: "+"; onClicked: host.brightnessStep(5) }
    }
}
