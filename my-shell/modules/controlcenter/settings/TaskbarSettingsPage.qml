import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../shared" as Shared

Item {
    id: root
    required property QtObject control
    function _T(s) { return root.control.config.formatUiText(s); }
    function _barVisible(id) { return (root.control.config.barOverlayVisibility || {})[id] !== false; }
    function _setBarVisible(id, visible) { root.control.shell.setBarOverlayVisible(id, visible); }
    function _timeHasSeconds() { return String(root.control.config.overlayTimeFormat || "").indexOf("%S") >= 0; }
    function _setShowSeconds(enabled) {
        const has = _timeHasSeconds();
        if (enabled && !has)
            root.control.config.overlayTimeFormat = String(root.control.config.overlayTimeFormat || "%H:%M") + ":%S";
        else if (!enabled && has)
            root.control.config.overlayTimeFormat = String(root.control.config.overlayTimeFormat || "%H:%M:%S").replace(":%S", "");
    }
    function _showDate() { return String(root.control.config.overlayDateTimeFormat || "date-time") !== "time"; }
    function _setShowDate(enabled) {
        const mode = String(root.control.config.overlayDateTimeFormat || "date-time");
        if (enabled)
            root.control.config.overlayDateTimeFormat = mode === "time" ? "date-time" : mode;
        else
            root.control.config.overlayDateTimeFormat = "time";
    }
    property int visibleWorkspaceCount: Math.max(1, Number(root.control.config.workspaceVisibleCount) || 8)
    readonly property var barOptions: [
        { id: "workspace", label: "Workspace" },
        { id: "clock", label: "Clock" },
        { id: "wifi", label: "Wifi" },
        { id: "bluetooth", label: "Bluetooth" },
        { id: "audio", label: "Audio" },
        { id: "battery", label: "Battery" },
        { id: "locks", label: "Locks" }
    ]
    function _optionActive(id) {
        return id === "workspace" ? root.control.config.workspaceSegmentVisible : root._barVisible(id);
    }
    function _toggleOption(id) {
        if (id === "workspace")
            root.control.config.workspaceSegmentVisible = !root.control.config.workspaceSegmentVisible;
        else
            root._setBarVisible(id, !root._barVisible(id));
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 12

        Label { text: root._T("Taskbar"); color: root.control.config.accentColor; font.bold: true; font.family: root.control.uiFontFamily }

        Flow {
            Layout.fillWidth: true
            spacing: 8
            Repeater {
                model: root.barOptions
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool active: root._optionActive(String(modelData.id))
                    property bool tileHovered: optionHover.containsMouse
                    width: 114
                    height: 50
                    radius: Math.max(0, root.control.config.overlayRounding - 2)
                    color: active ? root.control.config.quickSettingsButtonActiveColor : root.control.config.quickSettingsButtonInactiveColor
                    border.width: root.control.config.buttonBorderWidth
                    border.color: tileHovered
                        ? root.control.config.quickSettingsButtonHoverEffectColor
                        : (active ? root.control.config.buttonActiveBorderColor : root.control.config.buttonBorderColor)
                    scale: tileHovered ? 1.02 : 1
                    Behavior on scale { NumberAnimation { duration: 100 } }
                    Label {
                        anchors.centerIn: parent
                        text: root._T(String(modelData.label))
                        color: active ? root.control.config.buttonActiveTextColor : root.control.config.buttonTextColor
                        font.family: root.control.uiFontFamily
                    }
                    MouseArea {
                        id: optionHover
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root._toggleOption(String(modelData.id))
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                implicitHeight: workspaceColumn.implicitHeight + 24
                radius: root.control.config.overlayRounding
                color: Qt.rgba(root.control.config.overlayBackgroundColor.r, root.control.config.overlayBackgroundColor.g, root.control.config.overlayBackgroundColor.b, 0.22)
                border.color: root.control.config.buttonBorderColor
                border.width: root.control.config.buttonBorderWidth
                ColumnLayout {
                    id: workspaceColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 8
                    Label { text: root._T("Workspace"); color: root.control.config.accentColor; font.bold: true; font.family: root.control.uiFontFamily }
                    RowLayout {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        Label { text: root._T("Shown"); Layout.fillWidth: true; color: root.control.config.textColor }
                        SpinBox {
                            from: 1
                            to: 20
                            value: root.visibleWorkspaceCount
                            onValueModified: {
                                root.visibleWorkspaceCount = value;
                                root.control.config.workspaceVisibleCount = value;
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        Label { text: root._T("Per monitor workspace"); Layout.fillWidth: true; color: root.control.config.textColor }
                        Shared.SwitchPill {
                            checked: !root.control.config.workspaceShowAllScreens
                            rounding: root.control.config.rounding
                            onColor: root.control.config.buttonActiveBackgroundColor
                            offColor: root.control.config.buttonBackgroundColor
                            onBorderColor: root.control.config.buttonActiveBorderColor
                            offBorderColor: root.control.config.buttonBorderColor
                            onKnobColor: root.control.config.buttonActiveTextColor
                            offKnobColor: root.control.config.buttonTextColor
                            onToggled: root.control.config.workspaceShowAllScreens = checked
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        Label { text: root._T("Occupied background"); Layout.fillWidth: true; color: root.control.config.textColor }
                        Shared.SwitchPill {
                            checked: root.control.config.workspaceActiveScreenBackground
                            rounding: root.control.config.rounding
                            onColor: root.control.config.buttonActiveBackgroundColor
                            offColor: root.control.config.buttonBackgroundColor
                            onBorderColor: root.control.config.buttonActiveBorderColor
                            offBorderColor: root.control.config.buttonBorderColor
                            onKnobColor: root.control.config.buttonActiveTextColor
                            offKnobColor: root.control.config.buttonTextColor
                            onToggled: root.control.config.workspaceActiveScreenBackground = !root.control.config.workspaceActiveScreenBackground
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        Label { text: root._T("Active indicator"); Layout.fillWidth: true; color: root.control.config.textColor }
                        Shared.SwitchPill {
                            checked: root.control.config.workspaceHighlightCurrent
                            rounding: root.control.config.rounding
                            onColor: root.control.config.buttonActiveBackgroundColor
                            offColor: root.control.config.buttonBackgroundColor
                            onBorderColor: root.control.config.buttonActiveBorderColor
                            offBorderColor: root.control.config.buttonBorderColor
                            onKnobColor: root.control.config.buttonActiveTextColor
                            offKnobColor: root.control.config.buttonTextColor
                            onToggled: root.control.config.workspaceHighlightCurrent = !root.control.config.workspaceHighlightCurrent
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        Label { text: root._T("Show windows"); Layout.fillWidth: true; color: root.control.config.textColor }
                        Shared.SwitchPill {
                            checked: root.control.config.workspaceShowWindowIcons
                            rounding: root.control.config.rounding
                            onColor: root.control.config.buttonActiveBackgroundColor
                            offColor: root.control.config.buttonBackgroundColor
                            onBorderColor: root.control.config.buttonActiveBorderColor
                            offBorderColor: root.control.config.buttonBorderColor
                            onKnobColor: root.control.config.buttonActiveTextColor
                            offKnobColor: root.control.config.buttonTextColor
                            onToggled: root.control.config.workspaceShowWindowIcons = !root.control.config.workspaceShowWindowIcons
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        opacity: root.control.config.workspaceShowWindowIcons ? 1 : 0.45
                        Label { text: root._T("Max icons"); Layout.fillWidth: true; color: root.control.config.textColor }
                        SpinBox {
                            from: 0
                            to: 5
                            value: Math.max(0, Number(root.control.config.workspaceMaxIcons) || 1)
                            enabled: root.control.config.workspaceShowWindowIcons
                            onValueModified: root.control.config.workspaceMaxIcons = value
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        Label { text: root._T("Layout on hover"); Layout.fillWidth: true; color: root.control.config.textColor }
                        Shared.SwitchPill {
                            checked: root.control.config.workspaceShowLayoutOnHover
                            rounding: root.control.config.rounding
                            onColor: root.control.config.buttonActiveBackgroundColor
                            offColor: root.control.config.buttonBackgroundColor
                            onBorderColor: root.control.config.buttonActiveBorderColor
                            offBorderColor: root.control.config.buttonBorderColor
                            onKnobColor: root.control.config.buttonActiveTextColor
                            offKnobColor: root.control.config.buttonTextColor
                            onToggled: root.control.config.workspaceShowLayoutOnHover = !root.control.config.workspaceShowLayoutOnHover
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                implicitHeight: clockColumn.implicitHeight + 24
                radius: root.control.config.overlayRounding
                color: Qt.rgba(root.control.config.overlayBackgroundColor.r, root.control.config.overlayBackgroundColor.g, root.control.config.overlayBackgroundColor.b, 0.22)
                border.color: root.control.config.buttonBorderColor
                border.width: root.control.config.buttonBorderWidth
                ColumnLayout {
                    id: clockColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 8
                    Label { text: root._T("Clock"); color: root.control.config.accentColor; font.bold: true; font.family: root.control.uiFontFamily }
                    RowLayout {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        Label { text: root._T("Background"); Layout.fillWidth: true; color: root.control.config.textColor }
                        Shared.SwitchPill {
                            checked: root._barVisible("clock")
                            rounding: root.control.config.rounding
                            onColor: root.control.config.buttonActiveBackgroundColor
                            offColor: root.control.config.buttonBackgroundColor
                            onBorderColor: root.control.config.buttonActiveBorderColor
                            offBorderColor: root.control.config.buttonBorderColor
                            onKnobColor: root.control.config.buttonActiveTextColor
                            offKnobColor: root.control.config.buttonTextColor
                            onToggled: root._setBarVisible("clock", !root._barVisible("clock"))
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        Label { text: root._T("Show date"); Layout.fillWidth: true; color: root.control.config.textColor }
                        Shared.SwitchPill {
                            checked: root._showDate()
                            rounding: root.control.config.rounding
                            onColor: root.control.config.buttonActiveBackgroundColor
                            offColor: root.control.config.buttonBackgroundColor
                            onBorderColor: root.control.config.buttonActiveBorderColor
                            offBorderColor: root.control.config.buttonBorderColor
                            onKnobColor: root.control.config.buttonActiveTextColor
                            offKnobColor: root.control.config.buttonTextColor
                            onToggled: root._setShowDate(!root._showDate())
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        implicitHeight: 34
                        Label { text: root._T("Show seconds"); Layout.fillWidth: true; color: root.control.config.textColor }
                        Shared.SwitchPill {
                            checked: root._timeHasSeconds()
                            rounding: root.control.config.rounding
                            onColor: root.control.config.buttonActiveBackgroundColor
                            offColor: root.control.config.buttonBackgroundColor
                            onBorderColor: root.control.config.buttonActiveBorderColor
                            offBorderColor: root.control.config.buttonBorderColor
                            onKnobColor: root.control.config.buttonActiveTextColor
                            offKnobColor: root.control.config.buttonTextColor
                            onToggled: root._setShowSeconds(!root._timeHasSeconds())
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                implicitHeight: miscColumn.implicitHeight + 24
                radius: root.control.config.overlayRounding
                color: Qt.rgba(root.control.config.overlayBackgroundColor.r, root.control.config.overlayBackgroundColor.g, root.control.config.overlayBackgroundColor.b, 0.22)
                border.color: root.control.config.buttonBorderColor
                border.width: root.control.config.buttonBorderWidth
                ColumnLayout {
                    id: miscColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 8
                    Label { text: root._T("Undefined"); color: root.control.config.accentColor; font.bold: true; font.family: root.control.uiFontFamily }
                    Label { text: root._T("Reserved for upcoming workspace behavior settings."); color: root.control.config.mutedTextColor; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                }
            }
        }
    }
}
