import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    required property QtObject host
    required property int workspaceId
    required property var items
    required property var previewMonitor

    readonly property var fallbackBounds: _fallbackBounds()
    readonly property real monitorX: root.previewMonitor ? (Number(root.previewMonitor.x) || 0) : fallbackBounds.x
    readonly property real monitorY: root.previewMonitor ? (Number(root.previewMonitor.y) || 0) : fallbackBounds.y
    readonly property real monitorWidth: root.previewMonitor ? Math.max(1, Number(root.previewMonitor.width) || 0) : fallbackBounds.width
    readonly property real monitorHeight: root.previewMonitor ? Math.max(1, Number(root.previewMonitor.height) || 0) : fallbackBounds.height
    readonly property string monitorName: root.previewMonitor
        ? (String(root.previewMonitor.name || "").trim() || "Display")
        : "Workspace"
    readonly property real headerHeight: 30
    readonly property real footerHeight: 24
    readonly property real previewInsetLeft: 6
    readonly property real previewInsetRight: 6
    readonly property real previewInsetTop: 4
    readonly property real rightLabelInset: 12
    readonly property real maxPreviewWidth: 356
    readonly property real previewContentWidth: Math.max(
        120,
        ((root.width > 0 ? root.width : root.maxPreviewWidth) - root.previewInsetLeft - root.previewInsetRight)
    )
    readonly property real previewScale: root.previewContentWidth / Math.max(1, root.monitorWidth)
    readonly property real contentHeight: Math.max(72, Math.round(root.monitorHeight * root.previewScale))
    readonly property var previewWindows: _previewWindows()

    implicitWidth: root.maxPreviewWidth
    implicitHeight: Math.max(132, root.headerHeight + root.footerHeight + root.contentHeight + root.previewInsetTop)

    function _fallbackBounds() {
        let minX = Infinity;
        let minY = Infinity;
        let maxX = -Infinity;
        let maxY = -Infinity;
        const source = Array.isArray(root.items) ? root.items : [];
        for (let i = 0; i < source.length; i++) {
            const item = source[i] || {};
            const x = Number(item.x) || 0;
            const y = Number(item.y) || 0;
            const width = Math.max(1, Number(item.width) || 0);
            const height = Math.max(1, Number(item.height) || 0);
            minX = Math.min(minX, x);
            minY = Math.min(minY, y);
            maxX = Math.max(maxX, x + width);
            maxY = Math.max(maxY, y + height);
        }
        if (minX === Infinity || minY === Infinity || maxX === -Infinity || maxY === -Infinity)
            return { x: 0, y: 0, width: 1920, height: 1080 };
        return {
            x: minX,
            y: minY,
            width: Math.max(960, maxX - minX),
            height: Math.max(540, maxY - minY)
        };
    }

    function _windowTitle(client) {
        const title = String(client.title || "").trim();
        const className = String(client.className || client.initialClass || "").trim();
        if (title.length > 0)
            return title;
        if (className.length > 0)
            return className;
        return "Window";
    }

    function _previewWindows() {
        const source = Array.isArray(root.items) ? root.items.slice() : [];
        source.sort((a, b) => {
            const fullscreenDelta = Number(Boolean(b.fullscreen)) - Number(Boolean(a.fullscreen));
            if (fullscreenDelta !== 0)
                return fullscreenDelta;
            const floatingDelta = Number(Boolean(a.floating)) - Number(Boolean(b.floating));
            if (floatingDelta !== 0)
                return floatingDelta;
            return (Number(b.width) || 0) * (Number(b.height) || 0) - (Number(a.width) || 0) * (Number(a.height) || 0);
        });
        let out = [];
        for (let i = 0; i < source.length; i++) {
            const item = source[i] || {};
            let x = (Number(item.x) || 0) - root.monitorX;
            let y = (Number(item.y) || 0) - root.monitorY;
            let width = Math.max(1, Number(item.width) || 0);
            let height = Math.max(1, Number(item.height) || 0);
            x = Math.max(0, Math.min(root.monitorWidth - 18, x));
            y = Math.max(0, Math.min(root.monitorHeight - 18, y));
            width = Math.max(1, Math.min(width, root.monitorWidth - x));
            height = Math.max(1, Math.min(height, root.monitorHeight - y));
            out.push({
                title: root._windowTitle(item),
                className: String(item.className || item.initialClass || "").trim(),
                floating: Boolean(item.floating),
                fullscreen: Boolean(item.fullscreen),
                x: x,
                y: y,
                width: width,
                height: height
            });
        }
        return out;
    }

    Rectangle {
        anchors.fill: parent
        color: root.host.config.overlayBackgroundColor
        border.color: root.host.config.overlayAccentColor
        border.width: root.host.config.overlayBorderWidth
        radius: root.host.config.overlayRounding
        clip: true

        Repeater {
            model: root.previewWindows
            delegate: Rectangle {
                required property var modelData

                x: root.previewInsetLeft + Math.round(modelData.x * root.previewScale)
                y: root.headerHeight + root.previewInsetTop + Math.round(modelData.y * root.previewScale)
                width: Math.max(10, Math.round(modelData.width * root.previewScale))
                height: Math.max(8, Math.round(modelData.height * root.previewScale))
                radius: Math.max(2, root.host.config.workspaceRounding - 2)
                color: modelData.fullscreen
                    ? Qt.rgba(
                        root.host.config.overlayAccentColor.r,
                        root.host.config.overlayAccentColor.g,
                        root.host.config.overlayAccentColor.b,
                        0.26
                    )
                    : modelData.floating
                        ? Qt.rgba(
                            root.host.config.accentColor.r,
                            root.host.config.accentColor.g,
                            root.host.config.accentColor.b,
                            0.24
                        )
                        : Qt.rgba(
                            root.host.config.workspaceBackgroundColor.r,
                            root.host.config.workspaceBackgroundColor.g,
                            root.host.config.workspaceBackgroundColor.b,
                            0.92
                        )
                border.width: Math.max(1, root.host.config.buttonBorderWidth)
                border.color: modelData.floating
                    ? root.host.config.accentColor
                    : modelData.fullscreen
                        ? root.host.config.overlayAccentColor
                        : Qt.rgba(
                            root.host.config.overlayTextColor.r,
                            root.host.config.overlayTextColor.g,
                            root.host.config.overlayTextColor.b,
                            0.18
                        )

                Label {
                    anchors.fill: parent
                    anchors.margins: 4
                    visible: parent.width >= 36 && parent.height >= 18
                    text: modelData.title
                    color: root.host.config.overlayTextColor
                    font.family: root.host.uiFontFamily
                    font.pixelSize: Math.max(8, root.host.uiFontSize - 4)
                    wrapMode: Text.Wrap
                    maximumLineCount: parent.height >= 30 ? 2 : 1
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: root.headerHeight
            color: Qt.rgba(
                root.host.config.overlayBackgroundColor.r,
                root.host.config.overlayBackgroundColor.g,
                root.host.config.overlayBackgroundColor.b,
                0.84
            )
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: root.footerHeight
            color: Qt.rgba(
                root.host.config.overlayBackgroundColor.r,
                root.host.config.overlayBackgroundColor.g,
                root.host.config.overlayBackgroundColor.b,
                0.72
            )
        }

        Label {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 8
            text: "Workspace " + root.workspaceId
            color: root.host.config.overlayTextColor
            font.family: root.host.uiFontFamily
            font.pixelSize: root.host.uiFontSize
            font.bold: true
        }

        Label {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: root.rightLabelInset
            text: root.monitorName
            color: root.host.config.mutedTextColor
            font.family: root.host.uiFontFamily
            font.pixelSize: Math.max(10, root.host.uiFontSize - 1)
        }

        Label {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: root.rightLabelInset
            text: root.previewWindows.length > 0
                ? root.previewWindows.length + (root.previewWindows.length === 1 ? " window" : " windows")
                : "No open windows"
            color: root.host.config.mutedTextColor
            font.family: root.host.uiFontFamily
            font.pixelSize: Math.max(10, root.host.uiFontSize - 1)
        }

        Label {
            anchors.centerIn: parent
            visible: root.previewWindows.length < 1
            text: "Empty workspace"
            color: root.host.config.mutedTextColor
            font.family: root.host.uiFontFamily
            font.pixelSize: root.host.uiFontSize
        }
    }
}
