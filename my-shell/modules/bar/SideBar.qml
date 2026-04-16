import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "./status" as Status
import "./state" as BarState

PanelWindow {
    id: root

    required property QtObject shell
    required property QtObject config

    anchors {
        top: true
        bottom: true
        left: true
    }

    // --- Sidebar width chain (for tuning) ---
    // implicitWidth = contentRoot.implicitWidth + 8  (4 px margin each side of contentRoot).
    // contentRoot is a ColumnLayout: its width is max(workspaceCol, statusCol) preferred widths.
    // workspaceCol ≈ max("My" title, 28 px workspace chips).
    // statusCol ≈ max(clock Text widest line, wifi chip, bt, vol, bat, Set) — usually the widest chip.
    // Clock is multiline; without a cap, a bad date string or huge font metrics can widen the column.
    readonly property int sideBarStatusColumnMaxW: 52

    implicitWidth: contentRoot.implicitWidth + 8
    exclusiveZone: implicitWidth
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: root.config.panelColor
        border.color: root.config.borderColor
        border.width: root.config.borderWidth
        opacity: 0.96
    }

    Rectangle {
        visible: root.config.borderWidth > 0
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: root.config.borderWidth
        color: root.config.borderColor
        z: 1000
    }

    property alias dateText: barState.dateText
    readonly property string wifiText: root.networkDisplayText
    readonly property string btText: "BT"
    readonly property string batText: root._batteryRichText(root.batteryPercent)
    property alias batteryPercent: barState.batteryPercent
    readonly property string volText: root._volumeBarRichText(root.volumePercent, root.volumeMuted)
    property alias wifiDetailText: barState.wifiDetailText
    property alias btDetailText: barState.btDetailText
    property alias volumePercent: barState.volumePercent
    property alias volumeMuted: barState.volumeMuted
    property alias networkEnabled: barState.networkEnabled
    property alias networkDisplayText: barState.networkDisplayText
    property alias networkTypeText: barState.networkTypeText
    property alias wifiDeviceName: barState.wifiDeviceName
    property alias wifiConnected: barState.wifiConnected
    property alias btEnabled: barState.btEnabled
    property alias btDiscoverable: barState.btDiscoverable
    property alias audioOutputs: barState.audioOutputs
    property alias audioInputs: barState.audioInputs
    property alias batteryTimeText: barState.batteryTimeText
    property alias batteryStatusText: barState.batteryStatusText
    property alias activeStatusMenu: barState.activeStatusMenu
    property real statusMenuTopY: 0
    property alias wifiConnectSsid: barState.wifiConnectSsid
    property alias wifiConnectPassword: barState.wifiConnectPassword
    property alias btDeviceTarget: barState.btDeviceTarget
    property alias wifiNetworks: barState.wifiNetworks
    property alias btDevices: barState.btDevices
    property alias activeWorkspaceIds: barState.activeWorkspaceIds
    property alias focusedWorkspaceId: barState.focusedWorkspaceId
    property bool statusMenuInputFocused: false
    // Top bar uses width from the menu surface; side bar uses a fixed hug width (no circular binding).
    property bool statusMenuHugWidth: true
    readonly property int sideMenuHugContentWidth: 228
    // Align to the layer surface right edge — not the centered status column (avoids large horizontal error).
    readonly property real statusAnchorX: Math.max(0, root.width - 1)
    readonly property string uiFontFamily: root.config.fontFamily
    readonly property int uiFontSize: root.config.fontPixelSize
    readonly property int mediumPollMs: root.config.barMediumPollMs
    readonly property int slowPollMs: root.config.barSlowPollMs
    readonly property int workspacePollMs: root.config.barWorkspacePollMs

    BarState.BarSensorState {
        id: barState
        config: root.config
        visible: root.visible
        includeLocks: false
        dateCommand: "date '+%H\n-\n%M\n-\n%S'"
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

    onUiFontFamilyChanged: {
        _applyFontRecursive(root);
        _applyFontRecursive(sideStatusMenu);
    }
    onUiFontSizeChanged: {
        _applyFontRecursive(root);
        _applyFontRecursive(sideStatusMenu);
    }
    Component.onCompleted: {
        _applyFontRecursive(root);
        _applyFontRecursive(sideStatusMenu);
    }

    function _shellQuoteSingle(value) {
        return String(value).replace(/'/g, "'\"'\"'");
    }

    function _volumeBarRichText(percent, muted) {
        const p = Math.max(0, Math.min(100, Number(percent)));
        const active = Math.round((p / 100) * 8);
        const inactive = Qt.rgba(root.config.textColor.r, root.config.textColor.g, root.config.textColor.b, 0.5);
        const mutedColor = "#6b7280";
        const base = root.config.textColor;
        const hi = root.config.volumeColor;
        let bars = "";
        for (let i = 1; i <= 8; i++) {
            let color = inactive;
            if (i <= active) {
                if (muted)
                    color = mutedColor;
                else
                    color = i > 5 ? hi : base;
            }
            bars += "<span style=\"letter-spacing:-2px; color:" + color + ";\">|</span>";
        }
        return bars;
    }

    function _batteryRichText(percent) {
        return "BAT " + Math.round(Math.max(0, Math.min(100, Number(percent)))) + "%";
    }

    function _setLocalVolume(percent, muted) {
        volumePercent = Math.max(0, Math.min(150, Math.round(percent)));
        if (muted !== undefined)
            volumeMuted = muted;
    }

    function _volumeMenuRichText(percent, muted, contentWidth) {
        const p = Math.max(0, Math.min(100, Number(percent)));
        const total = Math.max(9, Math.min(18, Math.floor((Number(contentWidth) - 40) / 11)));
        const active = Math.round((p / 100) * total);
        const inactive = Qt.rgba(root.config.textColor.r, root.config.textColor.g, root.config.textColor.b, 0.5);
        const mutedColor = "#6b7280";
        const base = root.config.textColor;
        const hi = root.config.volumeColor;
        let bars = "";
        for (let i = 1; i <= total; i++) {
            let color = inactive;
            if (i <= active)
                color = muted ? mutedColor : (i > Math.ceil(total * 0.7) ? hi : base);
            bars += "<span style=\"letter-spacing:-2px; color:" + color + ";\">|</span>";
        }
        return "VOL " + bars;
    }

    function _wifiIsSecure(security) {
        const value = String(security || "").trim().toLowerCase();
        return value.length > 0 && value !== "open" && value !== "--" && value !== "none";
    }

    function _toggleRadius(height) {
        return Math.min(Math.max(0, root.config.rounding), height / 2);
    }

    function _toggleKnobRadius(height) {
        return Math.min(Math.max(0, root.config.rounding - 3), height / 2);
    }

    function refreshStatusMenuData() {
        barState.refreshStatusMenuData();
    }

    function scheduleStatusRefresh() {
        barState.scheduleStatusRefresh();
    }

    function openStatusMenu(name, chipY) {
        statusMenuTopY = Math.max(0, Number(chipY));
        sideMenuCloseTimer.stop();
        statusMenuInputFocused = false;
        barState.handleStatusMenuOpened(name);
    }

    function queueStatusMenuClose(name) {
        if (root.activeStatusMenu === name)
            sideMenuCloseTimer.restart();
    }

    function toggleWifiEnabled() {
        const next = !root.networkEnabled;
        root.networkEnabled = next;
        wifiToggleProc.exec({ command: ["bash", "-lc", "if command -v nmcli >/dev/null 2>&1; then nmcli radio wifi " + (next ? "on" : "off") + "; fi"] });
        root.scheduleStatusRefresh();
    }

    function clickWifiNetwork(modelData) {
        if (modelData.active) {
            wifiDisconnectProc.exec({ command: ["bash", "-lc", "if command -v nmcli >/dev/null 2>&1; then dev=$(nmcli -t -f DEVICE,TYPE,STATE device status | awk -F: '$2==\"wifi\" && $3==\"connected\" {print $1; exit}'); [ -n \"$dev\" ] && nmcli device disconnect \"$dev\"; fi"] });
        } else {
            if (modelData.secured && root.wifiConnectSsid === modelData.ssid) {
                root.wifiConnectSsid = "";
                root.wifiConnectPassword = "";
                return;
            }
            if (root.wifiConnectSsid !== modelData.ssid)
                root.wifiConnectPassword = "";
            root.wifiConnectSsid = modelData.ssid;
            if (modelData.secured && !root.wifiConnectPassword)
                return;
            if (modelData.secured)
                wifiConnectProc.exec({ command: ["bash", "-lc", "if command -v nmcli >/dev/null 2>&1; then nmcli dev wifi connect '" + root._shellQuoteSingle(modelData.ssid) + "' password '" + root._shellQuoteSingle(root.wifiConnectPassword) + "'; fi"] });
            else
                wifiConnectProc.exec({ command: ["bash", "-lc", "if command -v nmcli >/dev/null 2>&1; then nmcli dev wifi connect '" + root._shellQuoteSingle(modelData.ssid) + "'; fi"] });
        }
        root.scheduleStatusRefresh();
    }

    function submitWifiPassword(modelData) {
        wifiConnectProc.exec({ command: ["bash", "-lc", "if command -v nmcli >/dev/null 2>&1; then nmcli dev wifi connect '" + root._shellQuoteSingle(modelData.ssid) + "' password '" + root._shellQuoteSingle(root.wifiConnectPassword) + "'; fi"] });
        root.scheduleStatusRefresh();
    }

    function rescanWifi() {
        barState.handleStatusMenuOpened("wifi");
        barState.refreshStatusMenuData();
    }

    function toggleBtEnabled() {
        const next = !root.btEnabled;
        root.btEnabled = next;
        btPowerProc.exec({ command: ["bash", "-lc", "if command -v bluetoothctl >/dev/null 2>&1; then bluetoothctl power " + (next ? "on" : "off") + "; fi"] });
        root.scheduleStatusRefresh();
    }

    function toggleBtDiscoverable() {
        const next = !root.btDiscoverable;
        root.btDiscoverable = next;
        btDiscoverableProc.exec({ command: ["bash", "-lc", "if command -v bluetoothctl >/dev/null 2>&1; then bluetoothctl discoverable " + (next ? "on" : "off") + "; fi"] });
        root.scheduleStatusRefresh();
    }

    function connectBt(mac) {
        btConnectProc.exec({ command: ["bash", "-lc", "if command -v bluetoothctl >/dev/null 2>&1; then bluetoothctl connect '" + root._shellQuoteSingle(mac) + "'; fi"] });
        root.scheduleStatusRefresh();
    }

    function disconnectBt(mac) {
        btDisconnectProc.exec({ command: ["bash", "-lc", "if command -v bluetoothctl >/dev/null 2>&1; then bluetoothctl disconnect '" + root._shellQuoteSingle(mac) + "'; fi"] });
        root.scheduleStatusRefresh();
    }

    function rescanBt() {
        barState.handleStatusMenuOpened("bt");
        barState.refreshStatusMenuData();
    }

    function audioStep(delta) {
        const amount = Number(delta) >= 0 ? "+" + Math.abs(Number(delta)) : String(Number(delta));
        volStepProc.exec({ command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then pactl set-sink-volume @DEFAULT_SINK@ " + amount + "%; fi"] });
        volRefreshTimer.restart();
    }

    function audioToggleMute() {
        volMuteProc.exec({ command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then pactl set-sink-mute @DEFAULT_SINK@ toggle; fi"] });
        volRefreshTimer.restart();
    }

    function audioOpenMixer() {
    }

    function setDefaultAudioSink(name) {
        audioSinkSetProc.exec({ command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then pactl set-default-sink '" + root._shellQuoteSingle(name) + "'; fi"] });
        root.scheduleStatusRefresh();
    }

    function setDefaultAudioSource(name) {
        audioSourceSetProc.exec({ command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then pactl set-default-source '" + root._shellQuoteSingle(name) + "'; fi"] });
        root.scheduleStatusRefresh();
    }

    ColumnLayout {
        id: contentRoot
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            leftMargin: 4
            topMargin: 4
            bottomMargin: 4
        }
        width: implicitWidth
        spacing: 6

        ColumnLayout {
            id: workspaceCol
            spacing: 6
            Layout.alignment: Qt.AlignHCenter
            Label {
                text: "My"
                visible: root.config.showShellTitle
                color: root.config.accentColor
                font.bold: true
                font.family: root.uiFontFamily
                font.pixelSize: root.uiFontSize + 1
                Layout.alignment: Qt.AlignHCenter
            }
            Repeater {
                model: root.activeWorkspaceIds
                delegate: Rectangle {
                    required property var modelData
                    readonly property int wsId: Number(modelData)
                    implicitWidth: 26
                    implicitHeight: 22
                    radius: root.config.rounding
                    color: wsId === root.focusedWorkspaceId ? root.config.workspaceAccentColor : "transparent"
                    border.width: root.config.buttonBorderWidth
                    border.color: root.config.mutedTextColor
                    Label {
                        anchors.centerIn: parent
                        text: String(parent.wsId)
                        color: parent.wsId === root.focusedWorkspaceId ? root.config.workspaceColor : root.config.textColor
                        font.bold: true
                        font.family: root.uiFontFamily
                        font.pixelSize: root.uiFontSize
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: wsSwitchProc.exec({
                            command: ["bash", "-lc", "if command -v hyprctl >/dev/null 2>&1; then hyprctl dispatch workspace " + parent.wsId + "; fi"]
                        })
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }

        ColumnLayout {
            id: statusCol
            spacing: 4
            Layout.alignment: Qt.AlignHCenter
            Text {
                width: root.sideBarStatusColumnMaxW
                text: root.dateText
                color: root.config.textColor
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
                font.family: root.uiFontFamily
                font.pixelSize: root.uiFontSize + 1
                font.bold: true
                lineHeight: 0.85
            }
            Item {
                Layout.preferredHeight: 10
                Layout.minimumHeight: 10
            }
            Rectangle {
                id: wifiChip
                color: "transparent"
                border.width: root.config.buttonBorderWidth
                border.color: root.config.mutedTextColor
                radius: root.config.rounding
                implicitWidth: root.sideBarStatusColumnMaxW
                implicitHeight: 22
                Layout.alignment: Qt.AlignHCenter
                Label {
                    id: wifiLabel
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    leftPadding: 2
                    rightPadding: 2
                    text: root.wifiText
                    color: root.config.textColor
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.openStatusMenu("wifi", contentRoot.y + statusCol.y + wifiChip.y)
                    onExited: root.queueStatusMenuClose("wifi")
                    onClicked: root.openStatusMenu("wifi", contentRoot.y + statusCol.y + wifiChip.y)
                }
            }
            Rectangle {
                id: btChip
                color: "transparent"
                border.width: root.config.buttonBorderWidth
                border.color: root.config.mutedTextColor
                radius: root.config.rounding
                implicitWidth: 30
                implicitHeight: 22
                Layout.alignment: Qt.AlignHCenter
                Label {
                    id: btLabel
                    anchors.centerIn: parent
                    text: root.btText
                    color: root.config.textColor
                    elide: Text.ElideRight
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.openStatusMenu("bt", contentRoot.y + statusCol.y + btChip.y)
                    onExited: root.queueStatusMenuClose("bt")
                    onClicked: root.openStatusMenu("bt", contentRoot.y + statusCol.y + btChip.y)
                }
            }
            Rectangle {
                id: volChip
                color: "transparent"
                border.width: root.config.buttonBorderWidth
                border.color: root.config.mutedTextColor
                radius: root.config.rounding
                implicitWidth: 26
                implicitHeight: 66
                Layout.alignment: Qt.AlignHCenter
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 2
                    spacing: 0

                    Label {
                        text: "VOL"
                        color: root.config.textColor
                        font.family: root.uiFontFamily
                        font.pixelSize: Math.max(9, root.uiFontSize - 1)
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Item {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 18
                        implicitHeight: 42

                        Text {
                            anchors.centerIn: parent
                            text: root.volText
                            color: root.config.textColor
                            textFormat: Text.RichText
                            rotation: -90
                            transformOrigin: Item.Center
                            renderType: Text.NativeRendering
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.openStatusMenu("audio", contentRoot.y + statusCol.y + volChip.y)
                    onExited: root.queueStatusMenuClose("audio")
                    onClicked: mouse => {
                        const ratio = Math.max(0, Math.min(1, 1 - (mouse.y / Math.max(1, volChip.height))));
                        const pct = Math.round(ratio * 100);
                        root._setLocalVolume(pct);
                        volSetProc.exec({ command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then pactl set-sink-volume @DEFAULT_SINK@ " + pct + "%; fi"] });
                        volRefreshTimer.restart();
                    }
                    onWheel: wheel => {
                        const dir = wheel.angleDelta.y > 0 ? "+2%" : "-2%";
                        volStepProc.exec({ command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then pactl set-sink-volume @DEFAULT_SINK@ " + dir + "; fi"] });
                        root._setLocalVolume(root.volumePercent + (wheel.angleDelta.y > 0 ? 2 : -2));
                        volRefreshTimer.restart();
                        wheel.accepted = true;
                    }
                }
            }
            Rectangle {
                id: batChip
                color: "transparent"
                border.width: root.config.buttonBorderWidth
                border.color: root.config.mutedTextColor
                radius: root.config.rounding
                implicitWidth: 28
                implicitHeight: 72
                Layout.alignment: Qt.AlignHCenter
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 2
                    spacing: 0

                    Label {
                        text: "BAT"
                        color: root.config.textColor
                        font.family: root.uiFontFamily
                        font.pixelSize: Math.max(9, root.uiFontSize - 1)
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    BatterySegmentIndicator {
                        Layout.alignment: Qt.AlignHCenter
                        percent: root.batteryPercent
                        textColor: root.config.textColor
                        barRadius: Math.max(0, Math.min(root.config.rounding, 6))
                        segmentWidth: 12
                        segmentHeight: 4
                        segmentSpacing: 2
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.openStatusMenu("battery", contentRoot.y + statusCol.y + batChip.y)
                    onExited: root.queueStatusMenuClose("battery")
                    onClicked: root.openStatusMenu("battery", contentRoot.y + statusCol.y + batChip.y)
                }
            }
            Rectangle {
                implicitWidth: 34
                implicitHeight: 22
                radius: Math.max(0, root.config.rounding - 3)
                border.width: root.config.buttonBorderWidth
                border.color: root.config.mutedTextColor
                color: "transparent"
                Layout.alignment: Qt.AlignHCenter
                Label { anchors.centerIn: parent; text: "Set"; color: root.config.textColor }
                MouseArea { anchors.fill: parent; onClicked: root.shell.toggleControlCenter() }
            }
        }
    }

    PanelWindow {
        id: sideStatusMenu
        property bool shown: root.activeStatusMenu.length > 0
        visible: shown || sidePanel.opacity > 0.01
        focusable: root.activeStatusMenu === "wifi"
        WlrLayershell.keyboardFocus: root.activeStatusMenu === "wifi" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        anchors {
            top: true
            left: true
        }
        margins {
            top: Math.max(0, Math.min(root.height - sideStatusMenu.implicitHeight - 8, root.statusMenuTopY))
            left: root.statusAnchorX
        }
        implicitWidth: Math.max(120, sideStatusContent.implicitWidth + 16)
        implicitHeight: sideStatusContent.implicitHeight + 16
        exclusiveZone: 0
        color: "transparent"

        Item {
            id: sideMenuRoot
            anchors.fill: parent

            HoverHandler {
                onHoveredChanged: {
                    if (hovered)
                        sideMenuCloseTimer.stop();
                    else
                        sideMenuCloseTimer.restart();
                }
            }

            Rectangle {
                id: sidePanel
                anchors.fill: parent
                x: sideStatusMenu.shown ? 0 : -24
                opacity: sideStatusMenu.shown ? 1 : 0
                color: root.config.panelColor
                border.color: root.config.borderColor
                border.width: root.config.overlayBorderWidth
                radius: root.config.rounding
                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 120 } }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: Math.max(1, root.config.overlayBorderWidth)
                    color: root.config.panelColor
                }
            }

            Column {
                id: sideStatusContent
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 8
                spacing: 8

                Label {
                    width: root.sideMenuHugContentWidth
                    text: root.activeStatusMenu === "wifi" ? root.networkDisplayText
                        : root.activeStatusMenu === "bt" ? "Bluetooth"
                        : root.activeStatusMenu === "battery" ? "BATTERY"
                        : root.activeStatusMenu === "audio" ? "AUDIO"
                        : ""
                    color: root.config.overlayAccentColor
                    font.bold: true
                    elide: Text.ElideRight
                }
                Status.WifiMenuContent {
                    visible: root.activeStatusMenu === "wifi"
                    host: root
                    listHeight: 250
                }

                Status.BluetoothMenuContent {
                    visible: root.activeStatusMenu === "bt"
                    host: root
                    toggleWidth: 34
                    toggleHeight: 18
                    knobSize: 12
                    listHeight: 160
                }

                Status.AudioMenuContent {
                    visible: root.activeStatusMenu === "audio"
                    host: root
                    outputListHeight: 100
                    inputListHeight: 92
                    menuFontBoost: 7
                    showMixer: false
                }

                Status.BatteryMenuContent {
                    visible: root.activeStatusMenu === "battery"
                    host: root
                }
            }
        }
    }

    Process { id: wsSwitchProc }
    Process { id: volStepProc }
    Process { id: volSetProc }
    Process { id: volMuteProc }
    Process { id: wifiConnectProc }
    Process { id: wifiDisconnectProc }
    Process { id: wifiToggleProc }
    Process { id: btConnectProc }
    Process { id: btDisconnectProc }
    Process { id: btPowerProc }
    Process { id: btDiscoverableProc }
    Process { id: audioSinkSetProc }
    Process { id: audioSourceSetProc }
    Timer {
        id: hoverReleaseTimer
        interval: root.config.hoverReleaseMs
        repeat: false
        onTriggered: root.shell.dashboardTriggerHovered = false
    }

    Timer {
        id: sideMenuCloseTimer
        interval: root.config.hoverReleaseMs
        repeat: false
        onTriggered: {
            if (root.statusMenuInputFocused)
                restart();
            else
                root.activeStatusMenu = "";
        }
    }

    Timer {
        id: volRefreshTimer
        interval: 140
        repeat: false
        onTriggered: {
            barState.refreshAudioData();
        }
    }

    onActiveStatusMenuChanged: {
        if (activeStatusMenu !== "wifi")
            statusMenuInputFocused = false;
        _applyFontRecursive(sideStatusMenu);
    }
}
