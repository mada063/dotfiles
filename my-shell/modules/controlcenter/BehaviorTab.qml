import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: root

    required property QtObject control

    clip: true

    function _T(s) { return root.control.config.formatUiText(s); }

    ColumnLayout {
        width: parent.width
        spacing: 0

        // ── Typography (titles & button labels) ───────────────────────

        Label { text: _T("Typography"); color: root.control.config.accentColor; font.bold: true; Layout.bottomMargin: 4 }

        Label {
            text: _T("Use standard casing, or all caps for titles, buttons, and other chrome labels (not content such as track titles).")
            color: root.control.config.mutedTextColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.bottomMargin: 8
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: _T("All caps"); color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            Switch {
                checked: root.control.config.uiTextStyle === "uppercase"
                onToggled: root.control.config.uiTextStyle = checked ? "uppercase" : "standard"
            }
        }

        Item { implicitHeight: 18 }

        // ── Interaction ───────────────────────────────────────────────

        Label { text: _T("Interaction"); color: root.control.config.accentColor; font.bold: true; Layout.bottomMargin: 4 }

        Label {
            text: _T("Tune how fast edge hover and sidebar behavior respond.")
            color: root.control.config.mutedTextColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.bottomMargin: 8
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: _T("Edge Hold (ms)"); color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            SpinBox { from: 150; to: 2000; stepSize: 25; value: root.control.config.sidebarEdgeHoldMs; onValueModified: root.control.config.sidebarEdgeHoldMs = value }
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: _T("Edge Width (px)"); color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            SpinBox { from: 1; to: 24; value: root.control.config.sidebarEdgeThresholdPx; onValueModified: root.control.config.sidebarEdgeThresholdPx = value }
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: _T("Hover Release (ms)"); color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            SpinBox { from: 80; to: 1000; stepSize: 20; value: root.control.config.hoverReleaseMs; onValueModified: root.control.config.hoverReleaseMs = value }
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: _T("Slider Height (px)"); color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            SpinBox { from: 68; to: 200; stepSize: 4; value: root.control.config.sidebarSliderHeight; onValueModified: root.control.config.sidebarSliderHeight = value }
        }

        Item { implicitHeight: 18 }

        // ── Polling ───────────────────────────────────────────────────

        Label { text: _T("Polling"); color: root.control.config.accentColor; font.bold: true; Layout.bottomMargin: 4 }

        Label {
            text: _T("Choose the refresh profile used by each shell area.")
            color: root.control.config.mutedTextColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.bottomMargin: 8
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: _T("Workspace"); color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            ComboBox { Layout.preferredWidth: 120; model: root.control._pollProfileLabels("workspace"); currentIndex: root.control._pollProfileIndex("workspace", root.control.config.barWorkspacePollMs); onActivated: root.control.config.barWorkspacePollMs = root.control._pollProfileValue("workspace", currentIndex) }
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: _T("Bar Status"); color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            ComboBox { Layout.preferredWidth: 120; model: root.control._pollProfileLabels("barMedium"); currentIndex: root.control._pollProfileIndex("barMedium", root.control.config.barMediumPollMs); onActivated: root.control.config.barMediumPollMs = root.control._pollProfileValue("barMedium", currentIndex) }
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: _T("Bar Slow"); color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            ComboBox { Layout.preferredWidth: 120; model: root.control._pollProfileLabels("barSlow"); currentIndex: root.control._pollProfileIndex("barSlow", root.control.config.barSlowPollMs); onActivated: root.control.config.barSlowPollMs = root.control._pollProfileValue("barSlow", currentIndex) }
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: _T("Dashboard Fast"); color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            ComboBox { Layout.preferredWidth: 120; model: root.control._pollProfileLabels("dashboardFast"); currentIndex: root.control._pollProfileIndex("dashboardFast", root.control.config.dashboardFastPollMs); onActivated: root.control.config.dashboardFastPollMs = root.control._pollProfileValue("dashboardFast", currentIndex) }
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: _T("Dashboard Medium"); color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            ComboBox { Layout.preferredWidth: 120; model: root.control._pollProfileLabels("dashboardMedium"); currentIndex: root.control._pollProfileIndex("dashboardMedium", root.control.config.dashboardMediumPollMs); onActivated: root.control.config.dashboardMediumPollMs = root.control._pollProfileValue("dashboardMedium", currentIndex) }
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: _T("Dashboard Slow"); color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            ComboBox { Layout.preferredWidth: 120; model: root.control._pollProfileLabels("dashboardSlow"); currentIndex: root.control._pollProfileIndex("dashboardSlow", root.control.config.dashboardSlowPollMs); onActivated: root.control.config.dashboardSlowPollMs = root.control._pollProfileValue("dashboardSlow", currentIndex) }
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: _T("Quick Sidebar"); color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            ComboBox { Layout.preferredWidth: 120; model: root.control._pollProfileLabels("quickSidebar"); currentIndex: root.control._pollProfileIndex("quickSidebar", root.control.config.quickSidebarPollMs); onActivated: root.control.config.quickSidebarPollMs = root.control._pollProfileValue("quickSidebar", currentIndex) }
        }

        Item { implicitHeight: 8 }
    }
}
