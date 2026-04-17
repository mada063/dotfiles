import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "Common.js" as Common
import "./theme" as ThemeParts

ScrollView {
    id: root

    required property QtObject control

    clip: true

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
        spacing: 12

        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: root.control.shell.detectedWindowManagerName
                    color: root.control.config.textColor
                    font.bold: true
                }

                Label {
                    text: "Changes are written to `~/.config/hypr/quickshell-generated.conf`, then Hyprland is reloaded."
                    color: root.control.config.mutedTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }

            Button {
                text: "Apply Now"
                onClicked: root.control.shell.queueHyprlandSync()
            }
        }

        StyledCheckBox {
            text: "Enable shell-managed Hyprland settings"
            control: root.control
            checked: root.control.config.hyprlandManagedEnabled
            onToggled: root.control.config.hyprlandManagedEnabled = checked
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: decorationContent.implicitHeight + 20
            color: "transparent"
            border.width: root.control.config.overlayBorderWidth
            border.color: root.control.config.mutedTextColor
            radius: root.control.config.rounding

            ColumnLayout {
                id: decorationContent
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Label { text: "Decoration"; color: root.control.config.overlayAccentColor; font.bold: true }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 4
                    rowSpacing: 8
                    columnSpacing: 10

                    Label { text: "Gaps In"; color: root.control.config.textColor }
                    SpinBox { from: 0; to: 40; value: Number(root.control.config.hyprlandDecoration.gapsIn || 0); onValueModified: root._updateDecoration("gapsIn", value) }
                    Label { text: "Gaps Out"; color: root.control.config.textColor }
                    SpinBox { from: 0; to: 60; value: Number(root.control.config.hyprlandDecoration.gapsOut || 0); onValueModified: root._updateDecoration("gapsOut", value) }

                    Label { text: "Border Size"; color: root.control.config.textColor }
                    SpinBox { from: 0; to: 12; value: Number(root.control.config.hyprlandDecoration.borderSize || 0); onValueModified: root._updateDecoration("borderSize", value) }
                    Label { text: "Rounding"; color: root.control.config.textColor }
                    SpinBox { from: 0; to: 40; value: Number(root.control.config.hyprlandDecoration.rounding || 0); onValueModified: root._updateDecoration("rounding", value) }

                    Label { text: "Blur Size"; color: root.control.config.textColor }
                    SpinBox { from: 0; to: 20; value: Number(root.control.config.hyprlandDecoration.blurSize || 0); onValueModified: root._updateDecoration("blurSize", value) }
                    Label { text: "Blur Passes"; color: root.control.config.textColor }
                    SpinBox { from: 0; to: 4; value: Number(root.control.config.hyprlandDecoration.blurPasses || 0); onValueModified: root._updateDecoration("blurPasses", value) }
                }

                StyledCheckBox {
                    text: "Enable blur"
                    control: root.control
                    checked: Boolean(root.control.config.hyprlandDecoration.blurEnabled)
                    onToggled: root._updateDecoration("blurEnabled", checked)
                }

                ThemeParts.ThemeColorRow {
                    Layout.fillWidth: true
                    config: root.control.config
                    labelText: "Active Border Color"
                    colorValue: String(root.control.config.hyprlandDecoration.activeBorderColor || "#ff8c32")
                    options: ["#ff8c32", "#41aefc", "#0073cd", "#22c55e", "#14b8a6", "#a855f7", "#f59e0b", "#ffffff", "#444444"]
                    onColorChanged: value => root._updateDecoration("activeBorderColor", value)
                }

                ThemeParts.ThemeColorRow {
                    Layout.fillWidth: true
                    config: root.control.config
                    labelText: "Inactive Border Color"
                    colorValue: String(root.control.config.hyprlandDecoration.inactiveBorderColor || "#444444")
                    options: ["#444444", "#a1a1aa", "#18181b", "#0f0f12", "#41aefc", "#0073cd", "#ff8c32", "#ffffff"]
                    onColorChanged: value => root._updateDecoration("inactiveBorderColor", value)
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: monitorHelpContent.implicitHeight + 20
            color: "transparent"
            border.width: root.control.config.overlayBorderWidth
            border.color: root.control.config.mutedTextColor
            radius: root.control.config.rounding

            ColumnLayout {
                id: monitorHelpContent
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Monitors"; color: root.control.config.overlayAccentColor; font.bold: true }
                    Item { Layout.fillWidth: true }
                    Button {
                        text: "Open Screen Settings"
                        onClicked: root.control.currentSectionIndex = 1
                    }
                }

                Label {
                    text: "Monitor arrangement, preview, dragging, and direct position editing now live in the Screen tab so there is only one place to manage display layout."
                    color: root.control.config.mutedTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Label {
                    text: "Managed monitors: " + String((root.control.config.hyprlandMonitors || []).length)
                    color: root.control.config.textColor
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: bindsSectionContent.implicitHeight + 20
            color: "transparent"
            border.width: root.control.config.overlayBorderWidth
            border.color: root.control.config.mutedTextColor
            radius: root.control.config.rounding

            ColumnLayout {
                id: bindsSectionContent
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Binds"; color: root.control.config.overlayAccentColor; font.bold: true }
                    Item { Layout.fillWidth: true }
                    Button {
                        text: "Add Bind"
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
                        color: "transparent"
                        border.width: root.control.config.buttonBorderWidth
                        border.color: root.control.config.mutedTextColor
                        radius: root.control.config.rounding
                        Layout.fillWidth: true

                        GridLayout {
                            id: bindCardContent
                            anchors.fill: parent
                            anchors.margins: 8
                            columns: 5
                            rowSpacing: 6
                            columnSpacing: 8

                            Label { text: "Mods"; color: root.control.config.textColor }
                            TextField { text: String(modelData.mods || ""); onEditingFinished: root._updateBind(index, "mods", String(text).trim()) }
                            Label { text: "Key"; color: root.control.config.textColor }
                            TextField { text: String(modelData.key || ""); onEditingFinished: root._updateBind(index, "key", String(text).trim()) }
                            Button {
                                text: confirmRemove ? "Confirm" : "Remove"
                                onClicked: {
                                    if (!confirmRemove) {
                                        confirmRemove = true;
                                        return;
                                    }
                                    let next = root._copy(root.control.config.hyprlandBinds || []);
                                    next.splice(index, 1);
                                    root.control.config.hyprlandBinds = next;
                                }
                            }
                            Button { text: "Cancel"; visible: confirmRemove; onClicked: confirmRemove = false }

                            Label { text: "Dispatcher"; color: root.control.config.textColor }
                            TextField { text: String(modelData.dispatcher || "exec"); onEditingFinished: root._updateBind(index, "dispatcher", String(text).trim() || "exec") }
                            Label { text: "Argument"; color: root.control.config.textColor }
                            TextField {
                                Layout.columnSpan: 2
                                Layout.fillWidth: true
                                text: String(modelData.argument || "")
                                onEditingFinished: root._updateBind(index, "argument", String(text))
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: rulesSectionContent.implicitHeight + 20
            color: "transparent"
            border.width: root.control.config.overlayBorderWidth
            border.color: root.control.config.mutedTextColor
            radius: root.control.config.rounding

            ColumnLayout {
                id: rulesSectionContent
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Label { text: "Workspace Rules"; color: root.control.config.overlayAccentColor; font.bold: true }
                    Item { Layout.fillWidth: true }
                    Button {
                        text: "Add Rule"
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
                        color: "transparent"
                        border.width: root.control.config.buttonBorderWidth
                        border.color: root.control.config.mutedTextColor
                        radius: root.control.config.rounding
                        Layout.fillWidth: true

                        ColumnLayout {
                            id: ruleCardContent
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Label { text: "Rule " + (index + 1); color: root.control.config.textColor; font.bold: true }
                                Item { Layout.fillWidth: true }
                                Button {
                                    text: confirmRemove ? "Confirm" : "Remove"
                                    onClicked: {
                                        if (!confirmRemove) {
                                            confirmRemove = true;
                                            return;
                                        }
                                        let next = root._copy(root.control.config.hyprlandWorkspaceRules || []);
                                        next.splice(index, 1);
                                        root.control.config.hyprlandWorkspaceRules = next;
                                    }
                                }
                                Button { text: "Cancel"; visible: confirmRemove; onClicked: confirmRemove = false }
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 4
                                rowSpacing: 6
                                columnSpacing: 8

                                Label { text: "Workspace"; color: root.control.config.textColor }
                                TextField { text: String(modelData.workspace || ""); onEditingFinished: root._updateWorkspaceRule(index, "workspace", String(text).trim()) }
                                Label { text: "Monitor"; color: root.control.config.textColor }
                                TextField { text: String(modelData.monitor || ""); onEditingFinished: root._updateWorkspaceRule(index, "monitor", String(text).trim()) }

                                Label { text: "Name"; color: root.control.config.textColor }
                                TextField {
                                    Layout.columnSpan: 3
                                    Layout.fillWidth: true
                                    text: String(modelData.defaultName || "")
                                    onEditingFinished: root._updateWorkspaceRule(index, "defaultName", String(text).trim())
                                }
                            }

                            RowLayout {
                                StyledCheckBox {
                                    text: "Persistent"
                                    control: root.control
                                    checked: Boolean(modelData.persistent)
                                    onToggled: root._updateWorkspaceRule(index, "persistent", checked)
                                }
                                StyledCheckBox {
                                    text: "Default"
                                    control: root.control
                                    checked: Boolean(modelData.isDefault)
                                    onToggled: root._updateWorkspaceRule(index, "isDefault", checked)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
