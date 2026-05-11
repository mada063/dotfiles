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
        color: root.config.barBackgroundColor
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
        color: root.config.barAccentColor
        z: 1000
    }

    property alias dateText: barState.dateText
    readonly property string wifiText: root.networkDisplayText
    readonly property string btText: "BT"
    readonly property string batText: root._batteryRichText(root.batteryPercent)
    // "discharging" contains substring "charging" — exclude before testing charge state.
    readonly property bool batteryCharging: {
        const s = String(root.batteryStatusText || "").toLowerCase();
        if (s.indexOf("discharging") >= 0)
            return false;
        if (s.indexOf("not charging") >= 0)
            return false;
        return s.indexOf("charging") >= 0;
    }
    property alias batteryPercent: barState.batteryPercent
    property alias wifiDetailText: barState.wifiDetailText
    property alias btDetailText: barState.btDetailText
    property alias volumePercent: barState.volumePercent
    property alias volumeMuted: barState.volumeMuted
    property alias brightnessPercent: barState.brightnessPercent

    property real volumeVisualBar: 0
    property bool volumeVisualBarReady: false

    Behavior on volumeVisualBar {
        enabled: root.volumeVisualBarReady
        NumberAnimation {
            duration: 260
            easing.type: Easing.OutCubic
        }
    }

    Connections {
        target: root
        function onVolumePercentChanged() {
            if (!root.volumeVisualBarReady)
                return;
            root.volumeVisualBar = Math.max(0, Math.min(100, root.volumePercent));
        }
    }

    readonly property string volText: root._volumeBarRichText(root.volumeVisualBar, root.volumeMuted)

    property real brightnessVisualBar: 0
    property bool brightnessVisualBarReady: false

    Behavior on brightnessVisualBar {
        enabled: root.brightnessVisualBarReady
        NumberAnimation {
            duration: 260
            easing.type: Easing.OutCubic
        }
    }

    Connections {
        target: root
        function onBrightnessPercentChanged() {
            if (!root.brightnessVisualBarReady)
                return;
            root.brightnessVisualBar = Math.max(1, Math.min(100, root.brightnessPercent));
        }
    }

    readonly property string briText: root._brightnessBarRichText(root.brightnessVisualBar)

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
    property alias statusMenuPanelId: barState.statusMenuPanelId
    property real statusMenuTopY: 0
    property alias wifiConnectSsid: barState.wifiConnectSsid
    property alias wifiConnectPassword: barState.wifiConnectPassword
    property alias wifiConnectError: barState.wifiConnectError
    property alias wifiConnecting: barState.wifiConnecting
    property alias btDeviceTarget: barState.btDeviceTarget
    property alias wifiNetworks: barState.wifiNetworks
    property alias btDevices: barState.btDevices
    property alias activeWorkspaceIds: barState.activeWorkspaceIds
    property alias occupiedWorkspaceIds: barState.occupiedWorkspaceIds
    property alias focusedWorkspaceId: barState.focusedWorkspaceId
    readonly property var workspaceInfos: barState.workspaceInfos
    readonly property var workspaceMonitors: barState.workspaceMonitors
    property alias workspaceClients: barState.workspaceClients
    property bool statusMenuInputFocused: false
    // Top bar uses width from the menu surface; side bar uses an adaptive hug width.
    property bool statusMenuHugWidth: true
    property int sideMenuHugContentWidth: 228
    readonly property int wifiSideMenuWidth: 228
    readonly property int btSideMenuWidth: 244
    readonly property int audioSideMenuWidth: 264
    readonly property int brightnessSideMenuWidth: 264
    readonly property int batterySideMenuWidth: 196
    // Align to the layer surface right edge — not the centered status column (avoids large horizontal error).
    readonly property real statusAnchorX: Math.max(0, root.width - 1)
    readonly property string uiFontFamily: root.config.fontFamily
    readonly property int uiFontSize: root.config.fontPixelSize
    readonly property int mediumPollMs: root.config.barMediumPollMs
    readonly property int slowPollMs: root.config.barSlowPollMs
    readonly property int workspacePollMs: root.config.barWorkspacePollMs
    // Status menu hover close delay (slide length is overlaySlideDurationMs in settings).
    readonly property int statusMenuCloseDelayMs: root.config.hoverReleaseMs + 220
    // Visual gap between status stack rows; hit targets extend by half above/below (no dead zones).
    readonly property int statusColVisualSpacing: 4
    readonly property real statusColHitBleed: statusColVisualSpacing * 0.5
    readonly property var barOverlayVisibility: root.config.barOverlayVisibility || ({})
    property int workspacePreviewId: 0
    property int workspacePreviewDisplayId: 0
    property real workspacePreviewTopY: 0
    property real workspacePreviewAnchorCenterY: 0
    property bool workspacePreviewShown: false
    property bool workspacePreviewHovered: false
    readonly property var workspacePreviewItems: _workspacePreviewItems(workspacePreviewDisplayId)

    readonly property string barMonitorName: root.screen ? root.screen.name : ""
    readonly property var filteredWorkspaceIds: {
        if (root.config.workspaceShowAllScreens)
            return occupiedWorkspaceIds;
        const name = barMonitorName;
        if (!name.length)
            return occupiedWorkspaceIds;
        const infos = workspaceInfos;
        return occupiedWorkspaceIds.filter(function(id) {
            for (let i = 0; i < infos.length; i++) {
                if (Number(infos[i].id) === Number(id))
                    return String(infos[i].monitorName || "") === name;
            }
            return false;
        });
    }
    readonly property var visibleWorkspaceIds: _visibleWorkspaceIds(filteredWorkspaceIds)
    function _visibleWorkspaceIds(ids) {
        const activeIds = ids || [];
        const count = Math.max(1, Number(root.config.workspaceVisibleCount) || 8);

        let withApps = [];
        let seen = {};
        let localActive = {};
        for (let i = 0; i < activeIds.length; i++) {
            const wsId = Number(activeIds[i]);
            if (wsId < 1 || wsId > count)
                continue;
            localActive[wsId] = true;
            if (seen[wsId])
                continue;
            if (root._workspaceIsActive(wsId)) {
                withApps.push(wsId);
                seen[wsId] = true;
            }
        }

        let blocked = {};
        if (!root.config.workspaceShowAllScreens) {
            const globalActive = root.occupiedWorkspaceIds || [];
            for (let i = 0; i < globalActive.length; i++) {
                const wsId = Number(globalActive[i]);
                if (wsId >= 1 && wsId <= count && !localActive[wsId])
                    blocked[wsId] = true;
            }
        }

        let rest = [];
        for (let wsId = 1; wsId <= count; wsId++) {
            if (seen[wsId] || blocked[wsId])
                continue;
            rest.push(wsId);
        }

        return withApps.concat(rest).slice(0, count);
    }
    function _workspaceMonitorName(workspaceId) {
        const id = Number(workspaceId);
        const infos = workspaceInfos || [];
        for (let i = 0; i < infos.length; i++) {
            if (Number(infos[i].id) === id)
                return String(infos[i].monitorName || "");
        }
        return "";
    }
    function _workspaceGroups(ids) {
        const list = ids || [];
        return [{ monitorName: barMonitorName, ids: list }];
    }
    function _workspaceOnCurrentScreen(workspaceId) {
        const id = Number(workspaceId);
        const name = String(barMonitorName || "");
        const infos = workspaceInfos || [];
        if (!name.length)
            return false;
        for (let i = 0; i < infos.length; i++) {
            if (Number(infos[i].id) === id)
                return String(infos[i].monitorName || "") === name;
        }
        return false;
    }
    function _workspaceIsActive(workspaceId) {
        const id = Number(workspaceId);
        const active = root.occupiedWorkspaceIds || [];
        for (let i = 0; i < active.length; i++) {
            if (Number(active[i]) === id)
                return true;
        }
        return false;
    }
    function _workspaceClientCount(workspaceId) {
        let count = 0;
        for (let i = 0; i < workspaceClients.length; i++) {
            if (Number(workspaceClients[i].workspaceId) === Number(workspaceId))
                count += 1;
        }
        return count;
    }
    function _workspaceClientIcons(workspaceId) {
        let out = [];
        const maxIcons = Math.max(0, Number(root.config.workspaceMaxIcons) || 1);
        if (maxIcons < 1)
            return out;
        for (let i = 0; i < workspaceClients.length; i++) {
            const client = workspaceClients[i];
            if (Number(client.workspaceId) === Number(workspaceId) && String(client.iconPath || "").length > 0)
                out.push(String(client.iconPath));
            if (out.length >= maxIcons)
                break;
        }
        return out;
    }
    function _iconSource(path) {
        const p = String(path || "").trim();
        if (!p.length)
            return "";
        if (p.indexOf("file://") === 0 || p.indexOf("qrc:/") === 0 || p.indexOf("image://") === 0)
            return p;
        if (p.charAt(0) === "/")
            return "file://" + p;
        return p;
    }
    function _workspaceChipWidth(workspaceId) {
        const wsText = String(Number(workspaceId) || workspaceId);
        const digits = Math.max(1, wsText.length);
        const labelWidth = Math.ceil(digits * (root.uiFontSize * 0.62)) + 8;
        if (!root.config.workspaceShowWindowIcons)
            return Math.max(24, labelWidth + 10);
        const icons = _workspaceClientIcons(workspaceId);
        const iconCount = icons.length;
        const hasDot = iconCount < 1 && _workspaceClientCount(workspaceId) > 0;
        const iconsWidth = iconCount > 0 ? (iconCount * 11) + Math.max(0, iconCount - 1) : 0;
        const dotWidth = hasDot ? 6 : 0;
        return Math.max(30, labelWidth + 14 + iconsWidth + dotWidth);
    }

    BarState.BarSensorState {
        id: barState
        config: root.config
        visible: root.visible
        includeLocks: false
        dateCommand: "date '+%H\n-\n%M\n-\n%S'"
    }

    FontMetrics {
        id: sideMenuFontMetrics
        font.family: root.uiFontFamily
        font.pixelSize: root.uiFontSize
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
        root.volumeVisualBar = Math.max(0, Math.min(100, root.volumePercent));
        root.volumeVisualBarReady = true;
        root.brightnessVisualBar = Math.max(1, Math.min(100, root.brightnessPercent));
        root.brightnessVisualBarReady = true;
        _applyFontRecursive(root);
        _applyFontRecursive(sideStatusMenu);
    }

    function _shellQuoteSingle(value) {
        return String(value).replace(/'/g, "'\"'\"'");
    }

    function _barOverlayEnabled(name, fallback) {
        const map = barOverlayVisibility || {};
        if (map[name] === undefined)
            return fallback;
        return !!map[name];
    }

    function _cssRgba(c) {
        return "rgba(" + Math.round(255 * c.r) + "," + Math.round(255 * c.g) + "," + Math.round(255 * c.b) + "," + c.a + ")";
    }

    function _volumeBarRichText(percent, muted) {
        const p = Math.max(0, Math.min(100, Number(percent)));
        const total = 8;
        const fillThr = (p / 100) * total;
        const barFg = root.config.barTextColor;
        const inactive = Qt.rgba(barFg.r, barFg.g, barFg.b, 0.5);
        const base = barFg;
        const hi = root.config.volumeColor;
        const mutedFull = Qt.color("#6b7280");
        let bars = "";
        for (let i = 1; i <= total; i++) {
            const full = muted ? mutedFull : (i > 5 ? hi : base);
            let color;
            if (fillThr <= i - 1)
                color = inactive;
            else if (fillThr >= i)
                color = full;
            else {
                const frac = fillThr - (i - 1);
                color = Qt.rgba(
                    inactive.r + (full.r - inactive.r) * frac,
                    inactive.g + (full.g - inactive.g) * frac,
                    inactive.b + (full.b - inactive.b) * frac,
                    inactive.a + (full.a - inactive.a) * frac
                );
            }
            bars += "<span style=\"letter-spacing:-2px; color:" + root._cssRgba(color) + ";\">|</span>";
        }
        return bars;
    }

    function _brightnessBarRichText(percent) {
        const p = Math.max(1, Math.min(100, Number(percent)));
        const total = 8;
        const fillThr = ((p - 1) / 99) * total;
        const barFg = root.config.barTextColor;
        const inactive = Qt.rgba(barFg.r, barFg.g, barFg.b, 0.5);
        const base = barFg;
        const hi = root.config.overlayAccentColor;
        let bars = "";
        for (let i = 1; i <= total; i++) {
            const full = i > 5 ? hi : base;
            let color;
            if (fillThr <= i - 1)
                color = inactive;
            else if (fillThr >= i)
                color = full;
            else {
                const frac = fillThr - (i - 1);
                color = Qt.rgba(
                    inactive.r + (full.r - inactive.r) * frac,
                    inactive.g + (full.g - inactive.g) * frac,
                    inactive.b + (full.b - inactive.b) * frac,
                    inactive.a + (full.a - inactive.a) * frac
                );
            }
            bars += "<span style=\"letter-spacing:-2px; color:" + root._cssRgba(color) + ";\">|</span>";
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

    function _setLocalBrightness(percent) {
        brightnessPercent = Math.max(1, Math.min(100, Math.round(percent)));
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

    function _itemTopY(item) {
        if (!item)
            return 0;
        const point = item.mapToItem(null, 0, 0);
        return Math.max(0, Number(point.y) || 0);
    }

    function _itemCenterY(item) {
        if (!item)
            return 0;
        return _itemTopY(item) + (Math.max(0, Number(item.height) || 0) / 2);
    }

    function _estimatedTextWidth(text, padding) {
        return Math.ceil(sideMenuFontMetrics.averageCharacterWidth * String(text || "").length) + (padding || 0);
    }

    function _widestText(lines, padding) {
        let width = 0;
        for (let i = 0; i < lines.length; i++)
            width = Math.max(width, _estimatedTextWidth(lines[i], padding || 0));
        return width;
    }

    function _workspacePreviewItems(workspaceId) {
        let out = [];
        for (let i = 0; i < workspaceClients.length; i++) {
            const client = workspaceClients[i];
            if (Number(client.workspaceId) === Number(workspaceId))
                out.push(client);
        }
        return out;
    }

    function _workspacePreviewTitle(client) {
        const title = String(client.title || "").trim();
        const className = String(client.className || client.initialClass || "").trim();
        if (title.length > 0 && className.length > 0)
            return title + " [" + className + "]";
        return title.length > 0 ? title : (className.length > 0 ? className : "Window");
    }

    function _workspaceInfo(workspaceId) {
        const targetId = Number(workspaceId) || 0;
        for (let i = 0; i < workspaceInfos.length; i++) {
            const info = workspaceInfos[i];
            if (Number(info.id) === targetId)
                return info;
        }
        return null;
    }

    function _workspacePreviewMonitor(workspaceId) {
        const targetId = Number(workspaceId) || 0;
        if (targetId < 1)
            return null;
        const info = _workspaceInfo(targetId);
        if (info) {
            for (let i = 0; i < workspaceMonitors.length; i++) {
                const monitor = workspaceMonitors[i];
                if (String(info.monitorName || "").length > 0 && String(monitor.name || "") === String(info.monitorName))
                    return monitor;
            }
            for (let i = 0; i < workspaceMonitors.length; i++) {
                const monitor = workspaceMonitors[i];
                if (Number(monitor.id) === Number(info.monitorId))
                    return monitor;
            }
        }
        for (let i = 0; i < workspaceMonitors.length; i++) {
            const monitor = workspaceMonitors[i];
            if (Number(monitor.activeWorkspaceId) === targetId)
                return monitor;
        }
        const items = _workspacePreviewItems(targetId);
        for (let i = 0; i < items.length; i++) {
            const targetMonitorId = Number(items[i].monitor);
            for (let j = 0; j < workspaceMonitors.length; j++) {
                const monitor = workspaceMonitors[j];
                if (Number(monitor.id) === targetMonitorId)
                    return monitor;
            }
        }
        return workspaceMonitors.length > 0 ? workspaceMonitors[0] : null;
    }

    function openWorkspacePreview(workspaceId, item) {
        workspacePreviewCloseTimer.stop();
        workspacePreviewId = Number(workspaceId) || 0;
        workspacePreviewDisplayId = workspacePreviewId;
        workspacePreviewShown = workspacePreviewDisplayId > 0;
        if (item) {
            workspacePreviewTopY = _itemTopY(item);
            workspacePreviewAnchorCenterY = _itemCenterY(item);
        }
    }

    function queueWorkspacePreviewClose(workspaceId) {
        if (workspacePreviewId === Number(workspaceId))
            workspacePreviewCloseTimer.restart();
    }

    function refreshStatusMenuData() {
        barState.refreshStatusMenuData();
    }

    function scheduleStatusRefresh() {
        barState.scheduleStatusRefresh();
    }

    function openStatusMenu(name, chipY) {
        statusMenuTopY = Math.max(0, Number(chipY));
        if (name === "battery")
            sideMenuHugContentWidth = batterySideMenuWidth;
        else if (name === "audio")
            sideMenuHugContentWidth = audioSideMenuWidth;
        else if (name === "brightness")
            sideMenuHugContentWidth = brightnessSideMenuWidth;
        else if (name === "bt")
            sideMenuHugContentWidth = btSideMenuWidth;
        else
            sideMenuHugContentWidth = wifiSideMenuWidth;
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

    function dismissWifiPasswordEntry() {
        root.wifiConnectSsid = "";
        root.wifiConnectPassword = "";
        root.wifiConnectError = "";
        root.wifiConnecting = false;
    }

    function clickWifiNetwork(modelData) {
        if (modelData.active) {
            wifiDisconnectProc.exec({ command: ["bash", "-lc", "if command -v nmcli >/dev/null 2>&1; then dev=$(nmcli -t -f DEVICE,TYPE,STATE device status | awk -F: '$2==\"wifi\" && $3==\"connected\" {print $1; exit}'); [ -n \"$dev\" ] && nmcli device disconnect \"$dev\"; fi"] });
        } else {
            if (modelData.secured && root.wifiConnectSsid === modelData.ssid) {
                dismissWifiPasswordEntry();
                return;
            }
            root.wifiConnectError = "";
            if (root.wifiConnectSsid !== modelData.ssid)
                root.wifiConnectPassword = "";
            root.wifiConnectSsid = modelData.ssid;
            if (modelData.secured && !root.wifiConnectPassword)
                return;
            if (modelData.secured) {
                root.wifiConnecting = true;
                wifiConnectProc.exec({ command: ["bash", "-lc", "if command -v nmcli >/dev/null 2>&1; then nmcli dev wifi connect '" + root._shellQuoteSingle(modelData.ssid) + "' password '" + root._shellQuoteSingle(root.wifiConnectPassword) + "'; fi"] });
            } else {
                root.wifiConnecting = true;
                wifiConnectProc.exec({ command: ["bash", "-lc", "if command -v nmcli >/dev/null 2>&1; then nmcli dev wifi connect '" + root._shellQuoteSingle(modelData.ssid) + "'; fi"] });
            }
        }
        root.scheduleStatusRefresh();
    }

    function submitWifiPassword(modelData) {
        root.wifiConnectError = "";
        root.wifiConnecting = true;
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

    function audioSetVolumePercent(pct) {
        const p = Math.max(0, Math.min(100, Math.round(Number(pct))));
        volSetProc.exec({ command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then pactl set-sink-mute @DEFAULT_SINK@ 0; pactl set-sink-volume @DEFAULT_SINK@ " + p + "%; fi"] });
        root._setLocalVolume(p, false);
        volRefreshTimer.restart();
    }

    function audioToggleMute() {
        volMuteProc.exec({ command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then pactl set-sink-mute @DEFAULT_SINK@ toggle; fi"] });
        volRefreshTimer.restart();
    }

    function audioOpenMixer() {
    }

    function brightnessStep(delta) {
        const next = Math.max(1, Math.min(100, root.brightnessPercent + Number(delta)));
        brightnessSetPercent(next);
    }

    function brightnessSetPercent(pct) {
        const p = Math.max(1, Math.min(100, Math.round(Number(pct))));
        briSetProc.exec({ command: ["bash", "-lc", "if command -v brightnessctl >/dev/null 2>&1; then brightnessctl set " + p + "%; fi"] });
        root._setLocalBrightness(p);
        brightnessRefreshTimer.restart();
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
            visible: root.config.workspaceSegmentVisible
            Label {
                text: root.config.formatUiText("My")
                visible: root.config.showShellTitle
                color: root.config.barAccentColor
                font.bold: true
                font.family: root.uiFontFamily
                font.pixelSize: root.uiFontSize + 1
                Layout.alignment: Qt.AlignHCenter
            }
            Rectangle {
                color: "transparent"
                border.width: 0
                border.color: root.config.barAccentColor
                radius: root.config.workspaceRounding
                Layout.alignment: Qt.AlignHCenter
                implicitHeight: workspaceLayer.implicitHeight + 2
                implicitWidth: workspaceLayer.implicitWidth + 2

                Item {
                    id: workspaceLayer
                    anchors.centerIn: parent
                    property var activeItem: null
                    property real activeItemX: 0
                    property real activeItemY: 0
                    property real activeItemW: 0
                    property real activeItemH: 0
                    function _findFocusedChip(node) {
                        if (!node)
                            return null;
                        if (node.wsId !== undefined && Number(node.wsId) === Number(root.focusedWorkspaceId))
                            return node;
                        const kids = node.children || [];
                        for (let i = 0; i < kids.length; i++) {
                            const hit = _findFocusedChip(kids[i]);
                            if (hit)
                                return hit;
                        }
                        return null;
                    }
                    function refreshActiveItem() {
                        const hit = _findFocusedChip(workspaceStack);
                        activeItem = hit;
                        if (!hit)
                            return;
                        const mapped = hit.mapToItem(workspaceLayer, 0, 0);
                        activeItemX = mapped.x;
                        activeItemY = mapped.y;
                        activeItemW = hit.width;
                        activeItemH = hit.height;
                    }
                    implicitHeight: workspaceStack.implicitHeight
                    implicitWidth: workspaceStack.implicitWidth

                    Rectangle {
                        visible: root.config.workspaceHighlightCurrent && workspaceLayer.activeItem !== null
                        x: workspaceLayer.activeItemX
                        y: workspaceLayer.activeItemY
                        width: workspaceLayer.activeItemW
                        height: workspaceLayer.activeItemH
                        radius: root.config.workspaceRounding
                        color: root.config.workspaceHighlightColor
                        z: 1
                        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    }

                    Column {
                        id: workspaceStack
                        spacing: 8
                        z: 2
                        Repeater {
                            id: workspaceGroupRepeater
                            model: root._workspaceGroups(root.visibleWorkspaceIds)
                            delegate: Rectangle {
                    required property var modelData
                    readonly property bool isCurrentScreenGroup: String(modelData.monitorName || "") === String(root.barMonitorName || "")
                    color: "transparent"
                    border.width: 0
                    border.color: "transparent"
                    radius: root.config.workspaceRounding
                    implicitHeight: workspaceGroupCol.implicitHeight + (border.width > 0 ? 6 : 0)
                    implicitWidth: workspaceGroupCol.implicitWidth + (border.width > 0 ? 6 : 0)
                    property real activeFirstY: {
                        let first = -1;
                        for (let i = 0; i < workspaceRepeater.count; i++) {
                            const item = workspaceRepeater.itemAt(i);
                            if (item && item.hasApps) {
                                first = item.y;
                                break;
                            }
                        }
                        return first;
                    }
                    property real activeLastY: {
                        let last = -1;
                        for (let i = workspaceRepeater.count - 1; i >= 0; i--) {
                            const item = workspaceRepeater.itemAt(i);
                            if (item && item.hasApps) {
                                last = item.y + item.height;
                                break;
                            }
                        }
                        return last;
                    }
                    Rectangle {
                        visible: root.config.workspaceActiveScreenBackground && parent.activeFirstY >= 0 && parent.activeLastY > parent.activeFirstY
                        x: 0
                        y: parent.activeFirstY
                        width: parent.width
                        height: Math.max(0, parent.activeLastY - parent.activeFirstY)
                        radius: root.config.workspaceRounding
                        color: root.config.workspaceActiveGroupBackgroundColor
                        border.width: root.config.buttonBorderWidth
                        border.color: root.config.workspaceActiveGroupBorderColor
                        z: 0
                        Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    }
                    Column {
                        id: workspaceGroupCol
                        anchors.centerIn: parent
                        spacing: 6
                        Repeater {
                            id: workspaceRepeater
                            model: modelData.ids || []
                            delegate: Rectangle {
                    id: wsChip
                    required property var modelData
                    readonly property int wsId: Number(modelData)
                    readonly property bool hasApps: root._workspaceIsActive(wsId)
                    implicitWidth: root._workspaceChipWidth(wsId)
                    implicitHeight: 22
                    radius: root.config.workspaceRounding
                    color: (root.config.workspaceHighlightCurrent && wsId === root.focusedWorkspaceId)
                        ? "transparent"
                        : (
                            root.config.workspaceActiveScreenBackground
                            && root.config.workspaceShowAllScreens
                            && root._workspaceOnCurrentScreen(wsId)
                        )
                        ? Qt.rgba(root.config.workspaceAccentColor.r, root.config.workspaceAccentColor.g, root.config.workspaceAccentColor.b, 0.14)
                        : root.config.workspaceBackgroundColor
                    border.width: root.config.buttonBorderWidth
                    border.color: root.config.barAccentColor
                    z: 1
                    Row {
                        anchors.centerIn: parent
                        spacing: 2
                        Label {
                            text: String(wsChip.wsId)
                            color: (root.config.workspaceHighlightCurrent && wsChip.wsId === root.focusedWorkspaceId)
                                ? root.config.workspaceActiveTextColor
                                : root.config.barTextColor
                            font.bold: true
                            font.family: root.uiFontFamily
                            font.pixelSize: root.uiFontSize
                            horizontalAlignment: Text.AlignHCenter
                        }
                        Row {
                            visible: root.config.workspaceShowWindowIcons
                            spacing: 1
                            Repeater {
                                model: root._workspaceClientIcons(wsChip.wsId)
                                delegate: Image {
                                    required property string modelData
                                    source: root._iconSource(modelData)
                                    width: 11
                                    height: 11
                                    fillMode: Image.PreserveAspectFit
                                }
                            }
                        }
                    }
                    Label {
                        visible: root.config.workspaceShowWindowIcons && root._workspaceClientIcons(wsChip.wsId).length < 1 && root._workspaceClientCount(wsChip.wsId) > 0
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        text: "•"
                        color: (root.config.workspaceHighlightCurrent && wsChip.wsId === root.focusedWorkspaceId)
                            ? root.config.workspaceActiveTextColor
                            : root.config.barTextColor
                        font.family: root.uiFontFamily
                        font.pixelSize: root.uiFontSize - 1
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: if (root.config.workspaceShowLayoutOnHover) root.openWorkspacePreview(wsChip.wsId, wsChip)
                        onExited: if (root.config.workspaceShowLayoutOnHover) root.queueWorkspacePreviewClose(wsChip.wsId)
                        onClicked: wsSwitchProc.exec({
                            command: ["bash", "-lc", "if command -v hyprctl >/dev/null 2>&1; then hyprctl dispatch workspace " + wsChip.wsId + "; fi"]
                        })
                    }
                    Component.onCompleted: Qt.callLater(workspaceLayer.refreshActiveItem)
                }
            }
                    }
                }
                    }
                }
            }
                    Component.onCompleted: Qt.callLater(refreshActiveItem)
                    onImplicitWidthChanged: Qt.callLater(refreshActiveItem)
                    onImplicitHeightChanged: Qt.callLater(refreshActiveItem)
        }

        Item {
            Layout.fillHeight: true
        }

        ColumnLayout {
            id: statusCol
            spacing: root.statusColVisualSpacing
            Layout.alignment: Qt.AlignHCenter
            Text {
                visible: root._barOverlayEnabled("clock", true)
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
                visible: root._barOverlayEnabled("clock", true)
                Layout.preferredHeight: root._barOverlayEnabled("clock", true) ? 10 : 0
                Layout.minimumHeight: root._barOverlayEnabled("clock", true) ? 10 : 0
            }
            Item {
                visible: root._barOverlayEnabled("wifi", true)
                Layout.fillWidth: true
                implicitHeight: wifiChip.implicitHeight
                implicitWidth: root.sideBarStatusColumnMaxW
                Rectangle {
                    id: wifiChip
                    z: 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    color: "transparent"
                    border.width: root.config.buttonBorderWidth
                    border.color: root.config.barAccentColor
                    radius: root.config.barRounding
                    width: root.sideBarStatusColumnMaxW
                    height: 22
                    Label {
                        id: wifiLabel
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        leftPadding: 2
                        rightPadding: 2
                        text: root.wifiText
                        color: root.config.barTextColor
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                }
                MouseArea {
                    z: 1
                    y: -root.statusColHitBleed
                    height: parent.height + root.statusColVisualSpacing
                    anchors.left: parent.left
                    anchors.right: parent.right
                    hoverEnabled: true
                    onEntered: root.openStatusMenu("wifi", root._itemTopY(wifiChip))
                    onExited: root.queueStatusMenuClose("wifi")
                    onClicked: root.openStatusMenu("wifi", root._itemTopY(wifiChip))
                }
            }
            Item {
                visible: root._barOverlayEnabled("bluetooth", true)
                Layout.fillWidth: true
                implicitHeight: btChip.implicitHeight
                implicitWidth: 30
                Rectangle {
                    id: btChip
                    z: 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    color: "transparent"
                    border.width: root.config.buttonBorderWidth
                    border.color: root.config.barAccentColor
                    radius: root.config.barRounding
                    implicitWidth: 30
                    implicitHeight: 22
                    Label {
                        id: btLabel
                        anchors.centerIn: parent
                        text: root.btText
                        color: root.config.barTextColor
                        elide: Text.ElideRight
                    }
                }
                MouseArea {
                    z: 1
                    y: -root.statusColHitBleed
                    height: parent.height + root.statusColVisualSpacing
                    anchors.left: parent.left
                    anchors.right: parent.right
                    hoverEnabled: true
                    onEntered: root.openStatusMenu("bt", root._itemTopY(btChip))
                    onExited: root.queueStatusMenuClose("bt")
                    onClicked: root.openStatusMenu("bt", root._itemTopY(btChip))
                }
            }
            Item {
                visible: root._barOverlayEnabled("audio", true)
                Layout.fillWidth: true
                implicitHeight: volChip.implicitHeight
                implicitWidth: 26
                Rectangle {
                    id: volChip
                    z: 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    color: "transparent"
                    border.width: root.config.buttonBorderWidth
                    border.color: root.config.barAccentColor
                    radius: root.config.barRounding
                    implicitWidth: 26
                    implicitHeight: 66
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 2
                        spacing: 0

                        Label {
                            text: "VOL"
                            color: root.config.barTextColor
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
                                color: root.config.barTextColor
                                textFormat: Text.RichText
                                rotation: -90
                                transformOrigin: Item.Center
                                renderType: Text.NativeRendering
                            }
                        }
                    }
                }
                MouseArea {
                    z: 1
                    y: -root.statusColHitBleed
                    height: parent.height + root.statusColVisualSpacing
                    anchors.left: parent.left
                    anchors.right: parent.right
                    hoverEnabled: true
                    onEntered: root.openStatusMenu("audio", root._itemTopY(volChip))
                    onExited: root.queueStatusMenuClose("audio")
                    onClicked: root.openStatusMenu("audio", root._itemTopY(volChip))
                }
            }
            Item {
                visible: root._barOverlayEnabled("brightness", true)
                Layout.fillWidth: true
                implicitHeight: briChip.implicitHeight
                implicitWidth: 26
                Rectangle {
                    id: briChip
                    z: 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    color: "transparent"
                    border.width: root.config.buttonBorderWidth
                    border.color: root.config.barAccentColor
                    radius: root.config.barRounding
                    implicitWidth: 26
                    implicitHeight: 66
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 2
                        spacing: 0

                        Label {
                            text: "BRT"
                            color: root.config.barTextColor
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
                                text: root.briText
                                color: root.config.barTextColor
                                textFormat: Text.RichText
                                rotation: -90
                                transformOrigin: Item.Center
                                renderType: Text.NativeRendering
                            }
                        }
                    }
                }
                MouseArea {
                    z: 1
                    y: -root.statusColHitBleed
                    height: parent.height + root.statusColVisualSpacing
                    anchors.left: parent.left
                    anchors.right: parent.right
                    hoverEnabled: true
                    onEntered: root.openStatusMenu("brightness", root._itemTopY(briChip))
                    onExited: root.queueStatusMenuClose("brightness")
                    onClicked: root.openStatusMenu("brightness", root._itemTopY(briChip))
                }
            }
            Item {
                visible: root._barOverlayEnabled("battery", true)
                Layout.fillWidth: true
                implicitHeight: batChip.implicitHeight
                implicitWidth: 28
                Rectangle {
                    id: batChip
                    z: 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    color: "transparent"
                    border.width: root.config.buttonBorderWidth
                    border.color: root.config.barAccentColor
                    radius: root.config.barRounding
                    implicitWidth: 28
                    implicitHeight: 72
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 2
                        spacing: 0

                        Label {
                            text: "BAT"
                            color: root.config.barTextColor
                            font.family: root.uiFontFamily
                            font.pixelSize: Math.max(9, root.uiFontSize - 1)
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }

                        BatterySegmentIndicator {
                            Layout.alignment: Qt.AlignHCenter
                            percent: root.batteryPercent
                            textColor: root.config.barTextColor
                            accentColor: root.config.barAccentColor
                            segment0Color: root.batteryCharging ? root.config.overlayBatteryBarColorCharging : root.config.overlayBatteryBarColorCritical
                            segment1Color: root.batteryCharging ? root.config.overlayBatteryBarColorCharging : root.config.overlayBatteryBarColorLow
                            segment2Color: root.batteryCharging ? root.config.overlayBatteryBarColorCharging : root.config.overlayBatteryBarColorMedium
                            segment3Color: root.batteryCharging ? root.config.overlayBatteryBarColorCharging : root.config.overlayBatteryBarColorFull
                            barRadius: Math.max(0, Math.min(root.config.rounding, 6))
                            segmentWidth: 12
                            segmentHeight: 4
                            segmentSpacing: 2
                        }
                    }
                }
                MouseArea {
                    z: 1
                    y: -root.statusColHitBleed
                    height: parent.height + root.statusColVisualSpacing
                    anchors.left: parent.left
                    anchors.right: parent.right
                    hoverEnabled: true
                    onEntered: root.openStatusMenu("battery", root._itemTopY(batChip))
                    onExited: root.queueStatusMenuClose("battery")
                    onClicked: root.openStatusMenu("battery", root._itemTopY(batChip))
                }
            }
        }
    }

    PanelWindow {
        id: workspacePreviewWindow
        screen: root.screen
        property bool shown: root.workspacePreviewShown
        property bool mounted: shown
        property bool presented: shown
        visible: workspacePreviewWindow.mounted
        onShownChanged: {
            if (shown) {
                mounted = true;
                presented = false;
                workspacePreviewHideTimer.stop();
                workspacePreviewPresentTimer.restart();
            } else if (mounted) {
                presented = false;
                workspacePreviewHideTimer.restart();
            }
        }
        anchors {
            top: true
            left: true
        }
        margins {
            top: Math.max(
                0,
                Math.min(
                    Math.max(0, root.height - workspacePreviewWindow.implicitHeight),
                    root.workspacePreviewAnchorCenterY - (workspacePreviewWindow.implicitHeight / 2)
                )
            )
            left: Math.max(0, root.width - root.config.overlayBorderWidth)
        }
        implicitWidth: workspacePreviewPanel.implicitWidth
        implicitHeight: workspacePreviewPanel.implicitHeight
        exclusiveZone: 0
        color: "transparent"

        WorkspacePreviewSurface {
            id: workspacePreviewPanel
            readonly property real hiddenX: -(workspacePreviewWindow.implicitWidth + 8)
            width: parent.width
            height: parent.height
            visible: workspacePreviewWindow.mounted
            x: workspacePreviewWindow.presented ? 0 : hiddenX
            host: root
            workspaceId: root.workspacePreviewDisplayId
            items: root.workspacePreviewItems
            previewMonitor: root._workspacePreviewMonitor(root.workspacePreviewDisplayId)

            Behavior on x {
                enabled: root.config.uiAnimationsEnabled
                NumberAnimation { duration: root.config.overlaySlideDurationMs; easing.type: Easing.OutCubic }
            }
        }

        HoverHandler {
            enabled: workspacePreviewWindow.mounted
            onHoveredChanged: {
                root.workspacePreviewHovered = hovered;
                if (hovered)
                    workspacePreviewCloseTimer.stop();
                else
                    workspacePreviewCloseTimer.restart();
            }
        }

        Timer {
            id: workspacePreviewPresentTimer
            interval: 16
            repeat: false
            onTriggered: {
                if (workspacePreviewWindow.shown)
                    workspacePreviewWindow.presented = true;
            }
        }

        Timer {
            id: workspacePreviewHideTimer
            interval: root.config.uiAnimationsEnabled ? root.config.overlaySlideDurationMs + 20 : 1
            repeat: false
            onTriggered: {
                if (!workspacePreviewWindow.shown) {
                    workspacePreviewWindow.presented = false;
                    workspacePreviewWindow.mounted = false;
                }
            }
        }
    }

    PanelWindow {
        id: sideStatusMenu
        screen: root.screen
        property bool shown: root.activeStatusMenu.length > 0
        property bool mounted: shown
        property bool presented: shown
        property real slideTravelX: 200
        readonly property int statusSlideDurationMs: root.config.overlaySlideDurationMs
        visible: sideStatusMenu.mounted
        onShownChanged: {
            if (shown) {
                mounted = true;
                sideStatusMenuHideTimer.stop();
                slideTravelX = Math.max(120, sideStatusContent.implicitWidth + 24);
                presented = false;
                Qt.callLater(function () {
                    if (!sideStatusMenu.shown)
                        return;
                    slideTravelX = Math.max(120, sideStatusContent.implicitWidth + 24);
                    sideStatusMenuPresentTimer.restart();
                });
            } else if (mounted) {
                slideTravelX = Math.max(120, sideStatusContent.implicitWidth + 24);
                presented = false;
                sideStatusMenuHideTimer.restart();
            }
        }
        focusable: root.statusMenuPanelId === "wifi"
        WlrLayershell.keyboardFocus: root.statusMenuPanelId === "wifi" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        anchors {
            top: true
            left: true
        }
        margins {
            top: Math.max(0, root.statusMenuTopY)
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
                enabled: sideStatusMenu.mounted
                onHoveredChanged: {
                    if (hovered)
                        sideMenuCloseTimer.stop();
                    else
                        sideMenuCloseTimer.restart();
                }
            }

            Rectangle {
                id: sidePanel
                width: parent.width
                height: parent.height
                radius: root.config.overlayRounding
                color: root.config.borderColor
                transform: Translate {
                    x: sideStatusMenu.presented ? 0 : -sideStatusMenu.slideTravelX
                    Behavior on x {
                        enabled: root.config.uiAnimationsEnabled
                        NumberAnimation {
                            duration: sideStatusMenu.statusSlideDurationMs
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: root.config.overlayBorderWidth
                    radius: Math.max(0, root.config.overlayRounding - root.config.overlayBorderWidth)
                    color: root.config.overlayBackgroundColor
                }

                Column {
                    id: sideStatusContent
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.margins: 8
                    spacing: 8

                    Label {
                        width: root.sideMenuHugContentWidth
                        text: root.statusMenuPanelId === "wifi" ? root.networkDisplayText
                            : root.statusMenuPanelId === "bt" ? "BLUETOOTH"
                            : root.statusMenuPanelId === "battery" ? "BATTERY"
                            : root.statusMenuPanelId === "audio" ? "AUDIO"
                            : root.statusMenuPanelId === "brightness" ? "BRIGHTNESS"
                            : ""
                        color: root.config.overlayAccentColor
                        font.bold: true
                        elide: Text.ElideRight
                    }
                    Status.WifiMenuContent {
                        visible: root.statusMenuPanelId === "wifi"
                        host: root
                        listHeight: 250
                    }

                    Status.BluetoothMenuContent {
                        visible: root.statusMenuPanelId === "bt"
                        host: root
                        toggleWidth: 34
                        toggleHeight: 18
                        knobSize: 12
                        listHeight: 160
                    }

                    Status.AudioMenuContent {
                        visible: root.statusMenuPanelId === "audio"
                        host: root
                        outputListHeight: 100
                        inputListHeight: 92
                        menuFontBoost: 7
                        showMixer: false
                    }

                    Status.BrightnessMenuContent {
                        visible: root.statusMenuPanelId === "brightness"
                        host: root
                        menuFontBoost: 7
                    }

                    Status.BatteryMenuContent {
                        visible: root.statusMenuPanelId === "battery"
                        host: root
                    }
                }
            }
        }

        Timer {
            id: sideStatusMenuPresentTimer
            interval: 0
            repeat: false
            onTriggered: {
                if (sideStatusMenu.shown)
                    sideStatusMenu.presented = true;
            }
        }

        Timer {
            id: sideStatusMenuHideTimer
            interval: root.config.uiAnimationsEnabled ? root.config.overlaySlideDurationMs + 100 : 1
            repeat: false
            onTriggered: {
                if (!sideStatusMenu.shown) {
                    root.statusMenuPanelId = "";
                    sideStatusMenu.presented = false;
                    sideStatusMenu.mounted = false;
                }
            }
        }
    }

    Process { id: wsSwitchProc }
    Process { id: volStepProc }
    Process { id: volSetProc }
    Process { id: volMuteProc }
    Process {
        id: wifiConnectProc
        stderr: StdioCollector {
            id: wifiConnectStderrCollector
            waitForEnd: true
        }
        onExited: (exitCode, exitStatus) => {
            root.wifiConnecting = false;
            root.scheduleStatusRefresh();
            if (exitCode === 0) {
                root.wifiConnectError = "";
                root.wifiConnectPassword = "";
                return;
            }
            const raw = String(wifiConnectStderrCollector.text || "").trim();
            root.wifiConnectError = barState.humanizeWifiConnectError(raw);
        }
    }
    Process { id: wifiDisconnectProc }
    Process { id: wifiToggleProc }
    Process { id: btConnectProc }
    Process { id: btDisconnectProc }
    Process { id: btPowerProc }
    Process { id: btDiscoverableProc }
    Process { id: audioSinkSetProc }
    Process { id: audioSourceSetProc }
    Process { id: briSetProc }
    Timer {
        id: workspacePreviewCloseTimer
        interval: root.config.hoverReleaseMs
        repeat: false
        onTriggered: {
            if (!root.workspacePreviewHovered)
                root.workspacePreviewShown = false;
        }
    }

    Timer {
        id: hoverReleaseTimer
        interval: root.config.hoverReleaseMs
        repeat: false
        onTriggered: root.shell.dashboardTriggerHovered = false
    }

    Timer {
        id: sideMenuCloseTimer
        interval: root.statusMenuCloseDelayMs
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

    Timer {
        id: brightnessRefreshTimer
        interval: 140
        repeat: false
        onTriggered: {
            barState.refreshBrightnessData();
        }
    }

    Connections {
        target: barState
        function onActiveStatusMenuChanged() {
            if (root.activeStatusMenu !== "wifi") {
                root.statusMenuInputFocused = false;
                root.dismissWifiPasswordEntry();
            }
            root._applyFontRecursive(sideStatusMenu);
        }
        function onFocusedWorkspaceIdChanged() {
            Qt.callLater(workspaceLayer.refreshActiveItem);
        }
    }
}
}
