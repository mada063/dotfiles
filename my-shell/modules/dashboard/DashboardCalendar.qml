import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    required property QtObject dashboard

    RowLayout {
        anchors.fill: parent
        spacing: 8

        Rectangle {
            Layout.preferredWidth: 210
            Layout.fillHeight: true
            color: root.dashboard.dashboardBackgroundColor
            border.color: root.dashboard.dashboardAccent
            border.width: root.dashboard.config.overlayBorderWidth
            radius: root.dashboard.dashboardSurfaceRounding

            Column {
                anchors.fill: parent
                anchors.margins: 12
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
                    height: parent.height * 0.24
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
                    height: parent.height * 0.10
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
                    height: parent.height * 0.24
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
                    height: parent.height * 0.10
                }

                Text {
                    property bool qsKeepPixelSize: true
                    text: root.dashboard.timeSecond
                    color: root.dashboard.config.dashboardClockSecondColor
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
            border.color: root.dashboard.dashboardAccent
            border.width: root.dashboard.config.overlayBorderWidth
            radius: root.dashboard.config.rounding

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
    }
}
