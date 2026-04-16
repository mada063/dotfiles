import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: root

    required property QtObject control

    clip: true

    ColumnLayout {
        width: parent.width
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: interactionCard.implicitHeight + 20
            color: "transparent"
            border.width: root.control.config.overlayBorderWidth
            border.color: root.control.config.mutedTextColor
            radius: root.control.config.rounding

            ColumnLayout {
                id: interactionCard
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Label { text: "Interaction"; color: root.control.config.overlayAccentColor; font.bold: true }
                Label {
                    text: "Tune how fast edge hover and quick sidebar behavior respond."
                    color: root.control.config.mutedTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    rowSpacing: 8
                    columnSpacing: 10

                    Label { text: "Edge Hold"; color: root.control.config.textColor }
                    SpinBox { from: 150; to: 2000; stepSize: 25; value: root.control.config.sidebarEdgeHoldMs; onValueModified: root.control.config.sidebarEdgeHoldMs = value }
                    Label { text: "Edge Width"; color: root.control.config.textColor }
                    SpinBox { from: 1; to: 24; value: root.control.config.sidebarEdgeThresholdPx; onValueModified: root.control.config.sidebarEdgeThresholdPx = value }

                    Label { text: "Hover Release"; color: root.control.config.textColor }
                    SpinBox { from: 80; to: 1000; stepSize: 20; value: root.control.config.hoverReleaseMs; onValueModified: root.control.config.hoverReleaseMs = value }
                    Label { text: "Slider Height"; color: root.control.config.textColor }
                    SpinBox { from: 68; to: 200; stepSize: 4; value: root.control.config.sidebarSliderHeight; onValueModified: root.control.config.sidebarSliderHeight = value }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: pollingCard.implicitHeight + 20
            color: "transparent"
            border.width: root.control.config.overlayBorderWidth
            border.color: root.control.config.mutedTextColor
            radius: root.control.config.rounding

            ColumnLayout {
                id: pollingCard
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Label { text: "Polling"; color: root.control.config.overlayAccentColor; font.bold: true }
                Label {
                    text: "Choose the refresh profile used by each shell area."
                    color: root.control.config.mutedTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    rowSpacing: 8
                    columnSpacing: 10

                    Label { text: "Workspace"; color: root.control.config.textColor }
                    ComboBox { model: root.control._pollProfileLabels("workspace"); currentIndex: root.control._pollProfileIndex("workspace", root.control.config.barWorkspacePollMs); onActivated: root.control.config.barWorkspacePollMs = root.control._pollProfileValue("workspace", currentIndex) }
                    Label { text: "Bar Status"; color: root.control.config.textColor }
                    ComboBox { model: root.control._pollProfileLabels("barMedium"); currentIndex: root.control._pollProfileIndex("barMedium", root.control.config.barMediumPollMs); onActivated: root.control.config.barMediumPollMs = root.control._pollProfileValue("barMedium", currentIndex) }

                    Label { text: "Bar Slow"; color: root.control.config.textColor }
                    ComboBox { model: root.control._pollProfileLabels("barSlow"); currentIndex: root.control._pollProfileIndex("barSlow", root.control.config.barSlowPollMs); onActivated: root.control.config.barSlowPollMs = root.control._pollProfileValue("barSlow", currentIndex) }
                    Label { text: "Dashboard Fast"; color: root.control.config.textColor }
                    ComboBox { model: root.control._pollProfileLabels("dashboardFast"); currentIndex: root.control._pollProfileIndex("dashboardFast", root.control.config.dashboardFastPollMs); onActivated: root.control.config.dashboardFastPollMs = root.control._pollProfileValue("dashboardFast", currentIndex) }

                    Label { text: "Dashboard Medium"; color: root.control.config.textColor }
                    ComboBox { model: root.control._pollProfileLabels("dashboardMedium"); currentIndex: root.control._pollProfileIndex("dashboardMedium", root.control.config.dashboardMediumPollMs); onActivated: root.control.config.dashboardMediumPollMs = root.control._pollProfileValue("dashboardMedium", currentIndex) }
                    Label { text: "Dashboard Slow"; color: root.control.config.textColor }
                    ComboBox { model: root.control._pollProfileLabels("dashboardSlow"); currentIndex: root.control._pollProfileIndex("dashboardSlow", root.control.config.dashboardSlowPollMs); onActivated: root.control.config.dashboardSlowPollMs = root.control._pollProfileValue("dashboardSlow", currentIndex) }

                    Label { text: "Quick Sidebar"; color: root.control.config.textColor }
                    ComboBox { model: root.control._pollProfileLabels("quickSidebar"); currentIndex: root.control._pollProfileIndex("quickSidebar", root.control.config.quickSidebarPollMs); onActivated: root.control.config.quickSidebarPollMs = root.control._pollProfileValue("quickSidebar", currentIndex) }
                }
            }
        }
    }
}
