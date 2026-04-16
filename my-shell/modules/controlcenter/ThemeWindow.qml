import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell
import Quickshell.Wayland

import "./theme" as ThemeParts
import "Common.js" as Common

PanelWindow {
    id: root

    required property QtObject shell
    required property QtObject config
    focusable: true
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    readonly property string uiFontFamily: root.config.fontFamily
    readonly property int uiFontSize: root.config.fontPixelSize

    property string selectedThemeId: root.config.activeThemeId
    property var draftTheme: root.shell.createThemeFromCurrent("Draft")
    property string loadedThemeSignature: ""
    property string appliedThemeSignature: ""
    property string pendingThemeId: ""
    property bool pendingWindowClose: false
    property bool showDiscardPrompt: false
    property bool confirmDelete: false
    property int editorTab: 0
    property int componentTab: 0
    readonly property string draftThemeSignature: _themeSignature(root.draftTheme)
    readonly property bool hasUnsavedChanges: draftThemeSignature !== loadedThemeSignature
    readonly property bool isDraftApplied: draftThemeSignature === appliedThemeSignature

    function _copy(value) {
        return Common.deepCopy(value);
    }

    function _library() {
        return root.config.themeLibrary || [];
    }

    function _themeSignature(theme) {
        return JSON.stringify(root.shell.normalizeTheme(theme || {}));
    }

    function _syncAppliedThemeSignature() {
        root.appliedThemeSignature = _themeSignature(root.shell.createThemeFromCurrent("Applied", "applied"));
    }

    function _applyFontRecursive(node) {
        if (!node)
            return;
        try {
            if (node.font !== undefined) {
                node.font.family = root.uiFontFamily;
                node.font.pixelSize = root.uiFontSize;
            }
        } catch (e) {}
        const kids = node.children || [];
        for (let i = 0; i < kids.length; i++)
            _applyFontRecursive(kids[i]);
        if (node.contentItem)
            _applyFontRecursive(node.contentItem);
    }

    function _loadTheme(themeId) {
        const themes = _library();
        const id = String(themeId || "");
        for (let i = 0; i < themes.length; i++) {
            if (String(themes[i].id) !== id)
                continue;
            root.selectedThemeId = id;
            root.draftTheme = _copy(themes[i]);
            root.loadedThemeSignature = _themeSignature(themes[i]);
            root.confirmDelete = false;
            return;
        }
        root.draftTheme = root.shell.createThemeFromCurrent("Draft");
        root.loadedThemeSignature = _themeSignature(root.draftTheme);
        root.confirmDelete = false;
    }

    function _updateDraft(key, value) {
        let next = _copy(root.draftTheme || {});
        next[key] = value;
        root.draftTheme = next;
        root.confirmDelete = false;
    }

    function _updateDraftNum(key, value) {
        const n = Number(value);
        root._updateDraft(key, Number.isFinite(n) ? n : 0);
    }

    function _studioFill() {
        return Qt.rgba(root.config.accentColor.r, root.config.accentColor.g, root.config.accentColor.b, 0.06);
    }

    function _applyWallpaperFromDraft() {
        root.shell.applyWallpaper(String(root.draftTheme.wallpaperPath || ""));
    }

    function _newThemeFromCurrent() {
        const id = "theme-" + Date.now();
        root.selectedThemeId = id;
        root.draftTheme = root.shell.createThemeFromCurrent("New Theme", id);
        root.loadedThemeSignature = _themeSignature(root.draftTheme);
        root.confirmDelete = false;
    }

    function _saveDraft() {
        const next = _copy(root.draftTheme || {});
        if (!String(next.id || "").length)
            next.id = "theme-" + Date.now();
        if (!String(next.name || "").trim().length)
            next.name = "Custom Theme";
        const savedId = root.shell.saveTheme(next);
        _loadTheme(savedId);
        _syncAppliedThemeSignature();
    }

    function _requestThemeLoad(themeId) {
        if (root.hasUnsavedChanges) {
            root.pendingThemeId = String(themeId || "");
            root.pendingWindowClose = false;
            root.showDiscardPrompt = true;
            return;
        }
        _loadTheme(themeId);
    }

    function _requestClose() {
        if (root.hasUnsavedChanges) {
            root.pendingThemeId = "";
            root.pendingWindowClose = true;
            root.showDiscardPrompt = true;
            return;
        }
        root.shell.themeWindowVisible = false;
    }

    function _resolveDiscard(discardChanges) {
        if (!discardChanges) {
            root.pendingThemeId = "";
            root.pendingWindowClose = false;
            root.showDiscardPrompt = false;
            return;
        }
        const nextThemeId = root.pendingThemeId;
        const shouldClose = root.pendingWindowClose;
        root.pendingThemeId = "";
        root.pendingWindowClose = false;
        root.showDiscardPrompt = false;
        if (nextThemeId.length > 0) {
            _loadTheme(nextThemeId);
            return;
        }
        if (shouldClose)
            root.shell.themeWindowVisible = false;
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "#00000000"

    onVisibleChanged: {
        if (visible) {
            _loadTheme(root.config.activeThemeId);
            _syncAppliedThemeSignature();
            _applyFontRecursive(root);
        } else {
            root.showDiscardPrompt = false;
            root.pendingThemeId = "";
            root.pendingWindowClose = false;
            root.confirmDelete = false;
        }
    }
    onDraftThemeChanged: {
        themeNameField.text = String(root.draftTheme.name || "");
        wallPathField.text = String(root.draftTheme.wallpaperPath || "");
    }
    onUiFontFamilyChanged: _applyFontRecursive(root)
    onUiFontSizeChanged: _applyFontRecursive(root)
    Component.onCompleted: _applyFontRecursive(root)

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, root.config.overlayDimOpacity)

        MouseArea {
            anchors.fill: parent
            onClicked: root._requestClose()
        }
    }

    Rectangle {
        width: Math.min(parent.width - 56, 1220)
        height: Math.min(parent.height - 56, 900)
        anchors.centerIn: parent
        color: root.config.panelColor
        border.color: root.config.accentColor
        border.width: root.config.borderWidth
        radius: root.config.rounding
        opacity: root.config.panelOpacity

        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 270
                Layout.fillHeight: true
                color: root._studioFill()
                border.width: root.config.overlayBorderWidth
                border.color: root.config.accentColor
                radius: root.config.rounding

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    Label {
                        text: "Theme Studio"
                        color: root.config.textColor
                        font.bold: true
                    }

                    Label {
                        text: (_library().length || 0) + " saved theme" + ((_library().length || 0) === 1 ? "" : "s")
                        color: root.config.mutedTextColor
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Button {
                            text: "New"
                            onClicked: root._newThemeFromCurrent()
                        }
                        Button {
                            text: "Duplicate"
                            enabled: root.selectedThemeId.length > 0
                            onClicked: {
                                const nextId = root.shell.duplicateTheme(root.selectedThemeId);
                                if (nextId)
                                    root._loadTheme(nextId);
                            }
                        }
                    }

                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        ListView {
                            model: root._library()
                            spacing: 6
                            delegate: Rectangle {
                                required property var modelData
                                width: ListView.view.width - 8
                                height: 58
                                radius: root.config.rounding
                                color: String(root.selectedThemeId) === String(modelData.id)
                                    ? Qt.rgba(root.config.accentColor.r, root.config.accentColor.g, root.config.accentColor.b, 0.12)
                                    : "transparent"
                                border.width: root.config.buttonBorderWidth
                                border.color: String(root.config.activeThemeId) === String(modelData.id)
                                    ? root.config.accentColor
                                    : root.config.mutedTextColor

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 4

                                    Label {
                                        text: modelData.name
                                        color: root.config.textColor
                                        font.bold: true
                                    }

                                    Row {
                                        spacing: 6

                                        Repeater {
                                            model: [
                                                modelData.backgroundColor,
                                                modelData.accentColor,
                                                modelData.textColor,
                                                modelData.workspaceAccentColor,
                                                modelData.overlayAccentColor
                                            ]
                                            delegate: Rectangle {
                                                required property var modelData
                                                width: 14
                                                height: 14
                                                radius: 3
                                                color: modelData
                                                border.width: 1
                                                border.color: root.config.mutedTextColor
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: root._requestThemeLoad(parent.modelData.id)
                                }
                            }
                        }

                        Label {
                            visible: root._library().length < 1
                            width: parent.width
                            text: "No saved themes yet. Create one from your current shell colors and save it."
                            color: root.config.mutedTextColor
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: root._studioFill()
                border.width: root.config.overlayBorderWidth
                border.color: root.config.accentColor
                radius: root.config.rounding

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Repeater {
                            model: ["General", "Background", "Components"]
                            delegate: Button {
                                required property int index
                                required property string modelData
                                text: modelData
                                Layout.preferredHeight: 30
                                onClicked: root.editorTab = index
                                background: Rectangle {
                                    radius: Math.max(0, root.config.rounding - 2)
                                    color: root.editorTab === index
                                        ? Qt.rgba(root.config.accentColor.r, root.config.accentColor.g, root.config.accentColor.b, 0.2)
                                        : "transparent"
                                    border.width: root.config.buttonBorderWidth
                                    border.color: root.editorTab === index ? root.config.accentColor : root.config.mutedTextColor
                                }
                                contentItem: Label {
                                    text: modelData
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    color: root.editorTab === index ? root.config.accentColor : root.config.textColor
                                    font.bold: root.editorTab === index
                                }
                            }
                        }
                    }

                    StackLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        currentIndex: root.editorTab

                        ScrollView {
                            clip: true
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            ColumnLayout {
                                width: parent.width
                                spacing: 12

                                RowLayout {
                                    Layout.fillWidth: true
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 4
                                        Label {
                                            text: "Theme editor"
                                            color: root.config.textColor
                                            font.bold: true
                                        }
                                        Label {
                                            text: root.hasUnsavedChanges ? "Unsaved changes" : (root.isDraftApplied ? "Applied to shell" : "Saved theme")
                                            color: root.hasUnsavedChanges ? root.config.accentColor : root.config.mutedTextColor
                                        }
                                    }
                                    Button {
                                        text: root.isDraftApplied ? "Applied" : "Apply"
                                        onClicked: {
                                            root.shell.applyThemeObject(root.draftTheme);
                                            root._syncAppliedThemeSignature();
                                        }
                                    }
                                    Button {
                                        text: root.hasUnsavedChanges ? "Save" : "Saved"
                                        onClicked: root._saveDraft()
                                    }
                                    Button {
                                        text: root.confirmDelete ? "Confirm Delete" : "Delete"
                                        enabled: root._library().length > 1 && root.selectedThemeId.length > 0
                                        onClicked: {
                                            if (!root.confirmDelete) {
                                                root.confirmDelete = true;
                                                return;
                                            }
                                            root.shell.deleteTheme(root.selectedThemeId);
                                            root._loadTheme(root.config.activeThemeId);
                                            root._syncAppliedThemeSignature();
                                            root.confirmDelete = false;
                                        }
                                    }
                                    Button {
                                        text: "Cancel"
                                        visible: root.confirmDelete
                                        onClicked: root.confirmDelete = false
                                    }
                                    Button {
                                        text: "Close"
                                        onClicked: root._requestClose()
                                    }
                                }

                                Label { text: "Name"; color: root.config.textColor }
                                TextField {
                                    id: themeNameField
                                    Layout.fillWidth: true
                                    text: ""
                                    onEditingFinished: root._updateDraft("name", text)
                                }

                                Label { text: "Mode"; color: root.config.textColor }
                                ComboBox {
                                    model: ["dark", "light", "auto"]
                                    currentIndex: Math.max(0, model.indexOf(String(root.draftTheme.themeMode || "dark")))
                                    onActivated: root._updateDraft("themeMode", currentText)
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: previewCard.implicitHeight + 16
                                    color: root._studioFill()
                                    border.width: root.config.overlayBorderWidth
                                    border.color: root.config.accentColor
                                    radius: root.config.rounding

                                    ColumnLayout {
                                        id: previewCard
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 8

                                        Label { text: "Preview"; color: root.config.accentColor; font.bold: true }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            implicitHeight: 50
                                            radius: Number(root.draftTheme.rounding !== undefined ? root.draftTheme.rounding : root.config.rounding)
                                            color: String(root.draftTheme.backgroundColor || root.config.backgroundColor)
                                            border.width: Number(root.draftTheme.borderWidth !== undefined ? root.draftTheme.borderWidth : root.config.borderWidth)
                                            border.color: String(root.draftTheme.borderColor || root.config.borderColor)

                                            Row {
                                                anchors.fill: parent
                                                anchors.margins: 8
                                                spacing: 8

                                                Rectangle {
                                                    width: 38
                                                    height: 24
                                                    radius: Number(root.draftTheme.rounding !== undefined ? root.draftTheme.rounding : root.config.rounding)
                                                    color: String(root.draftTheme.workspaceAccentColor || root.config.workspaceAccentColor)
                                                    border.width: Number(root.draftTheme.buttonBorderWidth !== undefined ? root.draftTheme.buttonBorderWidth : root.config.buttonBorderWidth)
                                                    border.color: String(root.draftTheme.borderColor || root.config.borderColor)
                                                    Label {
                                                        anchors.centerIn: parent
                                                        text: "1"
                                                        font.bold: true
                                                        color: String(root.draftTheme.workspaceColor || root.config.workspaceColor)
                                                    }
                                                }

                                                Rectangle {
                                                    width: 96
                                                    height: 24
                                                    radius: Number(root.draftTheme.rounding !== undefined ? root.draftTheme.rounding : root.config.rounding)
                                                    color: "transparent"
                                                    border.width: Number(root.draftTheme.buttonBorderWidth !== undefined ? root.draftTheme.buttonBorderWidth : root.config.buttonBorderWidth)
                                                    border.color: String(root.draftTheme.overlayAccentColor || root.config.overlayAccentColor)
                                                    Label {
                                                        anchors.centerIn: parent
                                                        text: "WIFI"
                                                        color: String(root.draftTheme.textColor || root.config.textColor)
                                                    }
                                                }

                                                Rectangle {
                                                    width: 86
                                                    height: 24
                                                    radius: Number(root.draftTheme.rounding !== undefined ? root.draftTheme.rounding : root.config.rounding)
                                                    color: "transparent"
                                                    border.width: Number(root.draftTheme.buttonBorderWidth !== undefined ? root.draftTheme.buttonBorderWidth : root.config.buttonBorderWidth)
                                                    border.color: String(root.draftTheme.dashboardColor || root.config.dashboardColor)
                                                    Label {
                                                        anchors.centerIn: parent
                                                        text: "DASH"
                                                        color: String(root.draftTheme.textColor || root.config.textColor)
                                                    }
                                                }
                                            }
                                        }

                                        Label {
                                            text: "Matches dashboard-style cards: soft accent fill and accent border."
                                            color: root.config.mutedTextColor
                                            wrapMode: Text.WordWrap
                                            Layout.fillWidth: true
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: geomCard.implicitHeight + 16
                                    color: root._studioFill()
                                    border.width: root.config.overlayBorderWidth
                                    border.color: root.config.accentColor
                                    radius: root.config.rounding

                                    ColumnLayout {
                                        id: geomCard
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 8

                                        Label { text: "Geometry & chrome"; color: root.config.accentColor; font.bold: true }

                                        GridLayout {
                                            columns: 4
                                            rowSpacing: 8
                                            columnSpacing: 10

                                            Label { text: "Rounding"; color: root.config.textColor }
                                            SpinBox {
                                                from: 0
                                                to: 24
                                                value: Number(root.draftTheme.rounding !== undefined ? root.draftTheme.rounding : root.config.rounding)
                                                onValueModified: root._updateDraftNum("rounding", value)
                                            }
                                            Label { text: "Border"; color: root.config.textColor }
                                            SpinBox {
                                                from: 0
                                                to: 4
                                                value: Number(root.draftTheme.borderWidth !== undefined ? root.draftTheme.borderWidth : root.config.borderWidth)
                                                onValueModified: root._updateDraftNum("borderWidth", value)
                                            }
                                            Label { text: "Button border"; color: root.config.textColor }
                                            SpinBox {
                                                from: 0
                                                to: 4
                                                value: Number(root.draftTheme.buttonBorderWidth !== undefined ? root.draftTheme.buttonBorderWidth : root.config.buttonBorderWidth)
                                                onValueModified: root._updateDraftNum("buttonBorderWidth", value)
                                            }
                                            Label { text: "Overlay border"; color: root.config.textColor }
                                            SpinBox {
                                                from: 0
                                                to: 6
                                                value: Number(root.draftTheme.overlayBorderWidth !== undefined ? root.draftTheme.overlayBorderWidth : root.config.overlayBorderWidth)
                                                onValueModified: root._updateDraftNum("overlayBorderWidth", value)
                                            }
                                            Label { text: "Panel opacity %"; color: root.config.textColor }
                                            SpinBox {
                                                from: 55
                                                to: 100
                                                value: Math.round(100 * Number(root.draftTheme.panelOpacity !== undefined ? root.draftTheme.panelOpacity : root.config.panelOpacity))
                                                onValueModified: root._updateDraftNum("panelOpacity", Math.max(0.55, Math.min(1, value / 100)))
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: genActions.implicitHeight + 16
                                    color: root._studioFill()
                                    border.width: root.config.overlayBorderWidth
                                    border.color: root.config.accentColor
                                    radius: root.config.rounding

                                    ColumnLayout {
                                        id: genActions
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 8

                                        Label { text: "Actions"; color: root.config.accentColor; font.bold: true }
                                        Button {
                                            text: "Pull live shell into draft"
                                            onClicked: root.draftTheme = root.shell.createThemeFromCurrent(String(root.draftTheme.name || "Custom Theme"), String(root.draftTheme.id || ("theme-" + Date.now())))
                                        }
                                        Button {
                                            text: "Apply selected library theme"
                                            enabled: root.selectedThemeId.length > 0
                                            onClicked: root.shell.setActiveThemeById(root.selectedThemeId)
                                        }
                                        Label {
                                            text: "Apply pushes the draft to the running shell. Save stores it in your library."
                                            color: root.config.mutedTextColor
                                            wrapMode: Text.WordWrap
                                            Layout.fillWidth: true
                                        }
                                    }
                                }
                            }
                        }

                        ScrollView {
                            clip: true
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            ColumnLayout {
                                width: parent.width
                                spacing: 12

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: bgCard.implicitHeight + 16
                                    color: root._studioFill()
                                    border.width: root.config.overlayBorderWidth
                                    border.color: root.config.accentColor
                                    radius: root.config.rounding

                                    ColumnLayout {
                                        id: bgCard
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 8

                                        Label { text: "Desktop & panels"; color: root.config.accentColor; font.bold: true }
                                        ThemeParts.ThemeColorRow {
                                            Layout.fillWidth: true
                                            config: root.config
                                            labelText: "Desktop background"
                                            colorValue: String(root.draftTheme.backgroundColor || "#0f0f12")
                                            options: ["#0f0f12", "#1a1a1f", "#23232a", "#061826", "#0f172a", "#111827", "#f8fafc", "#ffffff"]
                                            onColorChanged: value => root._updateDraft("backgroundColor", value)
                                        }
                                        ThemeParts.ThemeColorRow {
                                            Layout.fillWidth: true
                                            config: root.config
                                            labelText: "Bar / panel fill (override)"
                                            colorValue: String(root.draftTheme.panelColor || root.draftTheme.backgroundColor || "#0f0f12")
                                            options: ["#0f0f12", "#1a1a1f", "#23232a", "#111827", "#18181b", "#f8fafc", "#ffffff", "#0c4a6e", "#1e1b4b"]
                                            onColorChanged: value => root._updateDraft("panelColor", value)
                                        }
                                        Button {
                                            text: "Use desktop color for panels (clear override)"
                                            onClicked: root._updateDraft("panelColor", "")
                                        }
                                        ThemeParts.ThemeColorRow {
                                            Layout.fillWidth: true
                                            config: root.config
                                            labelText: "Muted text (override)"
                                            colorValue: String(root.draftTheme.mutedTextColor || (root.draftTheme.themeMode === "light" ? "#52525b" : "#a1a1aa"))
                                            options: ["#a1a1aa", "#71717a", "#52525b", "#64748b", "#94a3b8", "#78716c", "#57534e"]
                                            onColorChanged: value => root._updateDraft("mutedTextColor", value)
                                        }
                                        Button {
                                            text: "Auto muted text from mode"
                                            onClicked: root._updateDraft("mutedTextColor", "")
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: wallCard.implicitHeight + 16
                                    color: root._studioFill()
                                    border.width: root.config.overlayBorderWidth
                                    border.color: root.config.accentColor
                                    radius: root.config.rounding

                                    ColumnLayout {
                                        id: wallCard
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 8

                                        Label { text: "Wallpaper (hyprpaper)"; color: root.config.accentColor; font.bold: true }
                                        Label {
                                            text: "Stored in the theme. Apply theme or tap “Set wallpaper” to push to Hyprland."
                                            color: root.config.mutedTextColor
                                            wrapMode: Text.WordWrap
                                            Layout.fillWidth: true
                                        }
                                        RowLayout {
                                            Layout.fillWidth: true
                                            TextField {
                                                id: wallPathField
                                                Layout.fillWidth: true
                                                placeholderText: "/path/to/image.jpg"
                                                onEditingFinished: root._updateDraft("wallpaperPath", text.trim())
                                            }
                                            Button {
                                                text: "Browse…"
                                                onClicked: wallFileDialog.open()
                                            }
                                            Button {
                                                text: "Set wallpaper"
                                                onClicked: root._applyWallpaperFromDraft()
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: dimCard.implicitHeight + 16
                                    color: root._studioFill()
                                    border.width: root.config.overlayBorderWidth
                                    border.color: root.config.accentColor
                                    radius: root.config.rounding

                                    ColumnLayout {
                                        id: dimCard
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 8

                                        Label { text: "Overlay dim"; color: root.config.accentColor; font.bold: true }
                                        RowLayout {
                                            Label { text: "Dim behind panels %"; color: root.config.textColor }
                                            SpinBox {
                                                from: 0
                                                to: 90
                                                value: Math.round(100 * Number(root.draftTheme.overlayDimOpacity !== undefined ? root.draftTheme.overlayDimOpacity : root.config.overlayDimOpacity))
                                                onValueModified: root._updateDraftNum("overlayDimOpacity", value / 100)
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        ScrollView {
                            clip: true
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            ColumnLayout {
                                width: parent.width
                                spacing: 12

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Repeater {
                                        model: ["Bar", "Workspaces", "Dashboard", "Sidebar & audio"]
                                        delegate: Button {
                                            required property int index
                                            required property string modelData
                                            Layout.fillWidth: true
                                            Layout.minimumWidth: 72
                                            text: modelData
                                            onClicked: root.componentTab = index
                                            background: Rectangle {
                                                radius: Math.max(0, root.config.rounding - 2)
                                                color: root.componentTab === index
                                                    ? Qt.rgba(root.config.accentColor.r, root.config.accentColor.g, root.config.accentColor.b, 0.18)
                                                    : "transparent"
                                                border.width: root.config.buttonBorderWidth
                                                border.color: root.componentTab === index ? root.config.accentColor : root.config.mutedTextColor
                                            }
                                            contentItem: Label {
                                                text: modelData
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                                color: root.componentTab === index ? root.config.accentColor : root.config.textColor
                                                font.bold: root.componentTab === index
                                            }
                                        }
                                    }
                                }

                                StackLayout {
                                    Layout.fillWidth: true
                                    Layout.minimumHeight: 420
                                    Layout.preferredHeight: 520
                                    currentIndex: root.componentTab

                                    Rectangle {
                                        color: root._studioFill()
                                        border.width: root.config.overlayBorderWidth
                                        border.color: root.config.accentColor
                                        radius: root.config.rounding
                                        clip: true
                                        ColumnLayout {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.margins: 8
                                            spacing: 10
                                            Label { text: "Top bar & chrome"; color: root.config.accentColor; font.bold: true }
                                            ThemeParts.ThemeColorRow {
                                                Layout.fillWidth: true
                                                config: root.config
                                                labelText: "Accent"
                                                colorValue: String(root.draftTheme.accentColor || "#ff8c32")
                                                options: ["#ff8c32", "#f97316", "#22c55e", "#3b82f6", "#41aefc", "#0073cd", "#a855f7", "#e11d48", "#14b8a6", "#f59e0b"]
                                                onColorChanged: value => root._updateDraft("accentColor", value)
                                            }
                                            ThemeParts.ThemeColorRow {
                                                Layout.fillWidth: true
                                                config: root.config
                                                labelText: "Border"
                                                colorValue: String(root.draftTheme.borderColor || "#ff8c32")
                                                options: ["#ff8c32", "#41aefc", "#0073cd", "#a1a1aa", "#ffffff", "#18181b", "#3b82f6", "#22c55e"]
                                                onColorChanged: value => root._updateDraft("borderColor", value)
                                            }
                                            ThemeParts.ThemeColorRow {
                                                Layout.fillWidth: true
                                                config: root.config
                                                labelText: "Primary text"
                                                colorValue: String(root.draftTheme.textColor || "#e5e7eb")
                                                options: ["#be5103", "#dbeafe", "#bfdbfe", "#e4e4e7", "#ffffff", "#18181b", "#a1a1aa", "#fef3c7"]
                                                onColorChanged: value => root._updateDraft("textColor", value)
                                            }
                                        }
                                    }

                                    Rectangle {
                                        color: root._studioFill()
                                        border.width: root.config.overlayBorderWidth
                                        border.color: root.config.accentColor
                                        radius: root.config.rounding
                                        clip: true
                                        ColumnLayout {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.margins: 8
                                            spacing: 10
                                            Label { text: "Workspace pills"; color: root.config.accentColor; font.bold: true }
                                            ThemeParts.ThemeColorRow {
                                                Layout.fillWidth: true
                                                config: root.config
                                                labelText: "Active background"
                                                colorValue: String(root.draftTheme.workspaceAccentColor || "#ff8c32")
                                                options: ["#ff8c32", "#f97316", "#22c55e", "#14b8a6", "#3b82f6", "#41aefc", "#0073cd", "#60a5fa", "#a855f7", "#e11d48"]
                                                onColorChanged: value => root._updateDraft("workspaceAccentColor", value)
                                            }
                                            ThemeParts.ThemeColorRow {
                                                Layout.fillWidth: true
                                                config: root.config
                                                labelText: "Label text"
                                                colorValue: String(root.draftTheme.workspaceColor || "#111827")
                                                options: ["#111827", "#082f49", "#0c4a6e", "#ffffff", "#18181b", "#e4e4e7", "#dbeafe", "#bfdbfe", "#fef3c7"]
                                                onColorChanged: value => root._updateDraft("workspaceColor", value)
                                            }
                                        }
                                    }

                                    Rectangle {
                                        color: root._studioFill()
                                        border.width: root.config.overlayBorderWidth
                                        border.color: root.config.accentColor
                                        radius: root.config.rounding
                                        clip: true
                                        ColumnLayout {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.margins: 8
                                            spacing: 10
                                            Label { text: "Dashboard & overlays"; color: root.config.accentColor; font.bold: true }
                                            ThemeParts.ThemeColorRow {
                                                Layout.fillWidth: true
                                                config: root.config
                                                labelText: "Dashboard accent"
                                                colorValue: String(root.draftTheme.dashboardColor || "#41aefc")
                                                options: ["#41aefc", "#0073cd", "#60a5fa", "#22c55e", "#ff8c32", "#f97316", "#a855f7", "#14b8a6"]
                                                onColorChanged: value => root._updateDraft("dashboardColor", value)
                                            }
                                            ThemeParts.ThemeColorRow {
                                                Layout.fillWidth: true
                                                config: root.config
                                                labelText: "Overlay accent"
                                                colorValue: String(root.draftTheme.overlayAccentColor || "#ff8c32")
                                                options: ["#ff8c32", "#41aefc", "#0073cd", "#22c55e", "#14b8a6", "#a855f7", "#e11d48", "#f59e0b"]
                                                onColorChanged: value => root._updateDraft("overlayAccentColor", value)
                                            }
                                        }
                                    }

                                    Rectangle {
                                        color: root._studioFill()
                                        border.width: root.config.overlayBorderWidth
                                        border.color: root.config.accentColor
                                        radius: root.config.rounding
                                        clip: true
                                        ColumnLayout {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.margins: 8
                                            spacing: 10
                                            Label { text: "Quick sidebar & volume"; color: root.config.accentColor; font.bold: true }
                                            ThemeParts.ThemeColorRow {
                                                Layout.fillWidth: true
                                                config: root.config
                                                labelText: "Quick sidebar"
                                                colorValue: String(root.draftTheme.quickSidebarColor || "#ff8c32")
                                                options: ["#ff8c32", "#f97316", "#22c55e", "#14b8a6", "#3b82f6", "#41aefc", "#0073cd", "#60a5fa", "#a855f7", "#e11d48"]
                                                onColorChanged: value => root._updateDraft("quickSidebarColor", value)
                                            }
                                            ThemeParts.ThemeColorRow {
                                                Layout.fillWidth: true
                                                config: root.config
                                                labelText: "Volume highlight"
                                                colorValue: String(root.draftTheme.volumeColor || "#ff8c32")
                                                options: ["#ff8c32", "#f97316", "#22c55e", "#14b8a6", "#3b82f6", "#41aefc", "#0073cd", "#60a5fa", "#a855f7", "#e11d48"]
                                                onColorChanged: value => root._updateDraft("volumeColor", value)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    FileDialog {
        id: wallFileDialog
        title: "Choose wallpaper"
        nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.bmp)"]
        onAccepted: {
            const u = wallFileDialog.selectedFile.toString();
            const path = u.startsWith("file://") ? decodeURIComponent(u.replace(/^file:\/\//, "")) : u;
            root._updateDraft("wallpaperPath", path);
        }
    }

    Rectangle {
        visible: root.showDiscardPrompt
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.22)

        MouseArea {
            anchors.fill: parent
        }

        Rectangle {
            width: Math.min(parent.width - 80, 420)
            anchors.centerIn: parent
            implicitHeight: discardContent.implicitHeight + 20
            color: root.config.panelColor
            border.width: root.config.overlayBorderWidth
            border.color: root.config.accentColor
            radius: root.config.rounding

            ColumnLayout {
                id: discardContent
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Label { text: "Discard changes?"; color: root.config.textColor; font.bold: true }
                Label {
                    text: "Your draft has unsaved changes. Discard them before leaving this theme?"
                    color: root.config.mutedTextColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    Button { text: "Keep Editing"; onClicked: root._resolveDiscard(false) }
                    Button { text: "Discard"; onClicked: root._resolveDiscard(true) }
                }
            }
        }
    }
}
