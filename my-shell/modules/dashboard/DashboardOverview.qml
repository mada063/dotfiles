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

    RowLayout {
        id: dashboardOverview
        width: root.availableWidth
        height: Math.max(dashboardOverviewLeft.implicitHeight, mediaColumn.implicitHeight)
        spacing: 8

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
                    color: "transparent"
                    border.color: root.dashboard.dashboardAccent
                    border.width: root.dashboard.config.overlayBorderWidth
                    radius: root.dashboard.config.rounding

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 14

                        Rectangle {
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
                            spacing: 6
                            Label { text: root.dashboard.osInfo; color: root.dashboard.config.textColor; wrapMode: Text.WordWrap; font.bold: true }
                            Label { text: root.dashboard.wmInfo; color: root.dashboard.config.mutedTextColor; wrapMode: Text.WordWrap }
                            Label { text: root.dashboard.uptimeInfo; color: root.dashboard.config.mutedTextColor; wrapMode: Text.WordWrap }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 320
                spacing: 8

                Rectangle {
                    Layout.preferredWidth: 210
                    Layout.fillHeight: true
                    color: "transparent"
                    border.color: root.dashboard.config.mutedTextColor
                    border.width: root.dashboard.config.overlayBorderWidth
                    radius: root.dashboard.config.rounding

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 0

                        Text {
                            property bool qsKeepPixelSize: true
                            text: root.dashboard.timeHour
                            color: root.dashboard.dashboardAccent
                            font.pixelSize: root.dashboard.uiFontSize + 34
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            width: parent.width
                            height: parent.height * 0.24
                        }

                        Text {
                            property bool qsKeepPixelSize: true
                            text: "-"
                            color: root.dashboard.config.mutedTextColor
                            font.pixelSize: root.dashboard.uiFontSize + 18
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            width: parent.width
                            height: parent.height * 0.10
                        }

                        Text {
                            property bool qsKeepPixelSize: true
                            text: root.dashboard.timeMinute
                            color: root.dashboard.config.textColor
                            font.pixelSize: root.dashboard.uiFontSize + 34
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            width: parent.width
                            height: parent.height * 0.24
                        }

                        Text {
                            property bool qsKeepPixelSize: true
                            text: "-"
                            color: root.dashboard.config.mutedTextColor
                            font.pixelSize: root.dashboard.uiFontSize + 18
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            width: parent.width
                            height: parent.height * 0.10
                        }

                        Text {
                            property bool qsKeepPixelSize: true
                            text: root.dashboard.timeSecond
                            color: root.dashboard.config.mutedTextColor
                            font.pixelSize: root.dashboard.uiFontSize + 26
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            width: parent.width
                            height: parent.height * 0.20
                        }
                    }
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

                        Label {
                            text: root.dashboard.monthLabel
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
                                    text: modelData
                                    color: root.dashboard.config.textColor
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
                                    radius: Math.max(0, root.dashboard.config.rounding - 4)
                                    color: modelData.today
                                        ? Qt.rgba(root.dashboard.dashboardAccent.r, root.dashboard.dashboardAccent.g, root.dashboard.dashboardAccent.b, 0.24)
                                        : modelData.weekend && modelData.inMonth
                                            ? Qt.rgba(root.dashboard.dashboardAccent.r, root.dashboard.dashboardAccent.g, root.dashboard.dashboardAccent.b, 0.10)
                                            : "transparent"
                                    border.width: modelData.today ? 1 : 0
                                    border.color: modelData.today ? root.dashboard.dashboardAccent : "transparent"

                                    Label {
                                        anchors.centerIn: parent
                                        text: modelData.day
                                        color: !modelData.inMonth
                                            ? Qt.rgba(root.dashboard.config.textColor.r, root.dashboard.config.textColor.g, root.dashboard.config.textColor.b, 0.35)
                                            : root.dashboard.config.textColor
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: root.dashboard.hasDiscreteGpu ? 150 : 126
                    Layout.fillHeight: true
                    color: "transparent"
                    border.color: root.dashboard.config.mutedTextColor
                    border.width: root.dashboard.config.overlayBorderWidth
                    radius: root.dashboard.config.rounding

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
                                    color: Qt.rgba(root.dashboard.config.textColor.r, root.dashboard.config.textColor.g, root.dashboard.config.textColor.b, 0.06)
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    width: Math.max(10, parent.width * 0.5)
                                    height: parent.height * Math.max(0, Math.min(100, root.dashboard.cpuUsage)) / 100
                                    radius: root.dashboard.config.rounding
                                    color: root.dashboard.dashboardAccent
                                    opacity: 0.72
                                    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                }
                            }

                            Label {
                                text: "CPU"
                                color: root.dashboard.config.textColor
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
                                    color: Qt.rgba(root.dashboard.config.textColor.r, root.dashboard.config.textColor.g, root.dashboard.config.textColor.b, 0.06)
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    width: Math.max(10, parent.width * 0.5)
                                    height: parent.height * Math.max(0, Math.min(100, root.dashboard.gpuUsage)) / 100
                                    radius: root.dashboard.config.rounding
                                    color: Qt.lighter(root.dashboard.dashboardAccent, 1.18)
                                    opacity: 0.72
                                    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                }
                            }

                            Label {
                                text: "GPU"
                                color: root.dashboard.config.textColor
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
                                    color: Qt.rgba(root.dashboard.config.textColor.r, root.dashboard.config.textColor.g, root.dashboard.config.textColor.b, 0.06)
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    width: Math.max(10, parent.width * 0.5)
                                    height: parent.height * Math.max(0, Math.min(100, root.dashboard.ramPercent)) / 100
                                    radius: root.dashboard.config.rounding
                                    color: root.dashboard.config.textColor
                                    opacity: 0.72
                                    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                }
                            }

                            Label {
                                text: "RAM"
                                color: root.dashboard.config.textColor
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
                                    color: Qt.rgba(root.dashboard.config.textColor.r, root.dashboard.config.textColor.g, root.dashboard.config.textColor.b, 0.06)
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    width: Math.max(10, parent.width * 0.5)
                                    height: parent.height * Math.max(0, Math.min(100, root.dashboard.diskPercent)) / 100
                                    radius: root.dashboard.config.rounding
                                    color: root.dashboard.config.mutedTextColor
                                    opacity: 0.72
                                    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                }
                            }

                            Label {
                                text: "DSK"
                                color: root.dashboard.config.textColor
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 230
            Layout.preferredHeight: dashboardOverviewLeft.implicitHeight
            color: "transparent"
            border.color: root.dashboard.dashboardAccent
            border.width: root.dashboard.config.overlayBorderWidth
            radius: root.dashboard.config.rounding

            ColumnLayout {
                id: mediaColumn
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Label {
                    text: "Media"
                    color: root.dashboard.dashboardAccent
                    font.bold: true
                }

                Label {
                    text: root.dashboard.mediaInfo
                    color: root.dashboard.config.textColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Label {
                    text: root.dashboard.mediaState
                    color: root.dashboard.config.mutedTextColor
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    color: "transparent"
                    border.width: root.dashboard.config.buttonBorderWidth
                    border.color: root.dashboard.config.mutedTextColor
                    radius: Math.max(0, root.dashboard.config.rounding - 3)
                    Label { anchors.centerIn: parent; text: "Previous"; color: root.dashboard.config.textColor }
                    MouseArea { anchors.fill: parent; onClicked: root.mediaPrevProc.exec({ command: root.mediaPrevProc.command }) }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    color: "transparent"
                    border.width: root.dashboard.config.buttonBorderWidth
                    border.color: root.dashboard.config.mutedTextColor
                    radius: Math.max(0, root.dashboard.config.rounding - 3)
                    Label { anchors.centerIn: parent; text: root.dashboard.mediaState === "Playing" ? "Pause" : "Play"; color: root.dashboard.config.textColor }
                    MouseArea { anchors.fill: parent; onClicked: root.mediaToggleProc.exec({ command: root.mediaToggleProc.command }) }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    color: "transparent"
                    border.width: root.dashboard.config.buttonBorderWidth
                    border.color: root.dashboard.config.mutedTextColor
                    radius: Math.max(0, root.dashboard.config.rounding - 3)
                    Label { anchors.centerIn: parent; text: "Next"; color: root.dashboard.config.textColor }
                    MouseArea { anchors.fill: parent; onClicked: root.mediaNextProc.exec({ command: root.mediaNextProc.command }) }
                }
            }
        }
    }
}
