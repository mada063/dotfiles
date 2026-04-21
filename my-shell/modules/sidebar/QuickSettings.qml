import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../shared" as Shared

Item {
    id: root

    required property QtObject shell
    required property QtObject config
    property var notifications: []

    readonly property int edgeMargin: 0
    readonly property int menuW: 400
    readonly property int menuMinH: 100
    readonly property int triggerW: 250
    readonly property int triggerH: 50

    readonly property string uiFontFamily: root.config.fontFamily
    readonly property int uiFontSize: root.config.fontPixelSize
    property bool wifiEnabled: false
    property bool bluetoothEnabled: false
    property bool notificationsSilenced: false
    property var tooltipOwner: null
    property string tooltipPendingText: ""
    property string tooltipDisplayText: ""
    property real tooltipCenterX: 0
    property real tooltipBottomY: 0
    property bool tooltipVisible: false

    // UI state
    property bool tileEditMode: false
    property bool notifExpanded: false
    readonly property bool overlayOpen: root.quickSettingsWindowActive
    readonly property int panelHeightEstimate: quickMenu.implicitHeight

    // All tile definitions (static IDs, dynamic state via functions)
    readonly property var _allTileIds: ["wifi", "bluetooth", "dnd", "wallpaper", "themes", "settings"]

    function _tileLabel(id) {
        if (id === "wifi")      return "Wi-Fi"
        if (id === "bluetooth") return "Bluetooth"
        if (id === "dnd")       return "Silence"
        if (id === "wallpaper") return "Wallpaper"
        if (id === "themes")    return "Themes"
        if (id === "settings")  return "Settings"
        return id
    }

    function _tileIcon(id) {
        if (id === "wifi")      return root.wifiEnabled      ? "\uD83D\uDCF6" : "\u2022"
        if (id === "bluetooth") return root.bluetoothEnabled ? "\u16D2"       : "\u00D7"
        if (id === "dnd")       return root.notificationsSilenced ? "\uD83D\uDD15" : "\uD83D\uDD14"
        if (id === "wallpaper") return "\uD83C\uDFDE"
        if (id === "themes")    return "\u25D0"
        if (id === "settings")  return "\u2699"
        return "?"
    }

    function _tileActive(id) {
        if (id === "wifi")      return root.wifiEnabled
        if (id === "bluetooth") return root.bluetoothEnabled
        if (id === "dnd")       return root.notificationsSilenced
        return false
    }

    function _tileAction(id) {
        if (id === "wifi")      root.toggleWifi()
        else if (id === "bluetooth") root.toggleBluetooth()
        else if (id === "dnd")       root.toggleNotificationsSilenced()
        else if (id === "wallpaper") root.shell.openWallpaperPicker()
        else if (id === "themes")    root.shell.openThemeSelector()
        else if (id === "settings")  root.shell.openControlCenter()
    }

    function _tileVisible(id) {
        const tiles = root.config.quickSettingsTiles || [];
        for (let i = 0; i < tiles.length; i++) {
            if (String(tiles[i].id) === String(id))
                return tiles[i].visible !== false;
        }
        return true;
    }

    readonly property var visibleTileIds: {
        const tiles = root.config.quickSettingsTiles || [];
        return tiles.filter(t => t.visible !== false).map(t => t.id);
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

    function refreshStates() {
        wifiStateProc.exec({ command: wifiStateProc.command });
        bluetoothStateProc.exec({ command: bluetoothStateProc.command });
        notificationsStateProc.exec({ command: notificationsStateProc.command });
    }

    function toggleWifi() {
        const next = !root.wifiEnabled;
        root.wifiEnabled = next;
        wifiToggleProc.exec({ command: ["bash", "-lc", "if command -v nmcli >/dev/null 2>&1; then nmcli radio wifi " + (next ? "on" : "off") + "; fi"] });
        refreshTimer.restart();
    }

    function toggleBluetooth() {
        const next = !root.bluetoothEnabled;
        root.bluetoothEnabled = next;
        bluetoothToggleProc.exec({ command: ["bash", "-lc", "if command -v bluetoothctl >/dev/null 2>&1; then bluetoothctl power " + (next ? "on" : "off") + "; fi"] });
        refreshTimer.restart();
    }

    function toggleNotificationsSilenced() {
        const next = !root.notificationsSilenced;
        root.notificationsSilenced = next;
        notificationsToggleProc.exec({ command: ["bash", "-lc", "if command -v dunstctl >/dev/null 2>&1; then dunstctl set-paused " + (next ? "true" : "false") + "; elif command -v makoctl >/dev/null 2>&1; then if " + (next ? "true" : "false") + "; then makoctl mode -a do-not-disturb 2>/dev/null || makoctl set-mode do-not-disturb 2>/dev/null; else makoctl mode -r do-not-disturb 2>/dev/null || makoctl set-mode default 2>/dev/null; fi; elif command -v swaync-client >/dev/null 2>&1; then swaync-client -d; fi"] });
        refreshTimer.restart();
    }

    readonly property bool quickSettingsActive: root.shell.quickSettingsTriggerHovered || root.shell.quickSettingsOverlayHovered
    property bool quickSettingsWindowActive: quickSettingsActive
    property bool quickSettingsPresented: false

    onQuickSettingsActiveChanged: {
        if (quickSettingsActive) {
            quickSettingsWindowActive = true;
            quickSettingsCloseDebounce.stop();
            quickSettingsHideTimer.stop();
            if (!quickSettingsPresented)
                quickSettingsPresentTimer.restart();
        } else if (quickSettingsWindowActive) {
            quickSettingsCloseDebounce.restart();
        }
    }

    onUiFontFamilyChanged: _applyFontRecursive(menuPanel)
    onUiFontSizeChanged: _applyFontRecursive(menuPanel)
    Component.onCompleted: {
        _applyFontRecursive(menuPanel);
        refreshStates();
    }

    // WlrLayer.Top (=2) is below WlrLayer.Overlay (=3), so menuPanel always receives clicks first.
    PanelWindow {
        id: dismissPanel
        visible: root.quickSettingsWindowActive
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        anchors { top: true; bottom: true; left: true; right: true }
        margins { top: 0; left: 0; right: 0; bottom: 0 }
        exclusiveZone: 0
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            onClicked: root.shell.dismissQuickSettings()
        }
    }

    PanelWindow {
        id: triggerPanel
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        anchors { bottom: true; right: true }
        margins { top: 0; left: 0; right: 0; bottom: 0 }
        implicitWidth: root.triggerW
        implicitHeight: root.triggerH
        exclusiveZone: 0
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onEntered: {
                if (root.quickSettingsActive) {
                    root.shell.cancelQuickSettingsTriggerClose();
                    root.shell.cancelQuickSettingsOverlayClose();
                    return;
                }
                quickSettingsEdgeHold.start();
            }
            onExited: {
                quickSettingsEdgeHold.stop();
                if (!root.shell.quickSettingsOverlayHovered && !root.quickSettingsWindowActive)
                    root.shell.scheduleQuickSettingsTriggerClose();
            }
        }
    }

    PanelWindow {
        id: menuPanel
        visible: root.quickSettingsWindowActive
        focusable: root.quickSettingsWindowActive
        WlrLayershell.keyboardFocus: root.quickSettingsWindowActive ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        anchors { bottom: true; right: true }
        margins { top: 0; left: 0; right: 0; bottom: 0 }
        implicitWidth: root.menuW + root.edgeMargin * 2
        implicitHeight: quickMenu.implicitHeight + root.edgeMargin * 2
        exclusiveZone: 0
        color: "transparent"

        HoverHandler {
            enabled: root.quickSettingsWindowActive
            onHoveredChanged: {
                if (hovered) {
                    root.shell.cancelQuickSettingsTriggerClose();
                    root.shell.cancelQuickSettingsOverlayClose();
                    root.shell.holdQuickSettingsOverlay();
                } else {
                    root.shell.scheduleQuickSettingsTriggerClose();
                    root.shell.scheduleQuickSettingsOverlayClose();
                }
            }
        }

        Rectangle {
            id: quickMenu
            readonly property real hiddenY: parent.height + 8
            width: root.menuW
            implicitHeight: Math.max(root.menuMinH, quickMenuContent.implicitHeight + 28)
            height: implicitHeight
            anchors.right: parent.right
            anchors.rightMargin: root.edgeMargin
            color: root.config.overlayBackgroundColor
            border.color: root.config.overlayAccentColor
            border.width: root.config.overlayBorderWidth
            radius: root.config.overlayRounding
            z: 1
            y: root.quickSettingsPresented ? root.edgeMargin : hiddenY
            Behavior on y {
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }

            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                id: quickMenuContent
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 10

                // ── Tile grid ──────────────────────────────────────────
                Flow {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: root.visibleTileIds
                        delegate: Rectangle {
                            required property string modelData
                            readonly property string tileId: modelData
                            readonly property bool tileActive: root._tileActive(tileId)

                            width: (root.menuW - 28 - 8 * 2) / 3
                            height: 52
                            color: tileActive
                                ? Qt.rgba(root.config.overlayAccentColor.r, root.config.overlayAccentColor.g, root.config.overlayAccentColor.b, 0.22)
                                : Qt.rgba(root.config.overlayTextColor.r, root.config.overlayTextColor.g, root.config.overlayTextColor.b, 0.06)
                            border.color: tileActive ? root.config.overlayAccentColor : root.config.mutedTextColor
                            border.width: root.config.buttonBorderWidth
                            radius: Math.max(0, root.config.overlayRounding - 2)

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 3

                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: root._tileIcon(tileId)
                                    color: tileActive ? root.config.overlayAccentColor : root.config.overlayTextColor
                                    font.family: root.uiFontFamily
                                    font.pixelSize: root.uiFontSize + 6
                                }
                                Label {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: root._tileLabel(tileId)
                                    color: tileActive ? root.config.overlayAccentColor : root.config.mutedTextColor
                                    font.family: root.uiFontFamily
                                    font.pixelSize: root.uiFontSize - 1
                                }
                            }

                            MouseArea {
                                id: tileHoverArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: {
                                    const point = parent.mapToItem(quickMenu, parent.width / 2, 0);
                                    root.tooltipOwner = parent;
                                    root.tooltipPendingText = root._tileLabel(tileId);
                                    root.tooltipDisplayText = "";
                                    root.tooltipVisible = false;
                                    root.tooltipCenterX = point.x;
                                    root.tooltipBottomY = point.y - 6;
                                    tooltipDelay.restart();
                                }
                                onExited: {
                                    if (root.tooltipOwner !== parent)
                                        return;
                                    tooltipDelay.stop();
                                    root.tooltipOwner = null;
                                    root.tooltipPendingText = "";
                                    root.tooltipDisplayText = "";
                                    root.tooltipVisible = false;
                                }
                                onClicked: root._tileAction(tileId)
                            }
                        }
                    }
                }

                // ── Customize tiles row ──────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true

                    Item { Layout.fillWidth: true }

                    Label {
                        text: root.tileEditMode ? "Done" : "Customize"
                        color: root.config.mutedTextColor
                        font.family: root.uiFontFamily
                        font.pixelSize: root.uiFontSize - 1

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            onClicked: root.tileEditMode = !root.tileEditMode
                        }
                    }
                }

                // ── Tile editor (shown when tileEditMode = true) ──────────
                ColumnLayout {
                    visible: root.tileEditMode
                    Layout.fillWidth: true
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Qt.rgba(root.config.overlayAccentColor.r, root.config.overlayAccentColor.g, root.config.overlayAccentColor.b, 0.2)
                    }

                    Item { height: 6 }

                    Repeater {
                        model: [
                            // Both
                            { icon: root._tileIcon("wifi"),      label: "Wi-Fi",      tileId: "wifi",      barId: "wifi" },
                            { icon: root._tileIcon("bluetooth"), label: "Bluetooth",  tileId: "bluetooth", barId: "bluetooth" },
                            // Bar
                            { icon: "\u23F0",                     label: "Clock",                     barId: "clock" },
                            { icon: "\uD83D\uDD0A",              label: "Audio",                     barId: "audio" },
                            { icon: "\uD83D\uDD0B",              label: "Battery",                   barId: "battery" },
                            { icon: "\u21EA",                    label: "Lock State",                barId: "locks" },
                            // Quick Settings
                            { icon: root._tileIcon("dnd"),       label: "Silence",    tileId: "dnd" },
                            { icon: root._tileIcon("wallpaper"), label: "Wallpaper",  tileId: "wallpaper" },
                            { icon: root._tileIcon("themes"),    label: "Themes",     tileId: "themes" },
                            { icon: root._tileIcon("settings"),  label: "Settings",   tileId: "settings" }
                        ]
                        delegate: RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            height: 32
                            spacing: 10

                            Label {
                                text: modelData.icon
                                color: root.config.overlayTextColor
                                font.family: root.uiFontFamily
                                font.pixelSize: root.uiFontSize + 2
                            }
                            Label {
                                text: modelData.label
                                color: root.config.overlayTextColor
                                font.family: root.uiFontFamily
                                font.pixelSize: root.uiFontSize
                                Layout.fillWidth: true
                            }

                            Shared.SwitchPill {
                                checked: modelData.tileId ? root._tileVisible(modelData.tileId) : false
                                enabled: !!modelData.tileId
                                rounding: root.config.rounding
                                onColor: Qt.rgba(root.config.overlayAccentColor.r, root.config.overlayAccentColor.g, root.config.overlayAccentColor.b, 0.7)
                                offColor: Qt.rgba(root.config.overlayTextColor.r, root.config.overlayTextColor.g, root.config.overlayTextColor.b, 0.12)
                                onBorderColor: root.config.overlayAccentColor
                                offBorderColor: root.config.mutedTextColor
                                onKnobColor: root.config.overlayAccentColor
                                offKnobColor: root.config.mutedTextColor
                                opacity: modelData.tileId ? 1 : 0
                                onToggled: if (modelData.tileId) root.shell.setQuickSettingsTileVisible(modelData.tileId, !root._tileVisible(modelData.tileId))
                            }

                            Shared.SwitchPill {
                                checked: modelData.barId ? ((root.config.barOverlayVisibility || {})[modelData.barId] !== false) : false
                                enabled: !!modelData.barId
                                rounding: root.config.rounding
                                onColor: Qt.rgba(root.config.overlayAccentColor.r, root.config.overlayAccentColor.g, root.config.overlayAccentColor.b, 0.7)
                                offColor: Qt.rgba(root.config.overlayTextColor.r, root.config.overlayTextColor.g, root.config.overlayTextColor.b, 0.12)
                                onBorderColor: root.config.overlayAccentColor
                                offBorderColor: root.config.mutedTextColor
                                onKnobColor: root.config.overlayAccentColor
                                offKnobColor: root.config.mutedTextColor
                                opacity: modelData.barId ? 1 : 0
                                onToggled: if (modelData.barId) root.shell.setBarOverlayVisible(modelData.barId, !((root.config.barOverlayVisibility || {})[modelData.barId] !== false))
                            }
                        }
                    }
                }

                // ── Separator ────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(root.config.overlayAccentColor.r, root.config.overlayAccentColor.g, root.config.overlayAccentColor.b, 0.2)
                }

                // ── Notifications section ─────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Label {
                        text: "Notifications"
                        color: root.config.overlayTextColor
                        font.family: root.uiFontFamily
                        font.pixelSize: root.uiFontSize
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    Label {
                        visible: root.notifications.length > 0
                        text: "Clear"
                        color: root.config.mutedTextColor
                        font.family: root.uiFontFamily
                        font.pixelSize: root.uiFontSize - 1
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            onClicked: root.shell.clearNotificationHistory()
                        }
                    }
                    Label {
                        text: root.notifExpanded ? "\u25B4" : "\u25BE"
                        color: root.config.mutedTextColor
                        font.family: root.uiFontFamily
                        font.pixelSize: root.uiFontSize
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            onClicked: root.notifExpanded = !root.notifExpanded
                        }
                    }
                }

                // Notification list (visible when expanded)
                ColumnLayout {
                    visible: root.notifExpanded
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        visible: root.notifications.length === 0
                        text: "No notifications"
                        color: root.config.mutedTextColor
                        font.family: root.uiFontFamily
                        font.pixelSize: root.uiFontSize - 1
                        Layout.fillWidth: true
                    }

                    Repeater {
                        model: Math.min(root.notifications.length, 8)
                        delegate: Rectangle {
                            required property int index
                            readonly property var notif: root.notifications[index] || {}
                            Layout.fillWidth: true
                            implicitHeight: notifRow.implicitHeight + 10
                            color: Qt.rgba(root.config.overlayTextColor.r, root.config.overlayTextColor.g, root.config.overlayTextColor.b, 0.05)
                            border.color: Qt.rgba(root.config.overlayTextColor.r, root.config.overlayTextColor.g, root.config.overlayTextColor.b, 0.1)
                            border.width: 1
                            radius: Math.max(0, root.config.overlayRounding - 4)

                            RowLayout {
                                id: notifRow
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 8
                                spacing: 8

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Label {
                                        text: String(notif.appName || notif.summary || "")
                                        color: root.config.overlayAccentColor
                                        font.family: root.uiFontFamily
                                        font.pixelSize: root.uiFontSize - 1
                                        font.bold: true
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                    Label {
                                        visible: String(notif.body || "").length > 0
                                        text: String(notif.body || "")
                                        color: root.config.overlayTextColor
                                        font.family: root.uiFontFamily
                                        font.pixelSize: root.uiFontSize - 1
                                        wrapMode: Text.NoWrap
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                Label {
                                    text: "\u00D7"
                                    color: root.config.mutedTextColor
                                    font.family: root.uiFontFamily
                                    font.pixelSize: root.uiFontSize + 2
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -4
                                        onClicked: root.shell.dismissNotification(index)
                                    }
                                }
                            }
                        }
                    }
                }

                Item { height: 2 }
            }

            // Shared tooltip
            Rectangle {
                visible: root.tooltipVisible && root.tooltipDisplayText.length > 0
                x: Math.max(6, Math.min(quickMenu.width - width - 6, root.tooltipCenterX - width / 2))
                y: Math.max(6, root.tooltipBottomY - height)
                implicitWidth: sharedTooltipLabel.implicitWidth + 14
                implicitHeight: sharedTooltipLabel.implicitHeight + 8
                color: root.config.overlayBackgroundColor
                border.color: root.config.overlayAccentColor
                border.width: root.config.buttonBorderWidth
                radius: Math.max(0, root.config.overlayRounding - 4)
                z: 50

                Label {
                    id: sharedTooltipLabel
                    anchors.centerIn: parent
                    text: root.tooltipDisplayText
                    color: root.config.overlayTextColor
                    font.family: root.uiFontFamily
                    font.pixelSize: Math.max(10, root.uiFontSize - 1)
                }
            }
        }
    }

    Timer {
        id: quickSettingsPresentTimer
        interval: 16
        repeat: false
        onTriggered: {
            if (root.quickSettingsActive)
                root.quickSettingsPresented = true;
        }
    }

    Timer {
        id: quickSettingsCloseDebounce
        interval: 50
        repeat: false
        onTriggered: {
            if (!root.quickSettingsActive && root.quickSettingsWindowActive) {
                root.quickSettingsPresented = false;
                quickSettingsHideTimer.restart();
            }
        }
    }

    Timer {
        id: quickSettingsHideTimer
        interval: 170
        repeat: false
        onTriggered: {
            if (!root.quickSettingsActive) {
                root.quickSettingsPresented = false;
                root.quickSettingsWindowActive = false;
            }
        }
    }

    Timer {
        id: quickSettingsEdgeHold
        interval: root.config.sidebarEdgeHoldMs
        repeat: false
        onTriggered: root.shell.holdQuickSettingsTrigger()
    }

    Timer {
        id: tooltipDelay
        interval: 1000
        repeat: false
        onTriggered: {
            if (!root.tooltipOwner || root.tooltipPendingText.length < 1)
                return;
            root.tooltipDisplayText = root.tooltipPendingText;
            root.tooltipVisible = true;
        }
    }

    Process {
        id: wifiStateProc
        command: ["bash", "-lc", "if command -v nmcli >/dev/null 2>&1; then state=$(nmcli radio wifi | head -n1 | tr '[:upper:]' '[:lower:]'); [ \"$state\" = enabled ] && echo on || echo off; else echo off; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.wifiEnabled = String(text).trim() === "on"
        }
    }

    Process {
        id: bluetoothStateProc
        command: ["bash", "-lc", "if command -v bluetoothctl >/dev/null 2>&1; then state=$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered:/ {print tolower($2); exit}'); [ \"$state\" = yes ] && echo on || echo off; else echo off; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.bluetoothEnabled = String(text).trim() === "on"
        }
    }

    Process {
        id: notificationsStateProc
        command: ["bash", "-lc", "if command -v dunstctl >/dev/null 2>&1; then state=$(dunstctl is-paused 2>/dev/null | tr '[:upper:]' '[:lower:]'); [ \"$state\" = true ] && echo on || echo off; elif command -v makoctl >/dev/null 2>&1; then state=$(makoctl mode 2>/dev/null | tr '[:upper:]' '[:lower:]'); [ \"$state\" = do-not-disturb ] && echo on || echo off; elif command -v swaync-client >/dev/null 2>&1; then state=$(swaync-client -D 2>/dev/null | tr '[:upper:]' '[:lower:]'); [ \"$state\" = true ] && echo on || echo off; else echo off; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.notificationsSilenced = String(text).trim() === "on"
        }
    }

    Process { id: wifiToggleProc }
    Process { id: bluetoothToggleProc }
    Process { id: notificationsToggleProc }

    Timer {
        id: refreshTimer
        interval: 220
        repeat: false
        onTriggered: root.refreshStates()
    }

    Timer {
        interval: Math.max(1200, root.config.quickSidebarPollMs)
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refreshStates()
    }
}
