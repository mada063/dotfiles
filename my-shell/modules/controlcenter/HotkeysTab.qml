import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
    id: root

    required property QtObject control
    property string recordingSequenceKey: ""

    clip: true

    readonly property var hotkeyDefaults: ({
        controlCenterHotkey: "Ctrl+Alt+C",
        dashboardHotkey: "Ctrl+Alt+D",
        sidebarHotkey: "Ctrl+Alt+B"
    })

    readonly property var hotkeyRows: [
        {
            title: "Control Center",
            subtitle: "Open or close the settings window from anywhere.",
            enabledKey: "controlCenterEnableHotkey",
            sequenceKey: "controlCenterHotkey"
        },
        {
            title: "Dashboard",
            subtitle: "Toggle the dashboard overlay quickly.",
            enabledKey: "dashboardEnableHotkey",
            sequenceKey: "dashboardHotkey"
        },
        {
            title: "Quick Sidebar",
            subtitle: "Open the right-edge sidebar without using edge hover.",
            enabledKey: "sidebarEnableHotkey",
            sequenceKey: "sidebarHotkey"
        }
    ]

    function _sequenceValue(sequenceKey) {
        return String(root.control.config[sequenceKey] || "");
    }

    function _setSequence(sequenceKey, value) {
        root.control.config[sequenceKey] = String(value || "").trim();
    }

    function _resetSequence(sequenceKey) {
        root._setSequence(sequenceKey, root.hotkeyDefaults[sequenceKey] || "");
    }

    function _isModifierKey(key) {
        return key === Qt.Key_Control || key === Qt.Key_Shift || key === Qt.Key_Alt
            || key === Qt.Key_Meta || key === Qt.Key_Super_L || key === Qt.Key_Super_R;
    }

    function _keyName(key) {
        if (key >= Qt.Key_A && key <= Qt.Key_Z)
            return String.fromCharCode(key);
        if (key >= Qt.Key_0 && key <= Qt.Key_9)
            return String.fromCharCode(key);
        if (key >= Qt.Key_F1 && key <= Qt.Key_F35)
            return "F" + String(key - Qt.Key_F1 + 1);
        switch (key) {
        case Qt.Key_Return:
        case Qt.Key_Enter:
            return "Return";
        case Qt.Key_Space:
            return "Space";
        case Qt.Key_Tab:
            return "Tab";
        case Qt.Key_Backtab:
            return "Backtab";
        case Qt.Key_Backspace:
            return "Backspace";
        case Qt.Key_Delete:
            return "Delete";
        case Qt.Key_Insert:
            return "Insert";
        case Qt.Key_Escape:
            return "Esc";
        case Qt.Key_Home:
            return "Home";
        case Qt.Key_End:
            return "End";
        case Qt.Key_PageUp:
            return "PgUp";
        case Qt.Key_PageDown:
            return "PgDown";
        case Qt.Key_Left:
            return "Left";
        case Qt.Key_Right:
            return "Right";
        case Qt.Key_Up:
            return "Up";
        case Qt.Key_Down:
            return "Down";
        case Qt.Key_Plus:
            return "Plus";
        case Qt.Key_Minus:
            return "Minus";
        case Qt.Key_Equal:
            return "Equal";
        case Qt.Key_Comma:
            return "Comma";
        case Qt.Key_Period:
            return "Period";
        case Qt.Key_Slash:
            return "Slash";
        case Qt.Key_Backslash:
            return "Backslash";
        case Qt.Key_Semicolon:
            return "Semicolon";
        case Qt.Key_Apostrophe:
            return "Apostrophe";
        case Qt.Key_BracketLeft:
            return "BracketLeft";
        case Qt.Key_BracketRight:
            return "BracketRight";
        case Qt.Key_QuoteLeft:
            return "QuoteLeft";
        default:
            return "";
        }
    }

    function _sequenceFromEvent(event) {
        const keyName = root._keyName(event.key);
        if (!keyName.length || root._isModifierKey(event.key))
            return "";
        let parts = [];
        if (event.modifiers & Qt.ControlModifier)
            parts.push("Ctrl");
        if (event.modifiers & Qt.AltModifier)
            parts.push("Alt");
        if (event.modifiers & Qt.ShiftModifier)
            parts.push("Shift");
        if (event.modifiers & Qt.MetaModifier)
            parts.push("Meta");
        parts.push(keyName);
        return parts.join("+");
    }

    function _startRecording(sequenceKey, scope) {
        root.recordingSequenceKey = sequenceKey;
        if (scope)
            scope.forceActiveFocus();
    }

    ColumnLayout {
        width: parent.width
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: introCard.implicitHeight + 20
            color: "transparent"
            border.width: root.control.config.overlayBorderWidth
            border.color: root.control.config.mutedTextColor
            radius: root.control.config.rounding

            ColumnLayout {
                id: introCard
                anchors.fill: parent
                anchors.margins: 10
                spacing: 6

                Label { text: "Hotkeys"; color: root.control.config.textColor; font.bold: true }
                Label {
                    text: "These map directly to the live shell shortcuts. Click Record and press the combination you want to use."
                    color: root.control.config.mutedTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        Repeater {
            model: root.hotkeyRows
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: hotkeyCardContent.implicitHeight + 20
                color: "transparent"
                border.width: root.control.config.overlayBorderWidth
                border.color: root.control.config.mutedTextColor
                radius: root.control.config.rounding

                ColumnLayout {
                    id: hotkeyCardContent
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Label { text: modelData.title; color: root.control.config.overlayAccentColor; font.bold: true }
                            Label {
                                text: modelData.subtitle
                                color: root.control.config.mutedTextColor
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        StyledCheckBox {
                            text: "Enabled"
                            control: root.control
                            checked: Boolean(root.control.config[modelData.enabledKey])
                            onToggled: root.control.config[modelData.enabledKey] = checked
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        FocusScope {
                            id: captureScope
                            Layout.fillWidth: true
                            implicitHeight: recordButton.implicitHeight
                            activeFocusOnTab: true

                            Keys.onPressed: event => {
                                if (root.recordingSequenceKey !== modelData.sequenceKey)
                                    return;
                                event.accepted = true;
                                if (event.key === Qt.Key_Escape && event.modifiers === Qt.NoModifier) {
                                    root.recordingSequenceKey = "";
                                    return;
                                }
                                const sequence = root._sequenceFromEvent(event);
                                if (!sequence.length)
                                    return;
                                root._setSequence(modelData.sequenceKey, sequence);
                                root.recordingSequenceKey = "";
                            }

                            onActiveFocusChanged: {
                                if (!activeFocus && root.recordingSequenceKey === modelData.sequenceKey)
                                    root.recordingSequenceKey = "";
                            }

                            Button {
                                id: recordButton
                                anchors.fill: parent
                                text: root.recordingSequenceKey === modelData.sequenceKey
                                    ? "Press shortcut..."
                                    : (root._sequenceValue(modelData.sequenceKey).length > 0
                                        ? root._sequenceValue(modelData.sequenceKey)
                                        : "Record shortcut")
                                onClicked: root._startRecording(modelData.sequenceKey, captureScope)
                            }
                        }

                        Button {
                            text: "Default"
                            onClicked: root._resetSequence(modelData.sequenceKey)
                        }

                        Button {
                            text: "Clear"
                            onClicked: root._setSequence(modelData.sequenceKey, "")
                        }
                    }

                    Label {
                        text: root.recordingSequenceKey === modelData.sequenceKey
                            ? "Recording: press a shortcut, or Esc to cancel."
                            : "Current sequence: " + (root._sequenceValue(modelData.sequenceKey).length > 0 ? root._sequenceValue(modelData.sequenceKey) : "None")
                        color: root.control.config.textColor
                    }
                }
            }
        }
    }
}
