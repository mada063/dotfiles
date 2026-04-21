import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Common.js" as Common

ScrollView {
    id: root

    required property QtObject control
    property int selectedMonitorIndex: -1
    property real snapThresholdPx: 28
    property bool snapGuideVerticalVisible: false
    property bool snapGuideHorizontalVisible: false
    property real snapGuideX: 0
    property real snapGuideY: 0

    clip: true

    function _copy(value) { return Common.deepCopy(value); }

    function _updateMonitor(index, key, value) {
        let next = _copy(root.control.config.hyprlandMonitors || []);
        if (!next[index])
            next[index] = {};
        next[index][key] = value;
        root.control.config.hyprlandMonitors = next;
    }

    function _updateMonitorPatch(index, patch) {
        let next = _copy(root.control.config.hyprlandMonitors || []);
        if (!next[index])
            next[index] = {};
        Object.assign(next[index], patch || {});
        root.control.config.hyprlandMonitors = next;
    }

    function _selectMonitor(index) { selectedMonitorIndex = index; }

    function _selectedMonitor() {
        const monitors = root.control.config.hyprlandMonitors || [];
        if (selectedMonitorIndex < 0 || selectedMonitorIndex >= monitors.length)
            return null;
        return monitors[selectedMonitorIndex];
    }

    function _syncSelection() {
        const monitors = root.control.config.hyprlandMonitors || [];
        if (monitors.length < 1) { selectedMonitorIndex = -1; return; }
        if (selectedMonitorIndex >= 0 && selectedMonitorIndex < monitors.length)
            return;
        selectedMonitorIndex = 0;
    }

    function _nudgeSelected(dx, dy) {
        if (selectedMonitorIndex < 0) return;
        const monitor = _selectedMonitor();
        if (!monitor) return;
        _updateMonitor(selectedMonitorIndex, "positionX", (Number(monitor.positionX) || 0) + dx);
        _updateMonitor(selectedMonitorIndex, "positionY", (Number(monitor.positionY) || 0) + dy);
    }

    function _resetSelectedPosition() {
        if (selectedMonitorIndex < 0) return;
        _updateMonitor(selectedMonitorIndex, "positionX", 0);
        _updateMonitor(selectedMonitorIndex, "positionY", 0);
    }

    function _stackEnabledMonitors(horizontal) {
        let next = _copy(root.control.config.hyprlandMonitors || []);
        let cursor = 0;
        for (let i = 0; i < next.length; i++) {
            const monitor = next[i];
            if (!monitor || monitor.enabled === false) continue;
            const scale = Math.max(0.5, Number(monitor.scale) || 1);
            const width = _modeWidth(monitor.mode) / scale;
            const height = _modeHeight(monitor.mode) / scale;
            monitor.positionX = horizontal ? Math.round(cursor) : 0;
            monitor.positionY = horizontal ? 0 : Math.round(cursor);
            cursor += horizontal ? width : height;
        }
        root.control.config.hyprlandMonitors = next;
    }

    function _modeWidth(modeText) {
        const match = String(modeText || "").match(/(\d+)x(\d+)/);
        return match ? Math.max(320, Number(match[1]) || 0) : 1920;
    }

    function _modeHeight(modeText) {
        const match = String(modeText || "").match(/(\d+)x(\d+)/);
        return match ? Math.max(200, Number(match[2]) || 0) : 1080;
    }

    function _monitorRect(monitor, sourceIndex, fallbackName) {
        const safeMonitor = monitor || {};
        const scale = Math.max(0.5, Number(safeMonitor.scale) || 1);
        const width = _modeWidth(safeMonitor.mode) / scale;
        const height = _modeHeight(safeMonitor.mode) / scale;
        const x = Number(safeMonitor.positionX) || 0;
        const y = Number(safeMonitor.positionY) || 0;
        return {
            sourceIndex: sourceIndex,
            name: String(safeMonitor.name || fallbackName || "Monitor"),
            mode: String(safeMonitor.mode || "preferred"),
            scale: scale,
            x: x, y: y, width: width, height: height,
            left: x, right: x + width,
            top: y, bottom: y + height,
            centerX: x + width / 2, centerY: y + height / 2
        };
    }

    function _enabledMonitorRects(includePlaceholder) {
        const monitors = root.control.config.hyprlandMonitors || [];
        let rects = [];
        for (let i = 0; i < monitors.length; i++) {
            const monitor = monitors[i];
            if (monitor && monitor.enabled !== false)
                rects.push(_monitorRect(monitor, i, "Monitor " + (i + 1)));
        }
        if (rects.length < 1 && includePlaceholder)
            rects.push(_monitorRect({ name: "Display", mode: "1920x1080", positionX: 0, positionY: 0, scale: 1 }, -1, "Display"));
        return rects;
    }

    function _previewBounds(rects) {
        if (!rects || rects.length < 1)
            return { minX: 0, minY: 0, maxX: 1920, maxY: 1080, width: 1920, height: 1080 };
        let minX = Infinity, minY = Infinity, maxX = -Infinity, maxY = -Infinity;
        for (let i = 0; i < rects.length; i++) {
            const rect = rects[i];
            minX = Math.min(minX, rect.left); minY = Math.min(minY, rect.top);
            maxX = Math.max(maxX, rect.right); maxY = Math.max(maxY, rect.bottom);
        }
        return { minX: minX, minY: minY, maxX: maxX, maxY: maxY,
                 width: Math.max(1, maxX - minX), height: Math.max(1, maxY - minY) };
    }

    function _bestSnapDelta(candidateValues, targetValues) {
        let bestDelta = null, bestGuide = 0;
        for (let i = 0; i < candidateValues.length; i++) {
            for (let j = 0; j < targetValues.length; j++) {
                const delta = Number(targetValues[j]) - Number(candidateValues[i]);
                if (Math.abs(delta) > root.snapThresholdPx) continue;
                if (bestDelta === null || Math.abs(delta) < Math.abs(bestDelta)) {
                    bestDelta = delta; bestGuide = Number(targetValues[j]);
                }
            }
        }
        return { snapped: bestDelta !== null, delta: bestDelta === null ? 0 : bestDelta, guide: bestGuide };
    }

    function _snapMonitorPosition(sourceIndex, candidateX, candidateY) {
        const monitors = root.control.config.hyprlandMonitors || [];
        const draggedRect = _monitorRect(monitors[sourceIndex], sourceIndex, "Monitor " + (sourceIndex + 1));
        const xCandidates = [candidateX, candidateX + draggedRect.width, candidateX + draggedRect.width / 2];
        const yCandidates = [candidateY, candidateY + draggedRect.height, candidateY + draggedRect.height / 2];
        const otherRects = _enabledMonitorRects(false).filter(rect => rect.sourceIndex !== sourceIndex);
        let targetX = candidateX, targetY = candidateY;
        let verticalGuide = null, horizontalGuide = null;
        if (otherRects.length > 0) {
            let targetXs = [], targetYs = [];
            for (let i = 0; i < otherRects.length; i++) {
                const rect = otherRects[i];
                targetXs.push(rect.left, rect.right, rect.centerX);
                targetYs.push(rect.top, rect.bottom, rect.centerY);
            }
            const xSnap = _bestSnapDelta(xCandidates, targetXs);
            const ySnap = _bestSnapDelta(yCandidates, targetYs);
            if (xSnap.snapped) { targetX += xSnap.delta; verticalGuide = xSnap.guide; }
            if (ySnap.snapped) { targetY += ySnap.delta; horizontalGuide = ySnap.guide; }
        }
        let guideRects = _enabledMonitorRects(false).filter(rect => rect.sourceIndex !== sourceIndex);
        guideRects.push({ left: targetX, top: targetY, right: targetX + draggedRect.width, bottom: targetY + draggedRect.height });
        const bounds = _previewBounds(guideRects);
        const scale = Math.min(
            Math.max(0.0001, (previewCanvas.width - 20) / Math.max(1, bounds.width)),
            Math.max(0.0001, (previewCanvas.height - 20) / Math.max(1, bounds.height))
        );
        return {
            x: Math.round(targetX), y: Math.round(targetY),
            verticalGuideVisible: verticalGuide !== null,
            horizontalGuideVisible: horizontalGuide !== null,
            verticalGuideX: verticalGuide === null ? 0 : 10 + (verticalGuide - bounds.minX) * scale,
            horizontalGuideY: horizontalGuide === null ? 0 : 10 + (horizontalGuide - bounds.minY) * scale
        };
    }

    function _hideSnapGuide() {
        root.snapGuideVerticalVisible = false;
        root.snapGuideHorizontalVisible = false;
    }

    function _showSnapGuide(result, keepVisible) {
        root.snapGuideVerticalVisible = Boolean(result && result.verticalGuideVisible);
        root.snapGuideHorizontalVisible = Boolean(result && result.horizontalGuideVisible);
        root.snapGuideX = result ? Number(result.verticalGuideX || 0) : 0;
        root.snapGuideY = result ? Number(result.horizontalGuideY || 0) : 0;
        if (keepVisible) snapGuideTimer.stop();
        else if (root.snapGuideVerticalVisible || root.snapGuideHorizontalVisible) snapGuideTimer.restart();
    }

    function _previewMonitors() {
        const rects = _enabledMonitorRects(true);
        const bounds = _previewBounds(rects);
        let mapped = [];
        for (let i = 0; i < rects.length; i++) {
            const item = rects[i];
            mapped.push({
                sourceIndex: item.sourceIndex, name: item.name,
                actualX: item.x, actualY: item.y,
                x: item.x - bounds.minX, y: item.y - bounds.minY,
                width: item.width, height: item.height,
                boundsWidth: bounds.width, boundsHeight: bounds.height,
                mode: item.mode, scale: item.scale
            });
        }
        return mapped;
    }

    Timer {
        id: snapGuideTimer
        interval: 850
        repeat: false
        onTriggered: root._hideSnapGuide()
    }

    Connections {
        target: root.control.config
        function onHyprlandMonitorsChanged() { root._syncSelection(); }
    }

    Component.onCompleted: _syncSelection()

    ColumnLayout {
        width: parent.width
        spacing: 0

        // ── Shell ──────────────────────────────────────────────────────

        Label { text: "Screen"; color: root.control.config.accentColor; font.bold: true; Layout.bottomMargin: 10 }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: "Bar Orientation"; color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            ComboBox {
                Layout.preferredWidth: 110
                model: ["top", "left"]
                currentIndex: model.indexOf(root.control.config.barOrientation)
                onActivated: root.control.config.barOrientation = currentText
            }
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            Layout.bottomMargin: 16
            StyledCheckBox {
                text: "Show left logo / title"
                control: root.control
                checked: root.control.config.showShellTitle
                onToggled: root.control.config.showShellTitle = checked
            }
            Item { Layout.fillWidth: true }
        }

        // ── Layout Preview ────────────────────────────────────────────

        Label { text: "Layout Preview"; color: root.control.config.accentColor; font.bold: true; Layout.bottomMargin: 4 }

        Label {
            text: "Click to select a monitor. Drag to reposition. Snap guides appear near edges."
            color: root.control.config.mutedTextColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.bottomMargin: 8
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 6
            spacing: 6

            Label {
                Layout.fillWidth: true
                text: root._selectedMonitor()
                    ? "Selected: " + String(root._selectedMonitor().name || ("Monitor " + (root.selectedMonitorIndex + 1)))
                        + "  (" + (Number(root._selectedMonitor().positionX) || 0) + ", " + (Number(root._selectedMonitor().positionY) || 0) + ")"
                    : "No monitor selected."
                color: root.control.config.textColor
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }

            Button { text: "Stack Row";    onClicked: root._stackEnabledMonitors(true) }
            Button { text: "Stack Column"; onClicked: root._stackEnabledMonitors(false) }
            Button { text: "Reset";        enabled: root.selectedMonitorIndex >= 0; onClicked: root._resetSelectedPosition() }
        }

        // Interactive drag canvas
        Item {
            id: previewCanvas
            Layout.fillWidth: true
            implicitHeight: 210
            Layout.bottomMargin: 6

            Rectangle {
                anchors.fill: parent
                radius: root.control.config.rounding
                color: Qt.rgba(0, 0, 0, 0.08)
                border.width: root.control.config.overlayBorderWidth
                border.color: root.control.config.mutedTextColor
            }

            Repeater {
                model: root._previewMonitors()
                delegate: Rectangle {
                    id: previewDisplay
                    required property var modelData
                    property var liveSnapResult: null
                    readonly property real scaleFactor: Math.min(
                        (parent.width - 20) / Math.max(1, modelData.boundsWidth),
                        (parent.height - 20) / Math.max(1, modelData.boundsHeight)
                    )
                    property real dragOffsetX: dragHandler.active ? dragHandler.translation.x : 0
                    property real dragOffsetY: dragHandler.active ? dragHandler.translation.y : 0
                    x: 10 + modelData.x * scaleFactor
                        + (dragHandler.active && liveSnapResult
                            ? (liveSnapResult.x - modelData.actualX) * scaleFactor
                            : dragOffsetX)
                    y: 10 + modelData.y * scaleFactor
                        + (dragHandler.active && liveSnapResult
                            ? (liveSnapResult.y - modelData.actualY) * scaleFactor
                            : dragOffsetY)
                    width:  Math.max(44, modelData.width  * scaleFactor)
                    height: Math.max(28, modelData.height * scaleFactor)
                    radius: Math.max(0, root.control.config.rounding - 2)
                    color: root.selectedMonitorIndex === modelData.sourceIndex
                        ? Qt.rgba(root.control.config.accentColor.r, root.control.config.accentColor.g, root.control.config.accentColor.b, 0.15)
                        : root.control.config.backgroundColor
                    border.width: root.control.config.buttonBorderWidth + (root.selectedMonitorIndex === modelData.sourceIndex ? 1 : 0)
                    border.color: root.selectedMonitorIndex === modelData.sourceIndex
                        ? root.control.config.accentColor : root.control.config.mutedTextColor

                    DragHandler {
                        id: dragHandler
                        target: null
                        onTranslationChanged: {
                            if (!active || previewDisplay.modelData.sourceIndex < 0) return;
                            const result = root._snapMonitorPosition(
                                previewDisplay.modelData.sourceIndex,
                                previewDisplay.modelData.actualX + (translation.x / Math.max(0.0001, previewDisplay.scaleFactor)),
                                previewDisplay.modelData.actualY + (translation.y / Math.max(0.0001, previewDisplay.scaleFactor))
                            );
                            previewDisplay.liveSnapResult = result;
                            root._showSnapGuide(result, true);
                        }
                        onActiveChanged: {
                            if (active && previewDisplay.modelData.sourceIndex >= 0) {
                                root._selectMonitor(previewDisplay.modelData.sourceIndex);
                                previewDisplay.liveSnapResult = root._snapMonitorPosition(
                                    previewDisplay.modelData.sourceIndex,
                                    previewDisplay.modelData.actualX, previewDisplay.modelData.actualY
                                );
                            } else if (previewDisplay.modelData.sourceIndex >= 0) {
                                const result = previewDisplay.liveSnapResult || root._snapMonitorPosition(
                                    previewDisplay.modelData.sourceIndex,
                                    previewDisplay.modelData.actualX + (translation.x / Math.max(0.0001, previewDisplay.scaleFactor)),
                                    previewDisplay.modelData.actualY + (translation.y / Math.max(0.0001, previewDisplay.scaleFactor))
                                );
                                root._updateMonitorPatch(previewDisplay.modelData.sourceIndex, {
                                    positionX: Math.round(result.x), positionY: Math.round(result.y)
                                });
                                previewDisplay.liveSnapResult = null;
                                root._showSnapGuide(result, false);
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: { if (parent.modelData.sourceIndex >= 0) root._selectMonitor(parent.modelData.sourceIndex); }
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top; anchors.topMargin: 6
                        text: modelData.name
                        color: root.control.config.textColor
                        font.bold: true
                        elide: Text.ElideRight
                        width: parent.width - 10
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom; anchors.bottomMargin: 6
                        text: modelData.mode + "  " + modelData.scale + "×"
                        color: root.control.config.mutedTextColor
                        font.pixelSize: Math.max(10, root.control.config.fontPixelSize - 2)
                        elide: Text.ElideRight
                        width: parent.width - 10
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

            Rectangle {
                visible: root.snapGuideVerticalVisible
                x: root.snapGuideX - Math.max(1, root.control.config.buttonBorderWidth)
                y: 10; width: Math.max(2, root.control.config.buttonBorderWidth + 1)
                height: Math.max(0, parent.height - 20); radius: width / 2
                color: root.control.config.accentColor; opacity: 0.7
            }
            Rectangle {
                visible: root.snapGuideHorizontalVisible
                x: 10; y: root.snapGuideY - Math.max(1, root.control.config.buttonBorderWidth)
                width: Math.max(0, parent.width - 20); height: Math.max(2, root.control.config.buttonBorderWidth + 1)
                radius: height / 2; color: root.control.config.accentColor; opacity: 0.7
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 20
            spacing: 6
            Button { text: "Up";    enabled: root.selectedMonitorIndex >= 0; onClicked: root._nudgeSelected(0, -50) }
            Button { text: "Left";  enabled: root.selectedMonitorIndex >= 0; onClicked: root._nudgeSelected(-50, 0) }
            Button { text: "Right"; enabled: root.selectedMonitorIndex >= 0; onClicked: root._nudgeSelected(50, 0) }
            Button { text: "Down";  enabled: root.selectedMonitorIndex >= 0; onClicked: root._nudgeSelected(0, 50) }
            Item { Layout.fillWidth: true }
            Label { text: "Nudge by 50 px"; color: root.control.config.mutedTextColor; verticalAlignment: Text.AlignVCenter }
        }

        // ── Displays ──────────────────────────────────────────────────

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 4
            Label { text: "Displays"; color: root.control.config.accentColor; font.bold: true }
            Item { Layout.fillWidth: true }
            Button { text: "Apply Now"; onClicked: root.control.shell.queueHyprlandSync() }
            Button {
                text: "Add Monitor"
                onClicked: {
                    let next = root._copy(root.control.config.hyprlandMonitors || []);
                    next.push({ name: "", mode: "preferred", positionX: 0, positionY: 0,
                                scale: 1, transform: 0, mirrorOf: "", enabled: true });
                    root.control.config.hyprlandMonitors = next;
                    root._selectMonitor(next.length - 1);
                }
            }
        }

        Label {
            text: "Written to the shell-managed Hyprland include on Apply."
            color: root.control.config.mutedTextColor
            Layout.fillWidth: true
            Layout.bottomMargin: 8
        }

        Repeater {
            model: root.control.config.hyprlandMonitors || []
            delegate: Rectangle {
                required property var modelData
                required property int index
                property bool confirmRemove: false
                implicitHeight: displayCardContent.implicitHeight + 16
                color: root.selectedMonitorIndex === index
                    ? Qt.rgba(root.control.config.accentColor.r, root.control.config.accentColor.g, root.control.config.accentColor.b, 0.08)
                    : Qt.rgba(root.control.config.accentColor.r, root.control.config.accentColor.g, root.control.config.accentColor.b, 0.03)
                border.width: root.control.config.overlayBorderWidth
                border.color: root.selectedMonitorIndex === index
                    ? root.control.config.accentColor : root.control.config.mutedTextColor
                radius: root.control.config.rounding
                Layout.fillWidth: true
                Layout.bottomMargin: 6

                TapHandler { onTapped: root._selectMonitor(index) }

                ColumnLayout {
                    id: displayCardContent
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: "Monitor " + (index + 1); color: root.control.config.textColor; font.bold: true }
                        Item { Layout.fillWidth: true }
                        StyledCheckBox {
                            text: "Enabled"
                            control: root.control
                            checked: Boolean(modelData.enabled)
                            onToggled: root._updateMonitor(index, "enabled", checked)
                        }
                        Button {
                            text: confirmRemove ? "Confirm" : "Remove"
                            onClicked: {
                                if (!confirmRemove) { confirmRemove = true; return; }
                                let next = root._copy(root.control.config.hyprlandMonitors || []);
                                next.splice(index, 1);
                                root.control.config.hyprlandMonitors = next;
                                root._syncSelection();
                            }
                        }
                        Button { text: "Cancel"; visible: confirmRemove; onClicked: confirmRemove = false }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Label { text: "Name"; color: root.control.config.textColor; Layout.preferredWidth: 70 }
                        TextField { Layout.fillWidth: true; text: String(modelData.name || ""); onEditingFinished: root._updateMonitor(index, "name", String(text).trim()) }
                        Label { text: "Mode"; color: root.control.config.textColor; Layout.preferredWidth: 40 }
                        TextField { Layout.fillWidth: true; text: String(modelData.mode || "preferred"); onEditingFinished: root._updateMonitor(index, "mode", String(text).trim() || "preferred") }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Label { text: "X"; color: root.control.config.textColor; Layout.preferredWidth: 70 }
                        SpinBox { Layout.fillWidth: true; from: -10000; to: 10000; value: Number(modelData.positionX || 0); onValueModified: root._updateMonitor(index, "positionX", value) }
                        Label { text: "Y"; color: root.control.config.textColor; Layout.preferredWidth: 40 }
                        SpinBox { Layout.fillWidth: true; from: -10000; to: 10000; value: Number(modelData.positionY || 0); onValueModified: root._updateMonitor(index, "positionY", value) }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Label { text: "Scale"; color: root.control.config.textColor; Layout.preferredWidth: 70 }
                        TextField { Layout.fillWidth: true; text: String(modelData.scale || 1); onEditingFinished: root._updateMonitor(index, "scale", Number(text) || 1) }
                        Label { text: "Transform"; color: root.control.config.textColor; Layout.preferredWidth: 70 }
                        SpinBox { Layout.fillWidth: true; from: 0; to: 7; value: Number(modelData.transform || 0); onValueModified: root._updateMonitor(index, "transform", value) }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Label { text: "Mirror Of"; color: root.control.config.textColor; Layout.preferredWidth: 70 }
                        TextField {
                            Layout.fillWidth: true
                            text: String(modelData.mirrorOf || "")
                            placeholderText: "Optional monitor name"
                            onEditingFinished: root._updateMonitor(index, "mirrorOf", String(text).trim())
                        }
                    }
                }
            }
        }

        Item { implicitHeight: 8 }
    }
}
