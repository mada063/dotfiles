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
        left: true
        right: true
    }

    implicitHeight: 34
    exclusiveZone: 34
    color: "transparent"

    property alias dateTimeText: barState.dateText
    readonly property string wifiText: root.networkDisplayText
    readonly property string btText: "BT"
    readonly property string batteryText: root._batteryRichText(root.batteryPercent)
    property alias batteryPercent: barState.batteryPercent
    readonly property string audioText: root._volumeRichText(root.volumePercent, root.volumeMuted)
    property alias capsLockOn: barState.capsLockOn
    property alias numLockOn: barState.numLockOn
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
    property real statusMenuLeftX: Math.max(0, root.width - 280)
    property alias wifiConnectSsid: barState.wifiConnectSsid
    property alias wifiConnectPassword: barState.wifiConnectPassword
    property alias btDeviceTarget: barState.btDeviceTarget
    property alias wifiNetworks: barState.wifiNetworks
    property alias btDevices: barState.btDevices
    property alias activeWorkspaceIds: barState.activeWorkspaceIds
    property alias focusedWorkspaceId: barState.focusedWorkspaceId
    property bool statusMenuInputFocused: false
    readonly property real statusMenuContentWidth: Math.max(240, statusMenuWindow.width - 16)
    property bool statusMenuHugWidth: false
    readonly property int sideMenuHugContentWidth: 280
    readonly property string uiFontFamily: root.config.fontFamily
    readonly property int uiFontSize: root.config.fontPixelSize
    readonly property int mediumPollMs: root.config.barMediumPollMs
    readonly property int slowPollMs: root.config.barSlowPollMs
    readonly property int workspacePollMs: root.config.barWorkspacePollMs

    BarState.BarSensorState {
        id: barState
        config: root.config
        visible: root.visible
        includeLocks: true
        dateCommand: "date '+%a %d %b %H:%M'"
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
        _applyFontRecursive(statusMenuWindow);
    }
    onUiFontSizeChanged: {
        _applyFontRecursive(root);
        _applyFontRecursive(statusMenuWindow);
    }
    Component.onCompleted: {
        _applyFontRecursive(root);
        _applyFontRecursive(statusMenuWindow);
    }

    function _shellQuoteSingle(value) {
        return String(value).replace(/'/g, "'\"'\"'");
    }

    function _levelBars(percent, steps) {
        const p = Math.max(0, Math.min(100, Number(percent)));
        const total = Math.max(1, Number(steps) || 10);
        const on = Math.round((p / 100) * total);
        return "|".repeat(on) + "·".repeat(total - on);
    }

    function _volumeRichText(percent, muted) {
        const p = Math.max(0, Math.min(100, Number(percent)));
        const active = Math.round((p / 100) * 10);
        const inactive = Qt.rgba(root.config.textColor.r, root.config.textColor.g, root.config.textColor.b, 0.5);
        const mutedColor = "#6b7280";
        const base = root.config.textColor;
        const hi = root.config.volumeColor;
        let bars = "";
        for (let i = 1; i <= 10; i++) {
            let color = inactive;
            if (i <= active) {
                if (muted)
                    color = mutedColor;
                else
                    color = i > 7 ? hi : base;
            }
            bars += "<span style=\"letter-spacing:-2px; color:" + color + ";\">|</span>";
        }
        return "VOL " + bars;
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
        const total = Math.max(10, Math.min(24, Math.floor((Number(contentWidth) - 40) / 11)));
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

    function openStatusMenu(name, chipX) {
        statusPopupCloseTimer.stop();
        statusMenuInputFocused = false;
        activeStatusMenu = name;
        if (chipX !== undefined) {
            const desiredWidth = name === "bt" ? 368 : name === "wifi" ? 320 : name === "audio" ? 300 : name === "locks" ? 132 : 260;
            statusMenuLeftX = Math.max(0, Math.min(Number(chipX), root.width - desiredWidth));
        }
        barState.handleStatusMenuOpened(name);
    }

    function queueStatusMenuClose(name) {
        if (activeStatusMenu === name)
            statusPopupCloseTimer.restart();
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
        audioRefreshTimer.restart();
    }

    function audioToggleMute() {
        volMuteProc.exec({ command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then pactl set-sink-mute @DEFAULT_SINK@ toggle; fi"] });
        audioRefreshTimer.restart();
    }

    function audioOpenMixer() {
        openMixerProc.exec({ command: ["bash", "-lc", "if command -v pavucontrol >/dev/null 2>&1; then pavucontrol; fi"] });
    }

    function setDefaultAudioSink(name) {
        audioSinkSetProc.exec({ command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then pactl set-default-sink '" + root._shellQuoteSingle(name) + "'; fi"] });
        root.scheduleStatusRefresh();
    }

    function setDefaultAudioSource(name) {
        audioSourceSetProc.exec({ command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then pactl set-default-source '" + root._shellQuoteSingle(name) + "'; fi"] });
        root.scheduleStatusRefresh();
    }

    Rectangle {
        anchors.fill: parent
        color: root.config.panelColor
        border.color: root.config.borderColor
        border.width: root.config.borderWidth
        opacity: 0.96
    }

    Rectangle {
        visible: root.config.borderWidth > 0
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.config.borderWidth
        color: root.config.borderColor
        z: 1000
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10

        RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignVCenter
            Label {
                text: "MyShell"
                visible: root.config.showShellTitle
                color: root.config.accentColor
                font.bold: true
                font.family: root.uiFontFamily
                font.pixelSize: root.uiFontSize + 1
            }
            Row {
                spacing: 5
                Repeater {
                    model: root.activeWorkspaceIds
                    delegate: Rectangle {
                        required property var modelData
                        readonly property int wsId: Number(modelData)
                        color: wsId === root.focusedWorkspaceId ? root.config.workspaceAccentColor : "transparent"
                        border.width: root.config.buttonBorderWidth
                        border.color: root.config.mutedTextColor
                        radius: root.config.rounding
                        implicitWidth: 24
                        implicitHeight: 22
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
        }

        Item {
            Layout.fillWidth: true
        }

        RowLayout {
            spacing: 8
            Rectangle {
                implicitWidth: 140
                implicitHeight: 30
                color: "transparent"
                border.width: root.config.buttonBorderWidth
                border.color: root.config.mutedTextColor
                radius: root.config.rounding



                MouseArea {
                    anchors.fill: parent
                    onClicked: root.shell.toggleDashboard()
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        RowLayout {
            id: rightStatusRow
            spacing: 10
            Rectangle {
                visible: root.capsLockOn
                color: "transparent"
                border.width: root.config.buttonBorderWidth
                border.color: root.config.accentColor
                radius: root.config.rounding
                implicitWidth: 48
                implicitHeight: 22
                Label {
                    anchors.centerIn: parent
                    text: "CAPS"
                    color: root.config.accentColor
                    font.bold: true
                    font.family: root.uiFontFamily
                    font.pixelSize: root.uiFontSize
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.openStatusMenu("locks", Math.max(0, rightStatusRow.x + wifiChip.x - 132))
                    onExited: root.queueStatusMenuClose("locks")
                    onClicked: root.openStatusMenu("locks", Math.max(0, rightStatusRow.x + wifiChip.x - 132))
                }
            }
            Rectangle {
                visible: root.numLockOn
                color: "transparent"
                border.width: root.config.buttonBorderWidth
                border.color: root.config.accentColor
                radius: root.config.rounding
                implicitWidth: 40
                implicitHeight: 22
                Label {
                    anchors.centerIn: parent
                    text: "NUM"
                    color: root.config.accentColor
                    font.bold: true
                    font.family: root.uiFontFamily
                    font.pixelSize: root.uiFontSize
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.openStatusMenu("locks", Math.max(0, rightStatusRow.x + wifiChip.x - 132))
                    onExited: root.queueStatusMenuClose("locks")
                    onClicked: root.openStatusMenu("locks", Math.max(0, rightStatusRow.x + wifiChip.x - 132))
                }
            }
            Label {
                text: root.dateTimeText
                color: root.config.textColor
                font.family: root.uiFontFamily
                font.pixelSize: root.uiFontSize
                Layout.alignment: Qt.AlignVCenter
            }
            Item {
                Layout.preferredWidth: 18
                Layout.minimumWidth: 18
                Layout.fillWidth: false
            }
            Rectangle {
                id: wifiChip
                color: "transparent"
                border.width: root.config.buttonBorderWidth
                border.color: root.config.mutedTextColor
                radius: root.config.rounding
                implicitWidth: wifiLabel.implicitWidth + 10
                implicitHeight: 22
                Layout.alignment: Qt.AlignVCenter
                Label { id: wifiLabel; anchors.centerIn: parent; text: root.wifiText; color: root.config.textColor }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.openStatusMenu("wifi", rightStatusRow.x + wifiChip.x)
                    onExited: root.queueStatusMenuClose("wifi")
                    onClicked: root.openStatusMenu("wifi", rightStatusRow.x + wifiChip.x)
                }
            }
            Rectangle {
                id: btChip
                color: "transparent"
                border.width: root.config.buttonBorderWidth
                border.color: root.config.mutedTextColor
                radius: root.config.rounding
                implicitWidth: btLabel.implicitWidth + 10
                implicitHeight: 22
                Layout.alignment: Qt.AlignVCenter
                Label { id: btLabel; anchors.centerIn: parent; text: root.btText; color: root.config.textColor }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.openStatusMenu("bt", rightStatusRow.x + btChip.x)
                    onExited: root.queueStatusMenuClose("bt")
                    onClicked: root.openStatusMenu("bt", rightStatusRow.x + btChip.x)
                }
            }
            Rectangle {
                id: audioChip
                color: "transparent"
                border.width: root.config.buttonBorderWidth
                border.color: root.config.mutedTextColor
                radius: root.config.rounding
                implicitWidth: audioLabel.implicitWidth + 10
                implicitHeight: 22
                Layout.alignment: Qt.AlignVCenter
                Label { id: audioLabel; anchors.centerIn: parent; text: root.audioText; color: root.config.textColor; textFormat: Text.RichText }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.openStatusMenu("audio", rightStatusRow.x + audioChip.x)
                    onExited: root.queueStatusMenuClose("audio")
                    onClicked: mouse => {
                        const ratio = Math.max(0, Math.min(1, mouse.x / Math.max(1, audioChip.width)));
                        const pct = Math.round(ratio * 100);
                        root._setLocalVolume(pct);
                        volSetProc.exec({ command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then pactl set-sink-volume @DEFAULT_SINK@ " + pct + "%; fi"] });
                        audioRefreshTimer.restart();
                    }
                    onWheel: wheel => {
                        const dir = wheel.angleDelta.y > 0 ? "+2%" : "-2%";
                        volStepProc.exec({ command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then pactl set-sink-volume @DEFAULT_SINK@ " + dir + "; fi"] });
                        root._setLocalVolume(root.volumePercent + (wheel.angleDelta.y > 0 ? 2 : -2));
                        audioRefreshTimer.restart();
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
                implicitWidth: batRow.implicitWidth + 14
                implicitHeight: Math.max(22, batRow.implicitHeight + 6)
                Layout.alignment: Qt.AlignVCenter
                RowLayout {
                    id: batRow
                    anchors.centerIn: parent
                    spacing: 5

                    Label {
                        text: "BAT"
                        color: root.config.textColor
                        font.family: root.uiFontFamily
                        font.pixelSize: root.uiFontSize + 1
                        Layout.alignment: Qt.AlignVCenter
                    }

                    BatterySegmentIndicator {
                        horizontal: true
                        percent: root.batteryPercent
                        textColor: root.config.textColor
                        barRadius: Math.max(0, Math.min(root.config.rounding, 8))
                        segmentWidth: 5
                        segmentHeight: 14
                        segmentSpacing: 2
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.openStatusMenu("battery", rightStatusRow.x + batChip.x)
                    onExited: root.queueStatusMenuClose("battery")
                    onClicked: root.openStatusMenu("battery", rightStatusRow.x + batChip.x)
                }
            }
            Item {
                width: 2
            }
            Rectangle {
                implicitWidth: 88
                implicitHeight: 22
                color: "transparent"
                border.width: root.config.buttonBorderWidth
                border.color: root.config.mutedTextColor
                radius: Math.max(0, root.config.rounding - 3)
                Label { anchors.centerIn: parent; text: "Settings"; color: root.config.textColor }
                MouseArea { anchors.fill: parent; onClicked: root.shell.toggleControlCenter() }
            }
        }
    }

    PanelWindow {
        id: statusMenuWindow
        property bool shown: root.activeStatusMenu.length > 0
        visible: shown || statusPanel.opacity > 0.01
        focusable: root.activeStatusMenu === "wifi"
        WlrLayershell.keyboardFocus: root.activeStatusMenu === "wifi" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        anchors {
            top: true
            right: true
        }
        margins {
            top: 0
            right: 0
        }
        implicitWidth: Math.max(1, root.width - root.statusMenuLeftX)
        implicitHeight: statusMenuContent.implicitHeight + 16
        exclusiveZone: 0
        color: "transparent"

        Rectangle {
            id: statusPanel
            anchors.fill: parent
            y: statusMenuWindow.shown ? 0 : -(statusMenuWindow.implicitHeight + 8)
            color: root.config.panelColor
            border.color: root.config.borderColor
            border.width: root.config.overlayBorderWidth
            radius: root.config.rounding
            opacity: statusMenuWindow.shown ? 1 : 0

            Behavior on y {
                id: statusSlideAnim
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }
            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: Math.max(1, root.config.overlayBorderWidth)
                color: root.config.panelColor
            }
        }

        Column {
            id: statusMenuContent
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            Label {
                text: root.activeStatusMenu === "wifi" ? root.networkDisplayText
                    : root.activeStatusMenu === "bt" ? "Bluetooth"
                    : root.activeStatusMenu === "locks" ? "LOCKS"
                    : root.activeStatusMenu === "battery" ? "BATTERY"
                    : root.activeStatusMenu === "audio" ? "AUDIO"
                    : ""
                color: root.config.overlayAccentColor
                font.bold: true
            }

            Status.WifiMenuContent {
                visible: root.activeStatusMenu === "wifi"
                host: root
                listHeight: 260
            }

            Status.BluetoothMenuContent {
                visible: root.activeStatusMenu === "bt"
                host: root
                toggleWidth: 38
                toggleHeight: 20
                knobSize: 14
                listHeight: 170
            }

            Status.LocksMenuContent {
                visible: root.activeStatusMenu === "locks"
                host: root
            }

            Status.AudioMenuContent {
                visible: root.activeStatusMenu === "audio"
                host: root
                outputListHeight: 110
                inputListHeight: 96
                menuFontBoost: 8
                showMixer: true
            }

            Status.BatteryMenuContent {
                visible: root.activeStatusMenu === "battery"
                host: root
            }
        }

        HoverHandler {
            onHoveredChanged: {
                if (hovered)
                    statusPopupCloseTimer.stop();
                else
                    statusPopupCloseTimer.restart();
            }
        }
    }

    Process {
        id: wsSwitchProc
    }

    Process { id: volStepProc }
    Process { id: volSetProc }
    Process { id: volMuteProc }
    Process { id: openMixerProc }
    Process { id: openPowerProc }
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
        id: statusPopupCloseTimer
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
        id: audioRefreshTimer
        interval: 140
        repeat: false
        onTriggered: {
            barState.refreshAudioData();
        }
    }

    onActiveStatusMenuChanged: {
        if (activeStatusMenu !== "wifi")
            statusMenuInputFocused = false;
        _applyFontRecursive(statusMenuWindow);
    }
}
