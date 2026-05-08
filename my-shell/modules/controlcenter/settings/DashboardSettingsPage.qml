import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    required property QtObject control
    function _T(s) { return root.control.config.formatUiText(s); }
    function _tabVisible(tabId) { return (root.control.config.dashboardTabVisibility || {})[tabId] !== false; }
    function _setTabVisible(tabId, visible) { root.control.shell.setDashboardTabVisible(tabId, visible); }
    property bool hoverOpenEnabled: true
    property bool monitorCpu: true
    property bool monitorRam: true
    property bool monitorDisk: true
    property bool monitorBattery: true

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 16

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: dashboardColumn.implicitHeight + 28
            radius: root.control.config.overlayRounding
            color: Qt.rgba(root.control.config.overlayBackgroundColor.r, root.control.config.overlayBackgroundColor.g, root.control.config.overlayBackgroundColor.b, 0.22)
            border.color: root.control.config.buttonBorderColor
            border.width: root.control.config.buttonBorderWidth

            ColumnLayout {
                id: dashboardColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 10
                Label { text: root._T("Dashboard"); color: root.control.config.accentColor; font.bold: true; font.family: root.control.uiFontFamily }
                Label {
                    text: root._T("Tune dashboard visibility, polling, and tab availability.")
                    color: root.control.config.mutedTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                RowLayout {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    Label { text: root._T("Enabled"); Layout.fillWidth: true; color: root.control.config.textColor }
                    Switch {
                        checked: root.control.config.dashboardEnabled
                        onToggled: root.control.config.dashboardEnabled = checked
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    Label { text: root._T("Hover toggle"); Layout.fillWidth: true; color: root.control.config.textColor }
                    Switch {
                        checked: root.hoverOpenEnabled
                        onToggled: root.hoverOpenEnabled = checked
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    Label { text: root._T("Refresh interval (ms)"); Layout.fillWidth: true; color: root.control.config.textColor }
                    SpinBox {
                        from: 500
                        to: 7000
                        stepSize: 100
                        value: root.control.config.dashboardRefreshMs
                        onValueModified: root.control.config.dashboardRefreshMs = value
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    Label { text: root._T("Media update interval (ms)"); Layout.fillWidth: true; color: root.control.config.textColor }
                    SpinBox {
                        from: 300
                        to: 6000
                        stepSize: 100
                        value: root.control.config.dashboardFastPollMs
                        onValueModified: root.control.config.dashboardFastPollMs = value
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    Label { text: root._T("Resource update interval (ms)"); Layout.fillWidth: true; color: root.control.config.textColor }
                    SpinBox {
                        from: 600
                        to: 8000
                        stepSize: 100
                        value: root.control.config.dashboardMediumPollMs
                        onValueModified: root.control.config.dashboardMediumPollMs = value
                    }
                }
                Label { text: root._T("Visible tabs"); color: root.control.config.textColor; font.bold: true; font.family: root.control.uiFontFamily }
                RowLayout {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    Label { text: "Overview"; Layout.fillWidth: true; color: root.control.config.textColor }
                    Switch {
                        checked: root._tabVisible("overview")
                        onToggled: root._setTabVisible("overview", checked)
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    Label { text: "Performance"; Layout.fillWidth: true; color: root.control.config.textColor }
                    Switch {
                        checked: root._tabVisible("performance")
                        onToggled: root._setTabVisible("performance", checked)
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    Label { text: "Media"; Layout.fillWidth: true; color: root.control.config.textColor }
                    Switch {
                        checked: root._tabVisible("media")
                        onToggled: root._setTabVisible("media", checked)
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: monitorColumn.implicitHeight + 28
            radius: root.control.config.overlayRounding
            color: Qt.rgba(root.control.config.overlayBackgroundColor.r, root.control.config.overlayBackgroundColor.g, root.control.config.overlayBackgroundColor.b, 0.22)
            border.color: root.control.config.buttonBorderColor
            border.width: root.control.config.buttonBorderWidth

            ColumnLayout {
                id: monitorColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 10
                Label { text: root._T("Monitoring Selection"); color: root.control.config.accentColor; font.bold: true; font.family: root.control.uiFontFamily }
                RowLayout {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    Label { text: root._T("CPU"); Layout.fillWidth: true; color: root.control.config.textColor }
                    Switch { checked: root.monitorCpu; onToggled: root.monitorCpu = checked }
                }
                RowLayout {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    Label { text: root._T("RAM"); Layout.fillWidth: true; color: root.control.config.textColor }
                    Switch { checked: root.monitorRam; onToggled: root.monitorRam = checked }
                }
                RowLayout {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    Label { text: root._T("Disk"); Layout.fillWidth: true; color: root.control.config.textColor }
                    Switch { checked: root.monitorDisk; onToggled: root.monitorDisk = checked }
                }
                RowLayout {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    Label { text: root._T("Battery"); Layout.fillWidth: true; color: root.control.config.textColor }
                    Switch { checked: root.monitorBattery; onToggled: root.monitorBattery = checked }
                }
            }
        }
    }
}
