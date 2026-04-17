import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property QtObject shell
    required property QtObject config
    focusable: true
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    readonly property string uiFontFamily: root.config.fontFamily
    readonly property int uiFontSize: root.config.fontPixelSize
    property int currentSectionIndex: 0
    readonly property bool showWindowManagerSettings: root.shell.detectedWindowManagerKey === "hyprland"
    readonly property bool showScreenSettings: root.shell.detectedWindowManagerKey === "hyprland"
    readonly property var availableThemes: (root.config.themeLibrary && root.config.themeLibrary.length > 0)
        ? root.config.themeLibrary
        : root.themePresets
    readonly property var settingsSections: {
        let sections = [
            { title: "Appearance" }
        ];
        if (root.showScreenSettings)
            sections.push({ title: "Screen" });
        sections.push({ title: "Behavior" });
        sections.push({ title: "Hotkeys" });
        if (root.showWindowManagerSettings)
            sections.push({ title: root.shell.detectedWindowManagerName });
        return sections;
    }
    readonly property int effectiveSectionIndex: Math.max(0, Math.min(root.currentSectionIndex, root.settingsSections.length - 1))
    property int accentR: 249
    property int accentG: 115
    property int accentB: 22
    readonly property var themePresets: [
        {
            name: "Amber Night",
            themeMode: "dark",
            accentColor: "#ff8c32",
            borderColor: "#ff8c32",
            backgroundColor: "#0f0f12",
            textColor: "#be5103",
            workspaceAccentColor: "#ff8c32",
            workspaceColor: "#111827",
            volumeColor: "#ff8c32",
            quickSidebarColor: "#ff8c32",
            dashboardColor: "#41aefc",
            overlayAccentColor: "#ff8c32"
        },
        {
            name: "Forest",
            themeMode: "dark",
            accentColor: "#4ade80",
            borderColor: "#4ade80",
            backgroundColor: "#0b1410",
            textColor: "#d1fae5",
            workspaceAccentColor: "#22c55e",
            workspaceColor: "#052e16",
            volumeColor: "#4ade80",
            quickSidebarColor: "#22c55e",
            dashboardColor: "#60a5fa",
            overlayAccentColor: "#4ade80"
        },
        {
            name: "Ocean",
            themeMode: "dark",
            accentColor: "#38bdf8",
            borderColor: "#38bdf8",
            backgroundColor: "#0b1220",
            textColor: "#dbeafe",
            workspaceAccentColor: "#0ea5e9",
            workspaceColor: "#082f49",
            volumeColor: "#60a5fa",
            quickSidebarColor: "#38bdf8",
            dashboardColor: "#0073cd",
            overlayAccentColor: "#38bdf8"
        },
        {
            name: "Plum",
            themeMode: "dark",
            accentColor: "#c084fc",
            borderColor: "#c084fc",
            backgroundColor: "#140f1f",
            textColor: "#f3e8ff",
            workspaceAccentColor: "#a855f7",
            workspaceColor: "#2e1065",
            volumeColor: "#d8b4fe",
            quickSidebarColor: "#c084fc",
            dashboardColor: "#41aefc",
            overlayAccentColor: "#c084fc"
        },
        {
            name: "Paper Light",
            themeMode: "light",
            accentColor: "#ea580c",
            borderColor: "#ea580c",
            backgroundColor: "#f8fafc",
            textColor: "#7c2d12",
            workspaceAccentColor: "#fb923c",
            workspaceColor: "#fff7ed",
            volumeColor: "#ea580c",
            quickSidebarColor: "#f97316",
            dashboardColor: "#0073cd",
            overlayAccentColor: "#ea580c"
        }
    ]
    readonly property string activeThemePresetName: _activeThemePresetName()
    readonly property var pollProfiles: ({
        workspace: [
            { label: "Realtime", value: 120 },
            { label: "High", value: 250 },
            { label: "Medium", value: 450 },
            { label: "Low", value: 800 }
        ],
        barMedium: [
            { label: "Realtime", value: 200 },
            { label: "High", value: 400 },
            { label: "Medium", value: 700 },
            { label: "Low", value: 1200 }
        ],
        barSlow: [
            { label: "Realtime", value: 300 },
            { label: "High", value: 900 },
            { label: "Medium", value: 1800 },
            { label: "Low", value: 3200 }
        ],
        dashboardFast: [
            { label: "Realtime", value: 300 },
            { label: "High", value: 800 },
            { label: "Medium", value: 1200 },
            { label: "Low", value: 2000 }
        ],
        dashboardMedium: [
            { label: "Realtime", value: 1000 },
            { label: "High", value: 1800 },
            { label: "Medium", value: 2400 },
            { label: "Low", value: 4000 }
        ],
        dashboardSlow: [
            { label: "Realtime", value: 3000 },
            { label: "High", value: 4200 },
            { label: "Medium", value: 4800 },
            { label: "Low", value: 7000 }
        ],
        quickSidebar: [
            { label: "Realtime", value: 200 },
            { label: "High", value: 500 },
            { label: "Medium", value: 1200 },
            { label: "Low", value: 2000 }
        ]
    })

    function _hex2(n) {
        const s = Number(n).toString(16);
        return s.length < 2 ? "0" + s : s;
    }

    function _syncAccentFromConfig() {
        const value = String(root.config.accentColor || "#f97316");
        if (!/^#[0-9a-fA-F]{6}$/.test(value))
            return;
        accentR = parseInt(value.slice(1, 3), 16);
        accentG = parseInt(value.slice(3, 5), 16);
        accentB = parseInt(value.slice(5, 7), 16);
    }

    function _applyAccentFromRgb() {
        root.config.accentColor = "#" + _hex2(accentR) + _hex2(accentG) + _hex2(accentB);
    }

    function _normColor(value) {
        return String(value || "").trim().toLowerCase();
    }

    function _applyThemePreset(preset) {
        if (!preset)
            return;
        if (preset.id)
            root.shell.setActiveThemeById(preset.id);
        else
            root.shell.applyThemeObject(preset);
        _syncAccentFromConfig();
    }

    function _activeThemePresetName() {
        for (let i = 0; i < availableThemes.length; i++) {
            const preset = availableThemes[i];
            if (String(preset.id) === String(root.config.activeThemeId))
                return preset.name;
        }
        return "Custom";
    }

    function _pollProfileList(kind) {
        return root.pollProfiles[kind] || root.pollProfiles.barMedium;
    }

    function _pollProfileLabels(kind) {
        const items = _pollProfileList(kind);
        let labels = [];
        for (let i = 0; i < items.length; i++)
            labels.push(items[i].label);
        return labels;
    }

    function _pollProfileValue(kind, index) {
        const items = _pollProfileList(kind);
        const safeIndex = Math.max(0, Math.min(items.length - 1, index));
        return items[safeIndex].value;
    }

    function _pollProfileIndex(kind, currentValue) {
        const items = _pollProfileList(kind);
        let bestIndex = 0;
        let bestDiff = Math.abs(Number(currentValue) - Number(items[0].value));
        for (let i = 1; i < items.length; i++) {
            const diff = Math.abs(Number(currentValue) - Number(items[i].value));
            if (diff < bestDiff) {
                bestDiff = diff;
                bestIndex = i;
            }
        }
        return bestIndex;
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

    onUiFontFamilyChanged: _applyFontRecursive(root)
    onUiFontSizeChanged: _applyFontRecursive(root)
    onShowWindowManagerSettingsChanged: {
        if (!showWindowManagerSettings && currentSectionIndex >= settingsSections.length)
            currentSectionIndex = settingsSections.length - 1;
    }
    onShowScreenSettingsChanged: {
        if (!showScreenSettings && currentSectionIndex >= settingsSections.length)
            currentSectionIndex = settingsSections.length - 1;
    }
    onVisibleChanged: {
        if (visible)
            _syncAccentFromConfig();
    }
    Component.onCompleted: {
        _applyFontRecursive(root);
        _syncAccentFromConfig();
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "#00000000"

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, root.config.overlayDimOpacity)

        MouseArea {
            anchors.fill: parent
            onClicked: root.shell.controlCenterVisible = false
        }
    }

    Rectangle {
        width: Math.min(parent.width - 48, 1120)
        height: Math.min(parent.height - 48, 860)
        anchors.centerIn: parent
        focus: true
        color: root.config.panelColor
        border.color: root.config.accentColor
        border.width: root.config.borderWidth
        opacity: root.config.panelOpacity
        radius: root.config.rounding

        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 220
                Layout.fillHeight: true
                color: Qt.rgba(root.config.accentColor.r, root.config.accentColor.g, root.config.accentColor.b, 0.06)
                border.color: root.config.accentColor
                border.width: root.config.overlayBorderWidth
                radius: root.config.rounding

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    Label {
                        text: "Settings"
                        color: root.config.textColor
                        font.bold: true
                    }

                    Repeater {
                        model: root.settingsSections
                        delegate: Button {
                            required property var modelData
                            required property int index
                            Layout.fillWidth: true
                            implicitHeight: 34
                            focusPolicy: Qt.StrongFocus
                            text: modelData.title
                            onClicked: root.currentSectionIndex = index

                            background: Rectangle {
                                radius: Math.max(0, root.config.rounding - 2)
                                color: index === root.currentSectionIndex
                                    ? Qt.rgba(root.config.accentColor.r, root.config.accentColor.g, root.config.accentColor.b, 0.16)
                                    : "transparent"
                                border.width: root.config.buttonBorderWidth
                                border.color: (index === root.currentSectionIndex || parent.activeFocus)
                                    ? root.config.accentColor
                                    : root.config.mutedTextColor
                            }

                            contentItem: Label {
                                text: modelData.title
                                color: index === root.currentSectionIndex ? root.config.accentColor : root.config.textColor
                                font.bold: index === root.currentSectionIndex
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Button {
                        text: "Close"
                        Layout.fillWidth: true
                        onClicked: root.shell.controlCenterVisible = false
                    }
                }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.effectiveSectionIndex

                AppearanceTab { control: root }
                Loader {
                    active: root.showScreenSettings
                    sourceComponent: Component {
                        ScreenTab { control: root }
                    }
                }
                BehaviorTab { control: root }
                HotkeysTab { control: root }
                Loader {
                    active: root.showWindowManagerSettings
                    sourceComponent: Component {
                        HyprlandTab { control: root }
                    }
                }
            }
        }
    }
}
