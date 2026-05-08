import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "."

Item {
    id: root

    required property QtObject dashboard
    property alias networkCanvas: networkCanvas

    RowLayout {
        anchors.fill: parent
        spacing: 8

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 210
                    color: "transparent"
                    border.color: root.dashboard.dashboardAccent
                    border.width: root.dashboard.config.overlayBorderWidth
                    radius: root.dashboard.config.rounding

                    Rectangle {
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        width: parent.width * Math.max(0, Math.min(100, root.dashboard.cpuUsage)) / 100
                        radius: root.dashboard.config.rounding
                        color: Qt.rgba(root.dashboard.config.dashboardPerformanceCpuBackgroundFillColor.r, root.dashboard.config.dashboardPerformanceCpuBackgroundFillColor.g, root.dashboard.config.dashboardPerformanceCpuBackgroundFillColor.b, 0.20)
                        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: root.dashboard.config.formatUiText("CPU"); color: root.dashboard.config.dashboardCpuColor; font.bold: true }
                            Item { Layout.fillWidth: true }
                            Label { text: root.dashboard.cpuUsage + "%"; color: root.dashboard.config.dashboardCpuColor; font.bold: true }
                        }

                        Label {
                            text: root.dashboard.cpuName
                            color: root.dashboard.config.dashboardTextColor
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Item { Layout.fillHeight: true }

                        Label {
                            text: root.dashboard.config.formatUiText("Temp") + " " + root.dashboard.cpuTemp + " C"
                            color: root.dashboard.config.mutedTextColor
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 10
                            radius: Math.min(Math.max(0, root.dashboard.config.rounding), implicitHeight / 2)
                            color: Qt.rgba(root.dashboard.config.dashboardUsageBarBackgroundColor.r, root.dashboard.config.dashboardUsageBarBackgroundColor.g, root.dashboard.config.dashboardUsageBarBackgroundColor.b, 0.16)

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * Math.max(0, Math.min(100, root.dashboard.cpuTemp)) / 100
                                radius: Math.min(Math.max(0, root.dashboard.config.rounding), parent.height / 2)
                            color: root.dashboard.cpuTemp >= 80 ? "#ef4444" : root.dashboard.config.dashboardPerformanceCpuTempBarColor
                                Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            }
                        }
                    }
                }

                Rectangle {
                    visible: root.dashboard.hasDiscreteGpu
                    Layout.fillWidth: true
                    Layout.preferredHeight: 210
                    color: "transparent"
                    border.color: root.dashboard.dashboardAccent
                    border.width: root.dashboard.config.overlayBorderWidth
                    radius: root.dashboard.config.rounding

                    Rectangle {
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        width: parent.width * Math.max(0, Math.min(100, root.dashboard.gpuUsage)) / 100
                        radius: root.dashboard.config.rounding
                        color: Qt.rgba(root.dashboard.config.dashboardPerformanceGpuBackgroundFillColor.r, root.dashboard.config.dashboardPerformanceGpuBackgroundFillColor.g, root.dashboard.config.dashboardPerformanceGpuBackgroundFillColor.b, 0.20)
                        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            Label { text: root.dashboard.config.formatUiText("GPU"); color: root.dashboard.config.dashboardGpuColor; font.bold: true }
                            Item { Layout.fillWidth: true }
                            Label { text: root.dashboard.gpuUsage + "%"; color: root.dashboard.config.dashboardGpuColor; font.bold: true }
                        }

                        Label {
                            text: root.dashboard.gpuName
                            color: root.dashboard.config.dashboardTextColor
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Item { Layout.fillHeight: true }

                        Label {
                            text: root.dashboard.config.formatUiText("Temp") + " " + root.dashboard.gpuTemp + " C"
                            color: root.dashboard.config.mutedTextColor
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 10
                            radius: Math.min(Math.max(0, root.dashboard.config.rounding), implicitHeight / 2)
                            color: Qt.rgba(root.dashboard.config.dashboardUsageBarBackgroundColor.r, root.dashboard.config.dashboardUsageBarBackgroundColor.g, root.dashboard.config.dashboardUsageBarBackgroundColor.b, 0.16)

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: parent.width * Math.max(0, Math.min(100, root.dashboard.gpuTemp)) / 100
                                radius: Math.min(Math.max(0, root.dashboard.config.rounding), parent.height / 2)
                                color: root.dashboard.gpuTemp >= 80 ? "#ef4444" : root.dashboard.config.dashboardPerformanceGpuTempBarColor
                                Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                UpdatesBatteryBar {
                    Layout.preferredWidth: 180
                    Layout.fillHeight: true
                    useSegmentSteps: false
                    fillOpacity: 0.2
                    segmentPercent: root.dashboard.ramPercent
                    segmentColor: root.dashboard.config.dashboardPerformanceMemoryBarFillColor
                    barTitle: root.dashboard.config.formatUiText("Memory")
                    bigValue: root.dashboard.ramPercent + "%"
                    smallLabel: root.dashboard.ramUsedText + " / " + root.dashboard.ramTotalText
                    titleColor: root.dashboard.config.dashboardSystemAccentColor
                    mutedTextColor: root.dashboard.config.mutedTextColor
                    panelBorder: root.dashboard.dashboardAccent
                    borderW: root.dashboard.config.overlayBorderWidth
                    barRounding: root.dashboard.config.rounding
                    valuePixelSize: root.dashboard.uiFontSize + 18
                }

                UpdatesBatteryBar {
                    Layout.preferredWidth: 180
                    Layout.fillHeight: true
                    useSegmentSteps: false
                    fillOpacity: 0.2
                    segmentPercent: root.dashboard.diskPercent
                    segmentColor: root.dashboard.config.dashboardPerformanceDiskBarFillColor
                    barTitle: root.dashboard.config.formatUiText("Disk")
                    bigValue: root.dashboard.diskPercent + "%"
                    smallLabel: root.dashboard.diskUsedText + " / " + root.dashboard.diskTotalText
                    titleColor: root.dashboard.config.dashboardSystemAccentColor
                    mutedTextColor: root.dashboard.config.mutedTextColor
                    panelBorder: root.dashboard.dashboardAccent
                    borderW: root.dashboard.config.overlayBorderWidth
                    barRounding: root.dashboard.config.rounding
                    valuePixelSize: root.dashboard.uiFontSize + 18
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"
                    border.color: root.dashboard.config.mutedTextColor
                    border.width: root.dashboard.config.overlayBorderWidth
                    radius: root.dashboard.config.rounding

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Label { text: root.dashboard.config.formatUiText("Network"); color: root.dashboard.config.dashboardSystemAccentColor; font.bold: true }

                        Connections {
                            target: root.dashboard
                            function onNetDownHistoryChanged() { networkCanvas.requestPaint() }
                            function onNetUpHistoryChanged() { networkCanvas.requestPaint() }
                        }

                        Canvas {
                            id: networkCanvas
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 100
                            onWidthChanged: requestPaint()
                            onHeightChanged: requestPaint()
                            onVisibleChanged: if (visible) requestPaint()
                            Component.onCompleted: requestPaint()
                            onPaint: {
                                const ctx = getContext("2d");
                                ctx.reset();
                                ctx.fillStyle = "rgba(0,0,0,0)";
                                ctx.fillRect(0, 0, width, height);

                                const down = root.dashboard.netDownHistory;
                                const up = root.dashboard.netUpHistory;
                                const maxLen = Math.max(down.length, up.length);
                                if (maxLen < 2)
                                    return;

                                let maxValue = 1;
                                for (let i = 0; i < down.length; i++)
                                    maxValue = Math.max(maxValue, Number(down[i]) || 0);
                                for (let i = 0; i < up.length; i++)
                                    maxValue = Math.max(maxValue, Number(up[i]) || 0);

                                function drawSeries(values, color) {
                                    if (values.length < 2)
                                        return;
                                    ctx.beginPath();
                                    ctx.lineWidth = 2;
                                    ctx.strokeStyle = color;
                                    ctx.lineJoin = "round";
                                    ctx.lineCap = "round";
                                    const points = [];
                                    for (let j = 0; j < values.length; j++) {
                                        const x = values.length > 1 ? (width * j) / (values.length - 1) : 0;
                                        const y = height - ((Number(values[j]) || 0) / maxValue) * (height - 4) - 2;
                                        points.push({ x: x, y: y });
                                    }
                                    ctx.moveTo(points[0].x, points[0].y);
                                    for (let j = 1; j < points.length - 1; j++) {
                                        const xc = (points[j].x + points[j + 1].x) / 2;
                                        const yc = (points[j].y + points[j + 1].y) / 2;
                                        ctx.quadraticCurveTo(points[j].x, points[j].y, xc, yc);
                                    }
                                    ctx.quadraticCurveTo(points[points.length - 1].x, points[points.length - 1].y, points[points.length - 1].x, points[points.length - 1].y);
                                    ctx.stroke();
                                }

                                drawSeries(down, root.dashboard.config.dashboardWifiDownColor);
                                drawSeries(up, root.dashboard.config.dashboardWifiUpColor);
                            }
                        }

                        Label { text: root.dashboard.config.formatUiText("Download") + " " + root.dashboard.netDownText; color: root.dashboard.config.dashboardWifiDownColor }
                        Label { text: root.dashboard.config.formatUiText("Upload") + " " + root.dashboard.netUpText; color: root.dashboard.config.dashboardWifiUpColor }
                        Label { text: root.dashboard.config.formatUiText("Total") + " " + root.dashboard.netTotalText; color: root.dashboard.config.mutedTextColor }
                    }
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 200
            Layout.fillHeight: true
            color: "transparent"
            border.color: root.dashboard.dashboardAccent
            border.width: root.dashboard.config.overlayBorderWidth
            radius: root.dashboard.config.rounding

            Item {
                id: batterySegLayer
                anchors.fill: parent
                clip: true
                z: 0
                readonly property real segGap: 2
                readonly property real segH: height > 0 ? Math.max(0, (height - 9 * segGap) / 10) : 0

                Repeater {
                    model: 10
                    delegate: Rectangle {
                        required property int index
                        width: batterySegLayer.width
                        height: batterySegLayer.segH
                        x: 0
                        y: batterySegLayer.height - (index + 1) * batterySegLayer.segH - index * batterySegLayer.segGap
                        radius: Math.min(batterySegLayer.segH / 2, root.dashboard.config.rounding)
                        color: root.dashboard.batteryPercent > index * 10
                            ? Qt.rgba(root.dashboard.config.dashboardPerformanceBatteryFillColor.r, root.dashboard.config.dashboardPerformanceBatteryFillColor.g, root.dashboard.config.dashboardPerformanceBatteryFillColor.b, 0.30)
                            : "transparent"
                    }
                }
            }

            ColumnLayout {
                z: 1
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Label { text: root.dashboard.config.formatUiText("Battery"); color: root.dashboard.config.dashboardBatteryPerformanceColor; font.bold: true }
                Item { Layout.fillHeight: true }
                Label { property bool qsKeepPixelSize: true; text: root.dashboard.batteryPercent + "%"; color: root.dashboard.config.dashboardBatteryPerformanceColor; font.pixelSize: root.dashboard.uiFontSize + 22; font.bold: true }
                Label { text: root.dashboard.batteryStatus; color: root.dashboard.config.mutedTextColor }
            }
        }
    }
}
