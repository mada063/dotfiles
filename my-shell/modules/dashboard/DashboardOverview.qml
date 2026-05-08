import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: root

    required property QtObject dashboard
    required property QtObject mediaPrevProc
    required property QtObject mediaToggleProc
    required property QtObject mediaNextProc

    clip: true
    implicitHeight: dashboardOverview.implicitHeight

    function _pushOverviewContentHeight() {
        const h = Math.ceil((dashboardOverview.height > 0) ? dashboardOverview.height : dashboardOverview.implicitHeight);
        if (h > 0)
            root.dashboard.overviewContentImplicit = h;
    }

    onImplicitHeightChanged: root._pushOverviewContentHeight()

    RowLayout {
        id: dashboardOverview
        width: root.availableWidth
        height: Math.max(dashboardOverviewLeft.implicitHeight, mediaColumn.implicitHeight)
        spacing: 8
        onImplicitHeightChanged: root._pushOverviewContentHeight()
        onHeightChanged: root._pushOverviewContentHeight()
        onWidthChanged: root._pushOverviewContentHeight()
        Component.onCompleted: root._pushOverviewContentHeight()

        ColumnLayout {
            id: dashboardOverviewLeft
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 170
                spacing: 8

                DashboardWeather {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    dashboard: root.dashboard
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: root.dashboard.dashboardBackgroundColor
                    border.color: root.dashboard.dashboardAccent
                    border.width: root.dashboard.config.overlayBorderWidth
                    radius: root.dashboard.dashboardSurfaceRounding

                    RowLayout {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 14

                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            width: 84
                            height: 84
                            radius: 42
                            color: Qt.rgba(root.dashboard.dashboardAccent.r, root.dashboard.dashboardAccent.g, root.dashboard.dashboardAccent.b, 0.18)
                            border.width: root.dashboard.config.buttonBorderWidth
                            border.color: root.dashboard.dashboardAccent

                            Label {
                                property bool qsKeepPixelSize: true
                                anchors.centerIn: parent
                                text: root.dashboard.avatarText
                                color: root.dashboard.dashboardAccent
                                font.pixelSize: root.dashboard.uiFontSize + 14
                                font.bold: true
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            spacing: 6
                            Label { Layout.fillWidth: true; text: root.dashboard.osInfo; color: root.dashboard.dashboardTextColor; wrapMode: Text.WordWrap; font.bold: true }
                            Label { Layout.fillWidth: true; text: root.dashboard.wmInfo; color: root.dashboard.config.mutedTextColor; wrapMode: Text.WordWrap }
                            Label { Layout.fillWidth: true; text: root.dashboard.uptimeInfo; color: root.dashboard.config.mutedTextColor; wrapMode: Text.WordWrap }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 300
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 210
                    Layout.fillHeight: true
                    color: root.dashboard.dashboardBackgroundColor
                    border.color: root.dashboard.dashboardAccent
                    border.width: root.dashboard.config.overlayBorderWidth
                    radius: root.dashboard.dashboardSurfaceRounding

                    Item {
                        anchors.fill: parent
                        anchors.margins: 12

                        Column {
                            anchors.centerIn: parent
                            width: parent.width
                            spacing: 0

                            Text {
                                property bool qsKeepPixelSize: true
                                text: root.dashboard.timeHour
                                color: root.dashboard.config.dashboardClockHourColor
                                font.pixelSize: root.dashboard.uiFontSize + 34
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                width: parent.width
                            }

                            Text {
                                property bool qsKeepPixelSize: true
                                text: ":"
                                color: root.dashboard.config.mutedTextColor
                                font.pixelSize: root.dashboard.uiFontSize + 18
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                width: parent.width
                            }

                            Text {
                                property bool qsKeepPixelSize: true
                                text: root.dashboard.timeMinute
                                color: root.dashboard.config.dashboardClockMinuteColor
                                font.pixelSize: root.dashboard.uiFontSize + 34
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                width: parent.width
                            }

                            Text {
                                property bool qsKeepPixelSize: true
                                text: ":"
                                color: root.dashboard.config.dashboardClockSecondsTimerColor
                                font.pixelSize: root.dashboard.uiFontSize + 18
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                width: parent.width
                            }

                            Text {
                                property bool qsKeepPixelSize: true
                                text: root.dashboard.timeSecond
                                color: root.dashboard.config.dashboardClockSecondColor
                                font.pixelSize: root.dashboard.uiFontSize + 34
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.bold: true
                                width: parent.width
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: root.dashboard.dashboardBackgroundColor
                    border.color: root.dashboard.dashboardAccent
                    border.width: root.dashboard.config.overlayBorderWidth
                    radius: root.dashboard.dashboardSurfaceRounding

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Label {
                            text: root.dashboard.config.formatUiText(root.dashboard.monthLabel)
                            color: root.dashboard.dashboardAccent
                            font.bold: true
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 7
                            rowSpacing: 4
                            columnSpacing: 4

                            Repeater {
                                model: root.dashboard.weekdayLabels
                                delegate: Label {
                                    required property var modelData
                                    text: root.dashboard.config.formatUiText(modelData)
                            color: root.dashboard.dashboardTextColor
                                    horizontalAlignment: Text.AlignHCenter
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            columns: 7
                            rowSpacing: 4
                            columnSpacing: 4

                            Repeater {
                                model: root.dashboard.calendarCells
                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: Math.max(0, root.dashboard.dashboardSurfaceRounding - 4)
                                    color: modelData.today
                                        ? Qt.rgba(root.dashboard.config.dashboardCalendarCurrentDayColor.r, root.dashboard.config.dashboardCalendarCurrentDayColor.g, root.dashboard.config.dashboardCalendarCurrentDayColor.b, 0.24)
                                        : modelData.weekend && modelData.inMonth
                                            ? Qt.rgba(root.dashboard.config.dashboardCalendarWeekendColor.r, root.dashboard.config.dashboardCalendarWeekendColor.g, root.dashboard.config.dashboardCalendarWeekendColor.b, 0.16)
                                            : "transparent"
                                    border.width: modelData.today ? 1 : 0
                                    border.color: modelData.today ? root.dashboard.config.dashboardCalendarCurrentDayColor : "transparent"

                                    Label {
                                        anchors.centerIn: parent
                                        text: modelData.day
                                        color: !modelData.inMonth
                                            ? Qt.rgba(root.dashboard.config.textColor.r, root.dashboard.config.textColor.g, root.dashboard.config.textColor.b, 0.35)
                                            : root.dashboard.dashboardTextColor
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: root.dashboard.hasDiscreteGpu ? 150 : 126
                    Layout.fillHeight: true
                    color: root.dashboard.dashboardBackgroundColor
                    border.color: root.dashboard.dashboardAccent
                    border.width: root.dashboard.config.overlayBorderWidth
                    radius: root.dashboard.dashboardSurfaceRounding

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        ColumnLayout {
                            spacing: 6
                            Layout.fillHeight: true
                            Layout.fillWidth: true

                            Item {
                                Layout.fillHeight: true
                                Layout.fillWidth: true

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: Math.max(10, parent.width * 0.5)
                                    radius: root.dashboard.config.rounding
                                    color: Qt.rgba(root.dashboard.config.dashboardUsageBarBackgroundColor.r, root.dashboard.config.dashboardUsageBarBackgroundColor.g, root.dashboard.config.dashboardUsageBarBackgroundColor.b, 0.12)
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    width: Math.max(10, parent.width * 0.5)
                                    height: parent.height * Math.max(0, Math.min(100, root.dashboard.cpuUsage)) / 100
                                    radius: root.dashboard.config.rounding
                                    color: root.dashboard.config.dashboardCpuBarColor
                                    opacity: 0.72
                                    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                }
                            }

                            Label {
                                text: root.dashboard.config.formatUiText("CPU")
                                color: root.dashboard.config.dashboardSystemAccentColor
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                            }
                        }

                        ColumnLayout {
                            visible: root.dashboard.hasDiscreteGpu
                            spacing: 6
                            Layout.fillHeight: true
                            Layout.fillWidth: true

                            Item {
                                Layout.fillHeight: true
                                Layout.fillWidth: true

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: Math.max(10, parent.width * 0.5)
                                    radius: root.dashboard.config.rounding
                                    color: Qt.rgba(root.dashboard.config.dashboardUsageBarBackgroundColor.r, root.dashboard.config.dashboardUsageBarBackgroundColor.g, root.dashboard.config.dashboardUsageBarBackgroundColor.b, 0.12)
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    width: Math.max(10, parent.width * 0.5)
                                    height: parent.height * Math.max(0, Math.min(100, root.dashboard.gpuUsage)) / 100
                                    radius: root.dashboard.config.rounding
                                    color: root.dashboard.config.dashboardGpuColor
                                    opacity: 0.72
                                    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                }
                            }

                            Label {
                                text: root.dashboard.config.formatUiText("GPU")
                                color: root.dashboard.config.dashboardSystemAccentColor
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                            }
                        }

                        ColumnLayout {
                            spacing: 6
                            Layout.fillHeight: true
                            Layout.fillWidth: true

                            Item {
                                Layout.fillHeight: true
                                Layout.fillWidth: true

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: Math.max(10, parent.width * 0.5)
                                    radius: root.dashboard.config.rounding
                                    color: Qt.rgba(root.dashboard.config.dashboardUsageBarBackgroundColor.r, root.dashboard.config.dashboardUsageBarBackgroundColor.g, root.dashboard.config.dashboardUsageBarBackgroundColor.b, 0.12)
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    width: Math.max(10, parent.width * 0.5)
                                    height: parent.height * Math.max(0, Math.min(100, root.dashboard.ramPercent)) / 100
                                    radius: root.dashboard.config.rounding
                                    color: root.dashboard.config.dashboardRamBarColor
                                    opacity: 0.72
                                    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                }
                            }

                            Label {
                                text: "RAM"
                                color: root.dashboard.config.dashboardSystemAccentColor
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                            }
                        }

                        ColumnLayout {
                            spacing: 6
                            Layout.fillHeight: true
                            Layout.fillWidth: true

                            Item {
                                Layout.fillHeight: true
                                Layout.fillWidth: true

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: Math.max(10, parent.width * 0.5)
                                    radius: root.dashboard.config.rounding
                                    color: Qt.rgba(root.dashboard.config.dashboardUsageBarBackgroundColor.r, root.dashboard.config.dashboardUsageBarBackgroundColor.g, root.dashboard.config.dashboardUsageBarBackgroundColor.b, 0.12)
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    width: Math.max(10, parent.width * 0.5)
                                    height: parent.height * Math.max(0, Math.min(100, root.dashboard.diskPercent)) / 100
                                    radius: root.dashboard.config.rounding
                                    color: root.dashboard.config.dashboardDiskBarColor
                                    opacity: 0.72
                                    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                }
                            }

                            Label {
                                text: root.dashboard.config.formatUiText("DSK")
                                color: root.dashboard.config.dashboardSystemAccentColor
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: overviewMediaPanel
            Layout.preferredWidth: 230
            Layout.preferredHeight: dashboardOverviewLeft.implicitHeight
            color: root.dashboard.dashboardBackgroundColor
            border.color: root.dashboard.dashboardAccent
            border.width: root.dashboard.config.overlayBorderWidth
            radius: root.dashboard.dashboardSurfaceRounding

            readonly property bool omHasArt: root.dashboard.mediaArtUrl && root.dashboard.mediaArtUrl.length > 0
            readonly property real omLen: root.dashboard.mediaLengthSec
            readonly property real omPos: root.dashboard.mediaPositionSec
            readonly property bool omMediaActive: root.dashboard.mediaState === "Playing" || root.dashboard.mediaState === "Paused"
            readonly property real omFrac: omLen > 0.01 ? Math.min(1, Math.max(0, omPos / omLen)) : 0
            readonly property int omThumbSize: Math.min(96, Math.max(72, overviewMediaPanel.width - 44))
            readonly property real omScrubBarWidth: Math.min(206, Math.max(120, overviewMediaPanel.width - 24))
            function omFmtTime(sec) {
                const s = Math.max(0, Math.floor(Number(sec) || 0));
                const m = Math.floor(s / 60);
                const r = s % 60;
                return String(m) + ":" + String(r).padStart(2, "0");
            }

            ColumnLayout {
                id: mediaColumn
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                Label {
                    text: root.dashboard.mediaInfo
                    color: root.dashboard.dashboardTextColor
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    font.pixelSize: Math.max(10, root.dashboard.uiFontSize)
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 0

                    Column {
                        anchors.centerIn: parent
                        width: parent.width
                        spacing: 8

                        Label {
                            width: parent.width
                            text: root.dashboard.mediaState
                            color: root.dashboard.config.mutedTextColor
                            font.pixelSize: Math.max(9, root.dashboard.uiFontSize - 1)
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }

                        Item {
                            width: overviewMediaPanel.omThumbSize
                            height: overviewMediaPanel.omThumbSize + 8
                            anchors.horizontalCenter: parent.horizontalCenter

                            Image {
                                anchors.centerIn: parent
                                width: overviewMediaPanel.omThumbSize
                                height: width
                                visible: overviewMediaPanel.omHasArt
                                asynchronous: true
                                source: overviewMediaPanel.omHasArt ? root.dashboard.mediaArtUrl : ""
                                fillMode: Image.PreserveAspectCrop
                                mipmap: true
                            }
                            Rectangle {
                                anchors.centerIn: parent
                                width: overviewMediaPanel.omThumbSize
                                height: width
                                visible: !overviewMediaPanel.omHasArt
                                color: Qt.rgba(root.dashboard.config.mutedTextColor.r, root.dashboard.config.mutedTextColor.g, root.dashboard.config.mutedTextColor.b, 0.1)
                                radius: Math.max(0, root.dashboard.config.rounding - 2)
                                Label {
                                    anchors.centerIn: parent
                                    text: "♪"
                                    color: root.dashboard.config.mutedTextColor
                                    font.pixelSize: root.dashboard.uiFontSize + 16
                                }
                            }
                        }

                        RowLayout {
                            id: overviewMediaDurRow
                            width: overviewMediaPanel.omScrubBarWidth
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 4

                            Label {
                                text: overviewMediaPanel.omLen > 0.01 ? overviewMediaPanel.omFmtTime(overviewMediaPanel.omPos) : "—"
                                color: root.dashboard.config.mutedTextColor
                                font.pixelSize: Math.max(8, root.dashboard.uiFontSize - 2)
                                Layout.preferredWidth: 44
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 6
                                color: Qt.rgba(root.dashboard.config.mutedTextColor.r, root.dashboard.config.mutedTextColor.g, root.dashboard.config.mutedTextColor.b, 0.2)
                                radius: 3
                                Rectangle {
                                    width: parent.width * overviewMediaPanel.omFrac
                                    height: parent.height
                                    color: root.dashboard.config.dashboardMediaDurationBarColor
                                    radius: 3
                                    visible: overviewMediaPanel.omLen > 0.01
                                }
                            }
                            Label {
                                text: overviewMediaPanel.omLen > 0.01 ? overviewMediaPanel.omFmtTime(overviewMediaPanel.omLen) : "—"
                                color: root.dashboard.config.mutedTextColor
                                font.pixelSize: Math.max(8, root.dashboard.uiFontSize - 2)
                                Layout.preferredWidth: 44
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Layout.topMargin: 2
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        color: prevOm.containsMouse
                            ? Qt.rgba(root.dashboard.config.dashboardMediaControlsColor.r, root.dashboard.config.dashboardMediaControlsColor.g, root.dashboard.config.dashboardMediaControlsColor.b, 0.10)
                            : "transparent"
                        border.width: root.dashboard.config.buttonBorderWidth
                        border.color: prevOm.containsMouse ? root.dashboard.config.dashboardMediaControlsColor : root.dashboard.config.overlayAccentColor
                        radius: Math.max(0, root.dashboard.dashboardSurfaceRounding - 3)
                        Label { anchors.centerIn: parent; text: "⏮"; color: prevOm.containsMouse ? root.dashboard.config.dashboardMediaControlsColor : root.dashboard.dashboardTextColor; font.pixelSize: root.dashboard.uiFontSize + 12 }
                        MouseArea { id: prevOm; anchors.fill: parent; hoverEnabled: true; onClicked: root.mediaPrevProc.exec({ command: root.mediaPrevProc.command }) }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        color: playOm.containsMouse
                            ? Qt.rgba(root.dashboard.config.dashboardMediaControlsColor.r, root.dashboard.config.dashboardMediaControlsColor.g, root.dashboard.config.dashboardMediaControlsColor.b, 0.10)
                            : "transparent"
                        border.width: root.dashboard.config.buttonBorderWidth
                        border.color: (playOm.containsMouse || overviewMediaPanel.omMediaActive) ? root.dashboard.config.dashboardMediaControlsColor : root.dashboard.config.overlayAccentColor
                        radius: Math.max(0, root.dashboard.dashboardSurfaceRounding - 3)
                        Label { anchors.centerIn: parent; text: root.dashboard.mediaState === "Playing" ? "⏸" : "▶"; color: playOm.containsMouse ? root.dashboard.config.dashboardMediaControlsColor : root.dashboard.dashboardTextColor; font.pixelSize: root.dashboard.uiFontSize + 12 }
                        MouseArea { id: playOm; anchors.fill: parent; hoverEnabled: true; onClicked: root.mediaToggleProc.exec({ command: root.mediaToggleProc.command }) }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        color: nextOm.containsMouse
                            ? Qt.rgba(root.dashboard.config.dashboardMediaControlsColor.r, root.dashboard.config.dashboardMediaControlsColor.g, root.dashboard.config.dashboardMediaControlsColor.b, 0.10)
                            : "transparent"
                        border.width: root.dashboard.config.buttonBorderWidth
                        border.color: nextOm.containsMouse ? root.dashboard.config.dashboardMediaControlsColor : root.dashboard.config.overlayAccentColor
                        radius: Math.max(0, root.dashboard.dashboardSurfaceRounding - 3)
                        Label { anchors.centerIn: parent; text: "⏭"; color: nextOm.containsMouse ? root.dashboard.config.dashboardMediaControlsColor : root.dashboard.dashboardTextColor; font.pixelSize: root.dashboard.uiFontSize + 12 }
                        MouseArea { id: nextOm; anchors.fill: parent; hoverEnabled: true; onClicked: root.mediaNextProc.exec({ command: root.mediaNextProc.command }) }
                    }
                }
            }
        }
    }
}
