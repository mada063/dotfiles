import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

ScrollView {
    id: root

    required property QtObject control
    property string recordingSequenceKey: ""
    property var windowManagerBinds: []
    property string windowManagerBindError: ""

    clip: true

    readonly property string detectedWindowManagerName: String(root.control.shell.detectedWindowManagerName || "Window Manager")
    readonly property string detectedWindowManagerKey: String(root.control.shell.detectedWindowManagerKey || "unknown")
    readonly property bool supportsLiveWindowManagerBinds: root.detectedWindowManagerKey === "hyprland"
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

    function _refreshWindowManagerBinds() {
        if (!root.supportsLiveWindowManagerBinds) {
            root.windowManagerBinds = [];
            root.windowManagerBindError = "";
            return;
        }
        root.windowManagerBindError = "";
        windowManagerBindsProc.exec({ command: windowManagerBindsProc.command });
    }

    function _hyprModifierNames(modmask) {
        const mask = Number(modmask) || 0;
        let parts = [];
        if (mask & 64)  parts.push("Super");
        if (mask & 4)   parts.push("Ctrl");
        if (mask & 8)   parts.push("Alt");
        if (mask & 1)   parts.push("Shift");
        if (mask & 16)  parts.push("Mod2");
        if (mask & 32)  parts.push("Mod3");
        if (mask & 128) parts.push("Mod5");
        return parts;
    }

    function _hyprKeyName(value) {
        const text = String(value || "").trim();
        if (!text.length)
            return "(none)";
        if (text.length === 1)
            return text.toUpperCase();
        return text.replace(/_/g, " ");
    }

    function _hyprSequence(bind) {
        const modifiers = root._hyprModifierNames(bind ? bind.modmask : 0);
        const keyLabel = bind && bind.mouse ? "Mouse" : root._hyprKeyName(bind ? bind.key : "");
        return (modifiers.length > 0 ? modifiers.join("+") + "+" : "") + keyLabel;
    }

    function _hyprAction(bind) {
        const dispatcher = String(bind && bind.dispatcher || "").trim();
        const arg = String(bind && bind.arg || "").trim();
        return arg.length > 0 ? dispatcher + " " + arg : dispatcher;
    }

    Component.onCompleted: root._refreshWindowManagerBinds()

    Connections {
        target: root.control.shell
        function onDetectedWindowManagerKeyChanged() {
            root._refreshWindowManagerBinds();
        }
    }

    Process {
        id: windowManagerBindsProc
        command: ["bash", "-lc", "if command -v hyprctl >/dev/null 2>&1; then hyprctl binds -j; else echo '[]'; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(String(text).trim() || "[]");
                    root.windowManagerBinds = Array.isArray(parsed) ? parsed : [];
                    root.windowManagerBindError = "";
                } catch (error) {
                    root.windowManagerBinds = [];
                    root.windowManagerBindError = "Could not parse live " + root.detectedWindowManagerName + " binds.";
                }
            }
        }
    }

    ColumnLayout {
        width: parent.width
        spacing: 0

        // ── Shell Hotkeys ─────────────────────────────────────────────

        Label { text: "Shell Hotkeys"; color: root.control.config.accentColor; font.bold: true; Layout.bottomMargin: 4 }

        Label {
            text: root.detectedWindowManagerKey === "hyprland"
                ? "These map to the live shell shortcuts and are written back to Hyprland global binds when shell-managed settings are enabled."
                : "These map directly to the live shell shortcuts. Click Record and press the combination you want."
            color: root.control.config.mutedTextColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.bottomMargin: 10
        }

        Repeater {
            model: root.hotkeyRows
            delegate: ColumnLayout {
                required property var modelData
                Layout.fillWidth: true
                Layout.bottomMargin: 12
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Label { text: modelData.title; color: root.control.config.textColor; font.bold: true }
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
                                ? "Press shortcut…"
                                : (root._sequenceValue(modelData.sequenceKey).length > 0
                                    ? root._sequenceValue(modelData.sequenceKey)
                                    : "Record shortcut")
                            onClicked: root._startRecording(modelData.sequenceKey, captureScope)
                        }
                    }

                    Button { text: "Default"; onClicked: root._resetSequence(modelData.sequenceKey) }
                    Button { text: "Clear"; onClicked: root._setSequence(modelData.sequenceKey, "") }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: root.control.config.mutedTextColor
                    opacity: 0.15
                }
            }
        }

        Item { implicitHeight: 8 }

        // ── Live WM Binds ─────────────────────────────────────────────

        RowLayout {
            Layout.fillWidth: true
            Label { text: root.detectedWindowManagerName + " Binds"; color: root.control.config.accentColor; font.bold: true }
            Item { Layout.fillWidth: true }
            Button { text: "Refresh"; enabled: root.supportsLiveWindowManagerBinds; onClicked: root._refreshWindowManagerBinds() }
        }

        Label {
            text: root.supportsLiveWindowManagerBinds
                ? "Live bindings reported by the current window manager."
                : "Live bind discovery is currently available for Hyprland sessions."
            color: root.control.config.mutedTextColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.bottomMargin: 8
        }

        Label {
            visible: root.windowManagerBindError.length > 0
            text: root.windowManagerBindError
            color: root.control.config.accentColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.topMargin: 4
        }

        Label {
            visible: root.supportsLiveWindowManagerBinds && root.windowManagerBindError.length < 1 && root.windowManagerBinds.length < 1
            text: "No live binds were returned."
            color: root.control.config.mutedTextColor
            Layout.topMargin: 4
        }

        Repeater {
            model: root.supportsLiveWindowManagerBinds ? root.windowManagerBinds : []
            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                implicitHeight: bindRowContent.implicitHeight + 12
                color: "transparent"
                border.width: root.control.config.buttonBorderWidth
                border.color: root.control.config.mutedTextColor
                radius: root.control.config.rounding
                Layout.topMargin: 4

                ColumnLayout {
                    id: bindRowContent
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: root._hyprSequence(modelData); color: root.control.config.textColor; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Label {
                            visible: String(modelData.submap || "").length > 0
                            text: "Submap: " + String(modelData.submap || "")
                            color: root.control.config.mutedTextColor
                        }
                    }

                    Label {
                        text: root._hyprAction(modelData)
                        color: root.control.config.mutedTextColor
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Label {
                        visible: Boolean(modelData.has_description) && String(modelData.description || "").trim().length > 0
                        text: String(modelData.description || "")
                        color: root.control.config.mutedTextColor
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }
        }

        Item { implicitHeight: 8 }
    }
}
