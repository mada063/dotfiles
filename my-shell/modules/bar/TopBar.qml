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
    required property BarState.BarSensorState sensors

    property string activeStatusMenu: ""
    property string statusMenuPanelId: ""

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 34
    exclusiveZone: 34
    color: "transparent"

    readonly property string dateTimeText: sensors.dateText
    readonly property string wifiText: root.networkDisplayText
    readonly property string btText: "BT"
    readonly property string batteryText: root._batteryRichText(root.batteryPercent)
    // "discharging" contains substring "charging" — exclude before testing charge state.
    readonly property bool batteryCharging: {
        const s = String(root.batteryStatusText || "").toLowerCase();
        if (s.indexOf("discharging") >= 0)
            return false;
        if (s.indexOf("not charging") >= 0)
            return false;
        return s.indexOf("charging") >= 0;
    }
    property alias batteryPercent: sensors.batteryPercent
    property alias capsLockOn: sensors.capsLockOn
    property alias numLockOn: sensors.numLockOn
    property alias wifiDetailText: sensors.wifiDetailText
    property alias btDetailText: sensors.btDetailText
    property alias volumePercent: sensors.volumePercent
    property alias volumeMuted: sensors.volumeMuted
    property alias brightnessPercent: sensors.brightnessPercent

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

    readonly property string audioText: root._volumeRichText(root.volumeVisualBar, root.volumeMuted)

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

    readonly property string brightnessText: root._brightnessRichText(root.brightnessVisualBar)

    property alias networkEnabled: sensors.networkEnabled
    property alias networkDisplayText: sensors.networkDisplayText
    property alias networkTypeText: sensors.networkTypeText
    property alias wifiDeviceName: sensors.wifiDeviceName
    property alias wifiConnected: sensors.wifiConnected
    property alias btEnabled: sensors.btEnabled
    property alias btDiscoverable: sensors.btDiscoverable
    property alias audioOutputs: sensors.audioOutputs
    property alias audioInputs: sensors.audioInputs
    property alias batteryTimeText: sensors.batteryTimeText
    property alias batteryStatusText: sensors.batteryStatusText
    property real statusMenuLeftX: Math.max(0, root.width - 280)
    property int statusMenuWidth: 280
    readonly property int wifiStatusMenuWidth: 350
    readonly property int btStatusMenuWidth: 320
    readonly property int audioStatusMenuWidth: 350
    readonly property int brightnessStatusMenuWidth: 288
    readonly property int batteryStatusMenuWidth: 220
    readonly property int locksStatusMenuWidth: 132
    property alias wifiConnectSsid: sensors.wifiConnectSsid
    property alias wifiConnectPassword: sensors.wifiConnectPassword
    property alias wifiConnectError: sensors.wifiConnectError
    property alias wifiConnecting: sensors.wifiConnecting
    property alias btDeviceTarget: sensors.btDeviceTarget
    property alias wifiNetworks: sensors.wifiNetworks
    property alias btDevices: sensors.btDevices
    property alias activeWorkspaceIds: sensors.activeWorkspaceIds
    property alias occupiedWorkspaceIds: sensors.occupiedWorkspaceIds
    property alias focusedWorkspaceId: sensors.focusedWorkspaceId
    readonly property var workspaceInfos: sensors.workspaceInfos
    readonly property var workspaceMonitors: sensors.workspaceMonitors
    property alias workspaceClients: sensors.workspaceClients
    property bool statusMenuInputFocused: false
    readonly property real statusMenuContentWidth: Math.max(240, statusMenuWindow.width - 16)
    property bool statusMenuHugWidth: false
    readonly property int sideMenuHugContentWidth: 280
    readonly property string uiFontFamily: root.config.fontFamily
    readonly property int uiFontSize: root.config.fontPixelSize
    readonly property int mediumPollMs: root.config.barMediumPollMs
    readonly property int slowPollMs: root.config.barSlowPollMs
    readonly property int workspacePollMs: root.config.barWorkspacePollMs
    // Match Quick Settings: hoverReleaseMs + closeDebounce (50) + hide (170).
    readonly property int statusMenuCloseDelayMs: root.config.hoverReleaseMs + 220
    // Visual gap between status chips; hit targets extend by half on each side (no dead zones).
    readonly property int statusRowVisualSpacing: 4
    readonly property real statusRowHitBleed: statusRowVisualSpacing * 0.5
    readonly property var barOverlayVisibility: root.config.barOverlayVisibility || ({})
    property int workspacePreviewId: 0
    property int workspacePreviewDisplayId: 0
    property real workspacePreviewLeftX: 0
    property real workspacePreviewAnchorCenterX: 0
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
        const iconsWidth = iconCount > 0 ? (iconCount * 12) + Math.max(0, iconCount - 1) : 0;
        const dotWidth = hasDot ? 6 : 0;
        return Math.max(30, labelWidth + 14 + iconsWidth + dotWidth);
    }

    FontMetrics {
        id: statusMenuFontMetrics
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
        _applyFontRecursive(statusMenuWindow);
    }
    onUiFontSizeChanged: {
        _applyFontRecursive(root);
        _applyFontRecursive(statusMenuWindow);
    }
    Component.onCompleted: {
        sensors.dateCommand = root._dateCommand();
        root.volumeVisualBar = Math.max(0, Math.min(100, root.volumePercent));
        root.volumeVisualBarReady = true;
        root.brightnessVisualBar = Math.max(1, Math.min(100, root.brightnessPercent));
        root.brightnessVisualBarReady = true;
        _applyFontRecursive(root);
        _applyFontRecursive(statusMenuWindow);
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

    function _levelBars(percent, steps) {
        const p = Math.max(0, Math.min(100, Number(percent)));
        const total = Math.max(1, Number(steps) || 10);
        const on = Math.round((p / 100) * total);
        return "|".repeat(on) + "·".repeat(total - on);
    }

    function _cssRgba(c) {
        return "rgba(" + Math.round(255 * c.r) + "," + Math.round(255 * c.g) + "," + Math.round(255 * c.b) + "," + c.a + ")";
    }

    function _volumeRichText(percent, muted) {
        const p = Math.max(0, Math.min(100, Number(percent)));
        const total = 10;
        const fillThr = (p / 100) * total;
        const barFg = root.config.barTextColor;
        const inactive = Qt.rgba(barFg.r, barFg.g, barFg.b, 0.5);
        const base = barFg;
        const hi = root.config.volumeColor;
        const mutedFull = Qt.color("#6b7280");
        let bars = "";
        for (let i = 1; i <= total; i++) {
            const full = muted ? mutedFull : (i > 7 ? hi : base);
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
        return "VOL " + bars;
    }

    function _brightnessRichText(percent) {
        const p = Math.max(1, Math.min(100, Number(percent)));
        const total = 10;
        const fillThr = ((p - 1) / 99) * total;
        const barFg = root.config.barTextColor;
        const inactive = Qt.rgba(barFg.r, barFg.g, barFg.b, 0.5);
        const base = barFg;
        const hi = root.config.overlayAccentColor;
        let bars = "";
        for (let i = 1; i <= total; i++) {
            const full = i > 7 ? hi : base;
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
        return "BRT " + bars;
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

    function _dateCommand() {
        const dateFmt = String(root.config.overlayDateFormat || "%a %d %b").trim();
        const timeFmt = String(root.config.overlayTimeFormat || "%H:%M").trim();
        const mode = String(root.config.overlayDateTimeFormat || "date-time").trim().toLowerCase();
        if (mode === "date")
            return "date '+" + dateFmt + "'";
        if (mode === "time")
            return "date '+" + timeFmt + "'";
        if (mode === "iso")
            return "date '+%F %T'";
        return "date '+" + dateFmt + " " + timeFmt + "'";
    }

    function _itemLeftX(item) {
        if (!item)
            return 0;
        const point = item.mapToItem(null, 0, 0);
        return Math.max(0, Number(point.x) || 0);
    }

    function _itemCenterX(item) {
        if (!item)
            return 0;
        return _itemLeftX(item) + (Math.max(0, Number(item.width) || 0) / 2);
    }

    function _estimatedTextWidth(text, padding) {
        return Math.ceil(statusMenuFontMetrics.averageCharacterWidth * String(text || "").length) + (padding || 0);
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
            workspacePreviewLeftX = _itemLeftX(item);
            workspacePreviewAnchorCenterX = _itemCenterX(item);
        }
    }

    function queueWorkspacePreviewClose(workspaceId) {
        if (workspacePreviewId === Number(workspaceId))
            workspacePreviewCloseTimer.restart();
    }

    function refreshStatusMenuData() {
        sensors.refreshStatusMenuData(root.activeStatusMenu);
    }

    function scheduleStatusRefresh() {
        sensors.scheduleStatusRefresh(root.activeStatusMenu);
    }

    function openStatusMenu(name, chipX) {
        statusPopupCloseTimer.stop();
        statusMenuInputFocused = false;
        activeStatusMenu = name;
        statusMenuPanelId = name;
        let desiredWidth = wifiStatusMenuWidth;
        if (name === "locks")
            desiredWidth = locksStatusMenuWidth;
        else if (name === "battery")
            desiredWidth = batteryStatusMenuWidth;
        else if (name === "audio")
            desiredWidth = audioStatusMenuWidth;
        else if (name === "brightness")
            desiredWidth = brightnessStatusMenuWidth;
        else if (name === "bt")
            desiredWidth = btStatusMenuWidth;
        statusMenuWidth = desiredWidth;
        if (chipX !== undefined) {
            const leftX = Math.max(0, Number(chipX) || 0);
            const overflow = Math.max(0, leftX + desiredWidth - root.width);
            statusMenuLeftX = Math.max(0, leftX - overflow);
        }
        sensors.handleStatusMenuOpened(name);
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
        sensors.handleStatusMenuOpened("wifi");
        sensors.refreshStatusMenuData();
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
        sensors.handleStatusMenuOpened("bt");
        sensors.refreshStatusMenuData();
    }

    function audioStep(delta) {
        const amount = Number(delta) >= 0 ? "+" + Math.abs(Number(delta)) : String(Number(delta));
        volStepProc.exec({ command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then pactl set-sink-volume @DEFAULT_SINK@ " + amount + "%; fi"] });
        audioRefreshTimer.restart();
    }

    function audioSetVolumePercent(pct) {
        const p = Math.max(0, Math.min(100, Math.round(Number(pct))));
        volSetProc.exec({ command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then pactl set-sink-mute @DEFAULT_SINK@ 0; pactl set-sink-volume @DEFAULT_SINK@ " + p + "%; fi"] });
        root._setLocalVolume(p, false);
        audioRefreshTimer.restart();
    }

    function audioToggleMute() {
        volMuteProc.exec({ command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then pactl set-sink-mute @DEFAULT_SINK@ toggle; fi"] });
        audioRefreshTimer.restart();
    }

    function audioOpenMixer() {
        openMixerProc.exec({ command: ["bash", "-lc", "if command -v pavucontrol >/dev/null 2>&1; then pavucontrol; fi"] });
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

    Rectangle {
        anchors.fill: parent
        color: root.config.barBackgroundColor
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
        color: root.config.barAccentColor
        z: 1000
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10

        RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignVCenter
            visible: root.config.workspaceSegmentVisible
            Label {
                text: root.config.formatUiText("MyShell")
                visible: root.config.showShellTitle
                color: root.config.barAccentColor
                font.bold: true
                font.family: root.uiFontFamily
                font.pixelSize: root.uiFontSize + 1
            }
            Rectangle {
                color: "transparent"
                border.width: 0
                border.color: root.config.barAccentColor
                radius: root.config.workspaceRounding
                implicitHeight: 22
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
                        const hit = _findFocusedChip(workspaceRow);
                        activeItem = hit;
                        if (!hit)
                            return;
                        const mapped = hit.mapToItem(workspaceLayer, 0, 0);
                        activeItemX = mapped.x;
                        activeItemY = mapped.y;
                        activeItemW = hit.width;
                        activeItemH = hit.height;
                    }
                    implicitWidth: workspaceRow.implicitWidth
                    implicitHeight: workspaceRow.implicitHeight

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
                        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    }

                    Row {
                        id: workspaceRow
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
                                implicitHeight: workspaceGroupRow.implicitHeight + (border.width > 0 ? 6 : 0)
                                implicitWidth: workspaceGroupRow.implicitWidth + (border.width > 0 ? 6 : 0)
                                property real activeFirstX: {
                                    let first = -1;
                                    for (let i = 0; i < workspaceRepeater.count; i++) {
                                        const item = workspaceRepeater.itemAt(i);
                                        if (item && item.hasApps) {
                                            first = item.x;
                                            break;
                                        }
                                    }
                                    return first;
                                }
                                property real activeLastX: {
                                    let last = -1;
                                    for (let i = workspaceRepeater.count - 1; i >= 0; i--) {
                                        const item = workspaceRepeater.itemAt(i);
                                        if (item && item.hasApps) {
                                            last = item.x + item.width;
                                            break;
                                        }
                                    }
                                    return last;
                                }

                                Rectangle {
                                    visible: root.config.workspaceActiveScreenBackground && parent.activeFirstX >= 0 && parent.activeLastX > parent.activeFirstX
                                    x: parent.activeFirstX
                                    y: 0
                                    width: Math.max(0, parent.activeLastX - parent.activeFirstX)
                                    height: parent.height
                                    radius: root.config.workspaceRounding
                                    color: root.config.workspaceActiveGroupBackgroundColor
                                    border.width: root.config.buttonBorderWidth
                                    border.color: root.config.workspaceActiveGroupBorderColor
                                    z: 0
                                    Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                    Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                                }

                                Row {
                                    id: workspaceGroupRow
                                    anchors.centerIn: parent
                                    spacing: 5
                                    Repeater {
                                        id: workspaceRepeater
                                        model: modelData.ids || []
                                        delegate: Rectangle {
                                            id: wsChip
                                            required property var modelData
                                            readonly property int wsId: Number(modelData)
                                            readonly property bool hasApps: root._workspaceIsActive(wsId)
                                            property bool wsHovered: wsMouse.containsMouse
                                            color: (root.config.workspaceHighlightCurrent && wsId === root.focusedWorkspaceId)
                                                ? "transparent"
                                                : (wsHovered
                                                    ? Qt.rgba(root.config.workspaceAccentColor.r, root.config.workspaceAccentColor.g, root.config.workspaceAccentColor.b, 0.18)
                                                    : root.config.workspaceBackgroundColor)
                                            border.width: root.config.buttonBorderWidth
                                            border.color: wsHovered ? root.config.workspaceAccentColor : root.config.barAccentColor
                                            radius: root.config.workspaceRounding
                                            implicitWidth: root._workspaceChipWidth(wsId)
                                            implicitHeight: 22
                                            scale: wsHovered ? 1.05 : 1
                                            z: 1
                                            Behavior on scale { NumberAnimation { duration: 90 } }
                                            Row {
                                                anchors.centerIn: parent
                                                spacing: 3
                                                Label {
                                                    text: String(wsChip.wsId)
                                                    color: (root.config.workspaceHighlightCurrent && wsChip.wsId === root.focusedWorkspaceId)
                                                        ? root.config.workspaceActiveTextColor
                                                        : root.config.barTextColor
                                                    font.bold: true
                                                    font.family: root.uiFontFamily
                                                    font.pixelSize: root.uiFontSize
                                                }
                                                Row {
                                                    visible: root.config.workspaceShowWindowIcons
                                                    spacing: 1
                                                    Repeater {
                                                        model: root._workspaceClientIcons(wsChip.wsId)
                                                        delegate: Image {
                                                            required property string modelData
                                                            source: root._iconSource(modelData)
                                                            width: 12
                                                            height: 12
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
                                                id: wsMouse
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
                    Component.onCompleted: Qt.callLater(refreshActiveItem)
                    onImplicitWidthChanged: Qt.callLater(refreshActiveItem)
                    onImplicitHeightChanged: Qt.callLater(refreshActiveItem)
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
                border.color: "transparent"
                radius: root.config.barRounding



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
            spacing: root.statusRowVisualSpacing
            Item {
                visible: root.capsLockOn && root._barOverlayEnabled("locks", true)
                Layout.fillHeight: true
                implicitWidth: capsChip.implicitWidth
                Rectangle {
                    id: capsChip
                    z: 0
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "transparent"
                    border.width: root.config.buttonBorderWidth
                    border.color: root.config.accentColor
                    radius: root.config.rounding
                    implicitWidth: 48
                    implicitHeight: 22
                    Label {
                        anchors.centerIn: parent
                        text: root.config.formatUiText("Caps")
                        color: root.config.accentColor
                        font.bold: true
                        font.family: root.uiFontFamily
                        font.pixelSize: root.uiFontSize
                    }
                }
                MouseArea {
                    z: 1
                    x: -root.statusRowHitBleed
                    width: parent.width + root.statusRowVisualSpacing
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    hoverEnabled: true
                    onEntered: root.openStatusMenu("locks", root._itemLeftX(capsChip))
                    onExited: root.queueStatusMenuClose("locks")
                    onClicked: root.openStatusMenu("locks", root._itemLeftX(capsChip))
                }
            }
            Item {
                visible: root.numLockOn && root._barOverlayEnabled("locks", true)
                Layout.fillHeight: true
                implicitWidth: numChip.implicitWidth
                Rectangle {
                    id: numChip
                    z: 0
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "transparent"
                    border.width: root.config.buttonBorderWidth
                    border.color: root.config.accentColor
                    radius: root.config.rounding
                    implicitWidth: 40
                    implicitHeight: 22
                    Label {
                        anchors.centerIn: parent
                        text: root.config.formatUiText("Num")
                        color: root.config.accentColor
                        font.bold: true
                        font.family: root.uiFontFamily
                        font.pixelSize: root.uiFontSize
                    }
                }
                MouseArea {
                    z: 1
                    x: -root.statusRowHitBleed
                    width: parent.width + root.statusRowVisualSpacing
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    hoverEnabled: true
                    onEntered: root.openStatusMenu("locks", root._itemLeftX(numChip))
                    onExited: root.queueStatusMenuClose("locks")
                    onClicked: root.openStatusMenu("locks", root._itemLeftX(numChip))
                }
            }
            Label {
                visible: root._barOverlayEnabled("clock", true)
                text: root.dateTimeText
                color: root.config.overlayDateColor
                font.family: root.uiFontFamily
                font.pixelSize: root.uiFontSize
                Layout.alignment: Qt.AlignVCenter
            }
            Item {
                visible: root._barOverlayEnabled("clock", true)
                Layout.preferredWidth: 6
                Layout.minimumWidth: 6
                Layout.fillWidth: false
            }
            Item {
                visible: root._barOverlayEnabled("wifi", true)
                Layout.fillHeight: true
                implicitWidth: wifiChip.implicitWidth
                Rectangle {
                    id: wifiChip
                    z: 0
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "transparent"
                    border.width: root.config.buttonBorderWidth
                    border.color: root.config.barAccentColor
                    radius: root.config.rounding
                    implicitWidth: wifiLabel.implicitWidth + 10
                    implicitHeight: 22
                    Label { id: wifiLabel; anchors.centerIn: parent; text: root.wifiText; color: root.config.barTextColor }
                }
                MouseArea {
                    z: 1
                    x: -root.statusRowHitBleed
                    width: parent.width + root.statusRowVisualSpacing
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    hoverEnabled: true
                    onEntered: root.openStatusMenu("wifi", root._itemLeftX(wifiChip))
                    onExited: root.queueStatusMenuClose("wifi")
                    onClicked: root.openStatusMenu("wifi", root._itemLeftX(wifiChip))
                }
            }
            Item {
                visible: root._barOverlayEnabled("bluetooth", true)
                Layout.fillHeight: true
                implicitWidth: btChip.implicitWidth
                Rectangle {
                    id: btChip
                    z: 0
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "transparent"
                    border.width: root.config.buttonBorderWidth
                    border.color: root.config.barAccentColor
                    radius: root.config.barRounding
                    implicitWidth: btLabel.implicitWidth + 10
                    implicitHeight: 22
                    Label { id: btLabel; anchors.centerIn: parent; text: root.btText; color: root.config.barTextColor }
                }
                MouseArea {
                    z: 1
                    x: -root.statusRowHitBleed
                    width: parent.width + root.statusRowVisualSpacing
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    hoverEnabled: true
                    onEntered: root.openStatusMenu("bt", root._itemLeftX(btChip))
                    onExited: root.queueStatusMenuClose("bt")
                    onClicked: root.openStatusMenu("bt", root._itemLeftX(btChip))
                }
            }
            Item {
                visible: root._barOverlayEnabled("audio", true)
                Layout.fillHeight: true
                implicitWidth: audioChip.implicitWidth
                Rectangle {
                    id: audioChip
                    z: 0
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "transparent"
                    border.width: root.config.buttonBorderWidth
                    border.color: root.config.barAccentColor
                    radius: root.config.barRounding
                    implicitWidth: audioLabel.implicitWidth + 10
                    implicitHeight: 22
                    Label { id: audioLabel; anchors.centerIn: parent; text: root.audioText; color: root.config.barTextColor; textFormat: Text.RichText }
                }
                MouseArea {
                    z: 1
                    x: -root.statusRowHitBleed
                    width: parent.width + root.statusRowVisualSpacing
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    hoverEnabled: true
                    onEntered: root.openStatusMenu("audio", root._itemLeftX(audioChip))
                    onExited: root.queueStatusMenuClose("audio")
                    onClicked: root.openStatusMenu("audio", root._itemLeftX(audioChip))
                }
            }
            Item {
                visible: root._barOverlayEnabled("brightness", true)
                Layout.fillHeight: true
                implicitWidth: briChip.implicitWidth
                Rectangle {
                    id: briChip
                    z: 0
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "transparent"
                    border.width: root.config.buttonBorderWidth
                    border.color: root.config.barAccentColor
                    radius: root.config.barRounding
                    implicitWidth: briLabel.implicitWidth + 10
                    implicitHeight: 22
                    Label { id: briLabel; anchors.centerIn: parent; text: root.brightnessText; color: root.config.barTextColor; textFormat: Text.RichText }
                }
                MouseArea {
                    z: 1
                    x: -root.statusRowHitBleed
                    width: parent.width + root.statusRowVisualSpacing
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    hoverEnabled: true
                    onEntered: root.openStatusMenu("brightness", root._itemLeftX(briChip))
                    onExited: root.queueStatusMenuClose("brightness")
                    onClicked: root.openStatusMenu("brightness", root._itemLeftX(briChip))
                }
            }
            Item {
                visible: root._barOverlayEnabled("battery", true)
                Layout.fillHeight: true
                implicitWidth: batChip.implicitWidth
                Rectangle {
                    id: batChip
                    z: 0
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "transparent"
                    border.width: root.config.buttonBorderWidth
                    border.color: root.config.barAccentColor
                    radius: root.config.barRounding
                    implicitWidth: batRow.implicitWidth + 14
                    implicitHeight: Math.max(22, batRow.implicitHeight + 6)
                    RowLayout {
                        id: batRow
                        anchors.centerIn: parent
                        spacing: 5

                        Label {
                            text: "BAT"
                            color: root.config.barTextColor
                            font.family: root.uiFontFamily
                            font.pixelSize: root.uiFontSize + 1
                            Layout.alignment: Qt.AlignVCenter
                        }

                        BatterySegmentIndicator {
                            horizontal: true
                            percent: root.batteryPercent
                            textColor: root.config.barTextColor
                            accentColor: root.config.barAccentColor
                            segment0Color: root.batteryCharging ? root.config.overlayBatteryBarColorCharging : root.config.overlayBatteryBarColorCritical
                            segment1Color: root.batteryCharging ? root.config.overlayBatteryBarColorCharging : root.config.overlayBatteryBarColorLow
                            segment2Color: root.batteryCharging ? root.config.overlayBatteryBarColorCharging : root.config.overlayBatteryBarColorMedium
                            segment3Color: root.batteryCharging ? root.config.overlayBatteryBarColorCharging : root.config.overlayBatteryBarColorFull
                            barRadius: Math.max(0, Math.min(root.config.rounding, 8))
                            segmentWidth: 7
                            segmentHeight: 14
                            segmentSpacing: 2
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                }
                MouseArea {
                    z: 1
                    x: -root.statusRowHitBleed
                    width: parent.width + root.statusRowVisualSpacing
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    hoverEnabled: true
                    onEntered: root.openStatusMenu("battery", root._itemLeftX(batChip))
                    onExited: root.queueStatusMenuClose("battery")
                    onClicked: root.openStatusMenu("battery", root._itemLeftX(batChip))
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
            top: 0
            left: Math.max(
                0,
                Math.min(
                    Math.max(0, root.width - workspacePreviewWindow.implicitWidth),
                    root.workspacePreviewAnchorCenterX - (workspacePreviewWindow.implicitWidth / 2)
                )
            )
        }
        implicitWidth: workspacePreviewPanel.implicitWidth
        implicitHeight: workspacePreviewPanel.implicitHeight
        exclusiveZone: 0
        color: "transparent"

        WorkspacePreviewSurface {
            id: workspacePreviewPanel
            readonly property real hiddenY: -(workspacePreviewWindow.implicitHeight + 8)
            width: parent.width
            height: parent.height
            visible: workspacePreviewWindow.mounted
            y: workspacePreviewWindow.presented ? 0 : hiddenY
            host: root
            workspaceId: root.workspacePreviewDisplayId
            items: root.workspacePreviewItems
            previewMonitor: root._workspacePreviewMonitor(root.workspacePreviewDisplayId)

            Behavior on y {
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
        id: statusMenuWindow
        screen: root.screen
        property bool shown: root.activeStatusMenu.length > 0
        property bool mounted: shown
        property bool presented: shown
        /** Pixels to translate off-screen; frozen per open/close so height changes do not shorten the slide. */
        property real slideTravelPx: 200
        readonly property int statusSlideDurationMs: root.config.overlaySlideDurationMs
        visible: statusMenuWindow.mounted
        onShownChanged: {
            if (shown) {
                mounted = true;
                statusMenuHideTimer.stop();
                slideTravelPx = Math.max(120, statusMenuContent.implicitHeight + 24);
                presented = false;
                Qt.callLater(function () {
                    if (!statusMenuWindow.shown)
                        return;
                    slideTravelPx = Math.max(120, statusMenuContent.implicitHeight + 24);
                    statusMenuPresentTimer.restart();
                });
            } else if (mounted) {
                slideTravelPx = Math.max(120, statusMenuContent.implicitHeight + 24);
                presented = false;
                statusMenuHideTimer.restart();
            }
        }
        focusable: root.statusMenuPanelId === "wifi"
        WlrLayershell.keyboardFocus: root.statusMenuPanelId === "wifi" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        anchors {
            top: true
            left: true
        }
        margins {
            top: 0
            left: root.statusMenuLeftX
        }
        implicitWidth: Math.max(132, root.statusMenuWidth)
        implicitHeight: statusMenuContent.implicitHeight + 16
        exclusiveZone: 0
        color: "transparent"

        Rectangle {
            id: statusPanel
            anchors.top: parent.top
            anchors.left: parent.left
            width: parent.width
            height: parent.height
            radius: root.config.overlayRounding
            color: root.config.borderColor
            transform: Translate {
                y: statusMenuWindow.presented ? 0 : -statusMenuWindow.slideTravelPx
                Behavior on y {
                    id: statusSlideAnim
                    enabled: root.config.uiAnimationsEnabled
                    NumberAnimation {
                        duration: statusMenuWindow.statusSlideDurationMs
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
                id: statusMenuContent
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Label {
                    text: root.statusMenuPanelId === "wifi" ? root.networkDisplayText
                        : root.statusMenuPanelId === "bt" ? "BLUETOOTH"
                        : root.statusMenuPanelId === "locks" ? root.config.formatUiText("Locks")
                        : root.statusMenuPanelId === "battery" ? "BATTERY"
                        : root.statusMenuPanelId === "audio" ? "AUDIO"
                        : root.statusMenuPanelId === "brightness" ? "BRIGHTNESS"
                        : ""
                    color: root.config.overlayAccentColor
                    font.bold: true
                }

                Status.WifiMenuContent {
                    visible: root.statusMenuPanelId === "wifi"
                    host: root
                    listHeight: 260
                }

                Status.BluetoothMenuContent {
                    visible: root.statusMenuPanelId === "bt"
                    host: root
                    toggleWidth: 38
                    toggleHeight: 20
                    knobSize: 14
                    listHeight: 170
                }

                Status.LocksMenuContent {
                    visible: root.statusMenuPanelId === "locks"
                    host: root
                }

                Status.AudioMenuContent {
                    visible: root.statusMenuPanelId === "audio"
                    host: root
                    outputListHeight: 110
                    inputListHeight: 96
                    menuFontBoost: 8
                    showMixer: true
                }

                Status.BrightnessMenuContent {
                    visible: root.statusMenuPanelId === "brightness"
                    host: root
                    menuFontBoost: 8
                }

                Status.BatteryMenuContent {
                    visible: root.statusMenuPanelId === "battery"
                    host: root
                }
            }
        }

        HoverHandler {
            enabled: statusMenuWindow.mounted
            onHoveredChanged: {
                if (hovered)
                    statusPopupCloseTimer.stop();
                else
                    statusPopupCloseTimer.restart();
            }
        }

        Timer {
            id: statusMenuPresentTimer
            interval: 0
            repeat: false
            onTriggered: {
                if (statusMenuWindow.shown)
                    statusMenuWindow.presented = true;
            }
        }

        Timer {
            id: statusMenuHideTimer
            interval: root.config.uiAnimationsEnabled ? root.config.overlaySlideDurationMs + 100 : 1
            repeat: false
            onTriggered: {
                if (!statusMenuWindow.shown) {
                    root.statusMenuPanelId = "";
                    statusMenuWindow.presented = false;
                    statusMenuWindow.mounted = false;
                }
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
            root.wifiConnectError = sensors.humanizeWifiConnectError(raw);
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
        id: statusPopupCloseTimer
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
        id: audioRefreshTimer
        interval: 140
        repeat: false
        onTriggered: {
            sensors.refreshAudioData();
        }
    }

    Timer {
        id: brightnessRefreshTimer
        interval: 140
        repeat: false
        onTriggered: sensors.refreshBrightnessData()
    }

    Connections {
        target: sensors
        function onActiveStatusMenuChanged() {
            if (root.activeStatusMenu !== "wifi") {
                root.statusMenuInputFocused = false;
                root.dismissWifiPasswordEntry();
            }
            root._applyFontRecursive(statusMenuWindow);
        }
        function onFocusedWorkspaceIdChanged() {
            Qt.callLater(workspaceLayer.refreshActiveItem);
        }
    }
}
