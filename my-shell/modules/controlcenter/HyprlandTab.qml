import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Common.js" as Common
import "./theme" as ThemeParts

ScrollView {
    id: root

    required property QtObject control

    clip: true

    function _T(s) { return root.control.config.formatUiText(s); }

    function _copy(value) { return Common.deepCopy(value); }

    function _updateDecoration(key, value) {
        let next = _copy(root.control.config.hyprlandDecoration || {});
        next[key] = value;
        root.control.config.hyprlandDecoration = next;
    }

    function _updateBind(index, key, value) {
        let next = _copy(root.control.config.hyprlandBinds || []);
        if (!next[index])
            next[index] = {};
        next[index][key] = value;
        root.control.config.hyprlandBinds = next;
    }

    function _updateWorkspaceRule(index, key, value) {
        let next = _copy(root.control.config.hyprlandWorkspaceRules || []);
        if (!next[index])
            next[index] = {};
        next[index][key] = value;
        root.control.config.hyprlandWorkspaceRules = next;
    }

    ColumnLayout {
        width: parent.width
        spacing: 0

        // ── Header ────────────────────────────────────────────────────

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 4

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Label {
                    text: root.control.shell.detectedWindowManagerName
                    color: root.control.config.accentColor
                    font.bold: true
                }
                Label {
                    visible: root.control.config.hyprlandShowInfoMessage
                    text: _T("Changes are written to `~/.config/hypr/quickshell-generated.conf`, then Hyprland is reloaded.")
                    color: root.control.config.mutedTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            Button {
                text: _T("Apply now")
                onClicked: root.control.shell.queueHyprlandSync()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            Layout.bottomMargin: 12
            StyledCheckBox {
                text: _T("Enable shell-managed Hyprland settings")
                control: root.control
                checked: root.control.config.hyprlandManagedEnabled
                onToggled: root.control.config.hyprlandManagedEnabled = checked
            }
            Item { Layout.fillWidth: true }
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            Layout.bottomMargin: 12
            StyledCheckBox {
                text: _T("Disable Hyprland splash")
                control: root.control
                checked: root.control.config.hyprlandDisableSplash
                onToggled: root.control.config.hyprlandDisableSplash = checked
            }
            Item { Layout.fillWidth: true }
        }

        // ── Decoration ────────────────────────────────────────────────

        Label { text: _T("Decoration"); color: root.control.config.accentColor; font.bold: true; Layout.bottomMargin: 8 }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: _T("Gaps in"); color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            SpinBox { from: 0; to: 40; value: Number(root.control.config.hyprlandDecoration.gapsIn || 0); onValueModified: root._updateDecoration("gapsIn", value) }
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: _T("Gaps out"); color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            SpinBox { from: 0; to: 60; value: Number(root.control.config.hyprlandDecoration.gapsOut || 0); onValueModified: root._updateDecoration("gapsOut", value) }
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: _T("Border size"); color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            SpinBox { from: 0; to: 12; value: Number(root.control.config.hyprlandDecoration.borderSize || 0); onValueModified: root._updateDecoration("borderSize", value) }
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: _T("Rounding"); color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            SpinBox { from: 0; to: 40; value: Number(root.control.config.hyprlandDecoration.rounding || 0); onValueModified: root._updateDecoration("rounding", value) }
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: _T("Blur size"); color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            SpinBox { from: 0; to: 20; value: Number(root.control.config.hyprlandDecoration.blurSize || 0); onValueModified: root._updateDecoration("blurSize", value) }
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            spacing: 12
            Label { text: _T("Blur passes"); color: root.control.config.textColor; Layout.fillWidth: true; verticalAlignment: Text.AlignVCenter }
            SpinBox { from: 0; to: 4; value: Number(root.control.config.hyprlandDecoration.blurPasses || 0); onValueModified: root._updateDecoration("blurPasses", value) }
        }

        RowLayout {
            Layout.fillWidth: true
            implicitHeight: 34
            Layout.bottomMargin: 6
            StyledCheckBox {
                text: _T("Enable blur")
                control: root.control
                checked: Boolean(root.control.config.hyprlandDecoration.blurEnabled)
                onToggled: root._updateDecoration("blurEnabled", checked)
            }
            Item { Layout.fillWidth: true }
        }

        ThemeParts.ThemeColorRow {
            Layout.fillWidth: true
            Layout.bottomMargin: 8
            config: root.control.config
            labelText: _T("Active border  ·  follows theme accent")
            colorValue: String(root.control.config.hyprlandDecoration.activeBorderColor || root.control.config.accentColor)
            options: ["#ff8c32", "#41aefc", "#0073cd", "#22c55e", "#14b8a6", "#a855f7", "#f59e0b", "#ffffff", "#444444"]
            onColorChanged: value => root._updateDecoration("activeBorderColor", value)
        }

        ThemeParts.ThemeColorRow {
            Layout.fillWidth: true
            Layout.bottomMargin: 18
            config: root.control.config
            labelText: _T("Inactive border")
            colorValue: String(root.control.config.hyprlandDecoration.inactiveBorderColor || "#444444")
            options: ["#444444", "#a1a1aa", "#18181b", "#0f0f12", "#41aefc", "#0073cd", "#ff8c32", "#ffffff"]
            onColorChanged: value => root._updateDecoration("inactiveBorderColor", value)
        }

        // ── Monitors ──────────────────────────────────────────────────

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 6
            Label { text: _T("Monitors"); color: root.control.config.accentColor; font.bold: true }
            Item { Layout.fillWidth: true }
            Button { text: _T("Screen settings →"); onClicked: root.control.currentSectionIndex = 1 }
        }

        Label {
            text: _T("Monitor arrangement and configuration live in the Screen tab.")
            color: root.control.config.mutedTextColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.bottomMargin: 4
        }

        Label {
            text: _T("Managed monitors:") + " " + String((root.control.config.hyprlandMonitors || []).length)
            color: root.control.config.textColor
            Layout.bottomMargin: 18
        }

        // ── Binds ─────────────────────────────────────────────────────

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 8
            Label { text: _T("Binds"); color: root.control.config.accentColor; font.bold: true }
            Item { Layout.fillWidth: true }
            Button {
                text: _T("Add bind")
                onClicked: {
                    let next = root._copy(root.control.config.hyprlandBinds || []);
                    next.push({ mods: "SUPER", key: "", dispatcher: "exec", argument: "" });
                    root.control.config.hyprlandBinds = next;
                }
            }
        }

        Repeater {
            model: root.control.config.hyprlandBinds || []
            delegate: Rectangle {
                required property var modelData
                required property int index
                property bool confirmRemove: false
                implicitHeight: bindCardContent.implicitHeight + 16
                color: Qt.rgba(root.control.config.accentColor.r, root.control.config.accentColor.g, root.control.config.accentColor.b, 0.04)
                border.width: root.control.config.overlayBorderWidth
                border.color: root.control.config.mutedTextColor
                radius: root.control.config.rounding
                Layout.fillWidth: true
                Layout.bottomMargin: 6

                GridLayout {
                    id: bindCardContent
                    anchors.fill: parent
                    anchors.margins: 8
                    columns: 5
                    rowSpacing: 6
                    columnSpacing: 8

                    Label { text: _T("Mods"); color: root.control.config.textColor }
                    TextField { text: String(modelData.mods || ""); onEditingFinished: root._updateBind(index, "mods", String(text).trim()) }
                    Label { text: _T("Key"); color: root.control.config.textColor }
                    TextField { text: String(modelData.key || ""); onEditingFinished: root._updateBind(index, "key", String(text).trim()) }
                    Button {
                        text: confirmRemove ? _T("Confirm") : _T("Remove")
                        onClicked: {
                            if (!confirmRemove) { confirmRemove = true; return; }
                            let next = root._copy(root.control.config.hyprlandBinds || []);
                            next.splice(index, 1);
                            root.control.config.hyprlandBinds = next;
                        }
                    }
                    Button { text: _T("Cancel"); visible: confirmRemove; onClicked: confirmRemove = false }

                    Label { text: _T("Dispatcher"); color: root.control.config.textColor }
                    TextField { text: String(modelData.dispatcher || "exec"); onEditingFinished: root._updateBind(index, "dispatcher", String(text).trim() || "exec") }
                    Label { text: _T("Argument"); color: root.control.config.textColor }
                    TextField {
                        Layout.columnSpan: 2
                        Layout.fillWidth: true
                        text: String(modelData.argument || "")
                        onEditingFinished: root._updateBind(index, "argument", String(text))
                    }
                }
            }
        }

        Item { implicitHeight: 12 }

        // ── Workspace Rules ───────────────────────────────────────────

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: 8
            Label { text: _T("Workspace rules"); color: root.control.config.accentColor; font.bold: true }
            Item { Layout.fillWidth: true }
            Button {
                text: _T("Add rule")
                onClicked: {
                    let next = root._copy(root.control.config.hyprlandWorkspaceRules || []);
                    next.push({ workspace: "", monitor: "", defaultName: "", persistent: true, isDefault: false });
                    root.control.config.hyprlandWorkspaceRules = next;
                }
            }
        }

        Repeater {
            model: root.control.config.hyprlandWorkspaceRules || []
            delegate: Rectangle {
                required property var modelData
                required property int index
                property bool confirmRemove: false
                implicitHeight: ruleCardContent.implicitHeight + 16
                color: Qt.rgba(root.control.config.accentColor.r, root.control.config.accentColor.g, root.control.config.accentColor.b, 0.04)
                border.width: root.control.config.overlayBorderWidth
                border.color: root.control.config.mutedTextColor
                radius: root.control.config.rounding
                Layout.fillWidth: true
                Layout.bottomMargin: 6

                ColumnLayout {
                    id: ruleCardContent
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Label { text: _T("Rule") + " " + (index + 1); color: root.control.config.textColor; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Button {
                            text: confirmRemove ? _T("Confirm") : _T("Remove")
                            onClicked: {
                                if (!confirmRemove) { confirmRemove = true; return; }
                                let next = root._copy(root.control.config.hyprlandWorkspaceRules || []);
                                next.splice(index, 1);
                                root.control.config.hyprlandWorkspaceRules = next;
                            }
                        }
                        Button { text: _T("Cancel"); visible: confirmRemove; onClicked: confirmRemove = false }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 4
                        rowSpacing: 6
                        columnSpacing: 8

                        Label { text: _T("Workspace"); color: root.control.config.textColor }
                        TextField { text: String(modelData.workspace || ""); onEditingFinished: root._updateWorkspaceRule(index, "workspace", String(text).trim()) }
                        Label { text: _T("Monitor"); color: root.control.config.textColor }
                        TextField { text: String(modelData.monitor || ""); onEditingFinished: root._updateWorkspaceRule(index, "monitor", String(text).trim()) }

                        Label { text: _T("Name"); color: root.control.config.textColor }
                        TextField {
                            Layout.columnSpan: 3
                            Layout.fillWidth: true
                            text: String(modelData.defaultName || "")
                            onEditingFinished: root._updateWorkspaceRule(index, "defaultName", String(text).trim())
                        }
                    }

                    RowLayout {
                        StyledCheckBox {
                            text: _T("Persistent")
                            control: root.control
                            checked: Boolean(modelData.persistent)
                            onToggled: root._updateWorkspaceRule(index, "persistent", checked)
                        }
                        StyledCheckBox {
                            text: _T("Default")
                            control: root.control
                            checked: Boolean(modelData.isDefault)
                            onToggled: root._updateWorkspaceRule(index, "isDefault", checked)
                        }
                    }
                }
            }
        }

        Item { implicitHeight: 8 }
    }
}
