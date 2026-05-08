import QtQuick
import QtCore
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland

import "modules/bar" as Bar
import "modules/controlcenter" as ControlCenter
import "modules/dashboard" as Dashboard
import "modules/sidebar" as Sidebar

ShellRoot {
    id: root

    property bool controlCenterVisible: false
    property bool dashboardVisible: false
    property bool themeSelectorVisible: false
    property bool wallpaperPickerVisible: false
    property bool quickSettingsTriggerHovered: false
    property bool quickSettingsOverlayHovered: false
    property bool dashboardTriggerHovered: false
    property bool dashboardOverlayHovered: false
    property bool rightSidebarVisible: false
    property bool rightSidebarTriggerHovered: false
    property bool rightSidebarOverlayHovered: false
    property bool settingsSaveToastPending: false
    /// Output the dashboard overlay and top-edge hover are tied to (keyboard toggle falls back to the first screen).
    property var dashboardAnchorScreen: null
    /// Output quick settings panels anchor to (corner trigger sets this).
    property var quickSettingsAnchorScreen: null
    /// Name of the output the right sidebar is shown on (edge hover or hotkey with empty anchor picks primary).
    property string rightSidebarAnchorName: ""
    readonly property bool quickSettingsOpen: quickSettingsTriggerHovered || quickSettingsOverlayHovered
    property string detectedWindowManagerKey: "unknown"
    property string detectedWindowManagerName: "Window Manager"

    function _windowManagerNameForKey(key) {
        const normalized = String(key || "").trim().toLowerCase();
        if (!normalized || normalized === "unknown")
            return "Window Manager";
        if (normalized === "hyprland")
            return "Hyprland";
        if (normalized === "sway")
            return "Sway";
        if (normalized === "i3")
            return "i3";
        return normalized.split(/[-_ ]+/).map(part => part.length > 0
            ? part.charAt(0).toUpperCase() + part.slice(1)
            : "").join(" ");
    }

    function _setDetectedWindowManager(value) {
        const normalized = String(value || "").trim().toLowerCase() || "unknown";
        detectedWindowManagerKey = normalized;
        detectedWindowManagerName = _windowManagerNameForKey(normalized);
    }

    function closeDashboardOverlays() {
        dashboardVisible = false;
        dashboardTriggerHovered = false;
        dashboardOverlayHovered = false;
        dashboardAnchorScreen = null;
    }

    function dismissQuickSettings() {
        quickSettingsTriggerRelease.stop();
        quickSettingsOverlayRelease.stop();
        quickSettingsTriggerHovered = false;
        quickSettingsOverlayHovered = false;
        quickSettingsAnchorScreen = null;
    }

    function holdQuickSettingsTrigger() {
        quickSettingsTriggerRelease.stop();
        quickSettingsTriggerHovered = true;
    }

    function holdQuickSettingsOverlay() {
        quickSettingsTriggerRelease.stop();
        quickSettingsOverlayRelease.stop();
        quickSettingsOverlayHovered = true;
    }

    function cancelQuickSettingsTriggerClose() {
        quickSettingsTriggerRelease.stop();
    }

    function scheduleQuickSettingsTriggerClose() {
        quickSettingsTriggerRelease.restart();
    }

    function cancelQuickSettingsOverlayClose() {
        quickSettingsOverlayRelease.stop();
    }

    function scheduleQuickSettingsOverlayClose() {
        quickSettingsOverlayRelease.restart();
    }

    function toggleControlCenter() {
        if (!controlCenterVisible) {
            closeDashboardOverlays();
            themeSelectorVisible = false;
            dismissQuickSettings();
        }
        controlCenterVisible = !controlCenterVisible;
    }

    function openControlCenter() {
        closeDashboardOverlays();
        themeSelectorVisible = false;
        dismissQuickSettings();
        controlCenterVisible = true;
    }

    function openThemeSelector() {
        closeDashboardOverlays();
        controlCenterVisible = false;
        dismissQuickSettings();
        themeSelectorVisible = true;
    }

    function openWallpaperPicker() {
        closeDashboardOverlays();
        controlCenterVisible = false;
        dismissQuickSettings();
        wallpaperPickerVisible = true;
    }

    function setWallpaper(path) {
        const p = String(path || "").trim();
        if (!p.length)
            return;
        store.wallpaperPath = p;
        root.applyWallpaper(p);
        root.queueStoreSave();
    }

    function clearNotificationHistory() {
        notificationHistory = [];
    }

    function dismissNotification(index) {
        const h = root.notificationHistory.slice();
        if (index >= 0 && index < h.length)
            h.splice(index, 1);
        root.notificationHistory = h;
    }

    function pushSystemNotification(summary, body, urgency, appName) {
        const entry = {
            appName: String(appName || "Quick Settings"),
            summary: String(summary || ""),
            body: String(body || ""),
            urgency: Number(urgency === undefined ? 1 : urgency),
            appIcon: ""
        };
        root.notificationHistory = [entry].concat(root.notificationHistory.slice(0, 49));
    }

    function setQuickSettingsTileVisible(tileId, visible) {
        const tiles = config.quickSettingsTiles || [];
        const updated = tiles.map(function(t) {
            return String(t.id) === String(tileId) ? Object.assign({}, t, { visible: visible }) : t;
        });
        config.quickSettingsTiles = root._deepCopy(updated);
    }

    function setBarOverlayVisible(overlayId, visible) {
        const next = Object.assign({}, config.barOverlayVisibility || root.defaultBarOverlayVisibility());
        next[String(overlayId)] = !!visible;
        config.barOverlayVisibility = root._deepCopy(next);
    }

    function setDashboardTabVisible(tabId, visible) {
        const next = Object.assign({}, config.dashboardTabVisibility || root.defaultDashboardTabVisibility());
        next[String(tabId)] = !!visible;
        config.dashboardTabVisibility = root._deepCopy(next);
    }

    function toggleDashboard() {
        const next = !dashboardVisible;
        if (!next)
            dashboardAnchorScreen = null;
        else if (Quickshell.screens.length > 0 && dashboardAnchorScreen == null)
            dashboardAnchorScreen = Quickshell.screens[0];
        dashboardVisible = next;
    }

    function toggleRightSidebar() {
        const next = !rightSidebarVisible;
        if (next && Quickshell.screens.length > 0 && rightSidebarAnchorName.length === 0)
            rightSidebarAnchorName = Quickshell.screens[0].name;
        rightSidebarVisible = next;
    }

    function stopDashboardHoverTimer() {
        dashboardHoverRelease.stop();
    }

    function startDashboardHoverTimer() {
        dashboardHoverRelease.restart();
    }

    onControlCenterVisibleChanged: {
        if (!controlCenterVisible && root.settingsSaveToastPending)
            settingsSavedToastTimer.restart();
    }

    Component.onCompleted: {
        windowManagerDetectProc.exec({ command: windowManagerDetectProc.command });
    }

    Timer {
        id: dashboardHoverRelease
        interval: config.hoverReleaseMs
        repeat: false
        onTriggered: {
            root.dashboardTriggerHovered = false;
            if (!root.dashboardVisible && !root.dashboardOverlayHovered)
                root.dashboardAnchorScreen = null;
        }
    }

    Timer {
        id: quickSettingsTriggerRelease
        interval: config.hoverReleaseMs
        repeat: false
        onTriggered: root.quickSettingsTriggerHovered = false
    }

    Timer {
        id: quickSettingsOverlayRelease
        interval: config.hoverReleaseMs
        repeat: false
        onTriggered: root.quickSettingsOverlayHovered = false
    }

    Process {
        id: windowManagerDetectProc
        command: ["bash", "-lc", "if [ -n \"${HYPRLAND_INSTANCE_SIGNATURE:-}\" ]; then echo hyprland; elif [ -n \"${SWAYSOCK:-}\" ]; then echo sway; elif [ -n \"${I3SOCK:-}\" ]; then echo i3; elif [ -n \"${XDG_CURRENT_DESKTOP:-}\" ]; then printf '%s' \"$XDG_CURRENT_DESKTOP\" | tr '[:upper:]' '[:lower:]' | cut -d: -f1; elif [ -n \"${DESKTOP_SESSION:-}\" ]; then printf '%s' \"$DESKTOP_SESSION\" | tr '[:upper:]' '[:lower:]'; else echo unknown; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root._setDetectedWindowManager(String(text))
        }
    }

    function _deepCopy(value) {
        return JSON.parse(JSON.stringify(value));
    }

    function defaultThemeLibrary() {
        return [];
    }

    function defaultQuickSettingsTiles() {
        return [
            { id: "wifi",      visible: true },
            { id: "bluetooth", visible: true },
            { id: "dnd",       visible: true },
            { id: "wallpaper", visible: true },
            { id: "themes",    visible: true },
            { id: "settings",  visible: true }
        ];
    }

    function defaultBarOverlayVisibility() {
        return {
            clock: true,
            locks: true,
            wifi: true,
            bluetooth: true,
            audio: true,
            battery: true
        };
    }

    function defaultDashboardTabVisibility() {
        return {
            overview: true,
            performance: true,
            focus: true,
            media: true,
            calendar: true,
            updates: true
        };
    }

    function applyBundledThemeLibrary(rawText) {
        let parsedThemes = [];
        try {
            parsedThemes = JSON.parse(String(rawText || "[]"));
        } catch (e) {
            console.warn("theme preset parse failed:", e);
            return;
        }
        if (!Array.isArray(parsedThemes) || parsedThemes.length < 1) {
            console.warn("no theme presets found");
            return;
        }

        const nextLibrary = parsedThemes.map((theme, index) => root.normalizeTheme(theme, "theme-" + index));
        store.themeLibrary = nextLibrary;
        config.themeLibrary = root._deepCopy(nextLibrary);

        const requestedId = String(store.activeThemeId || "").trim();
        if (requestedId.length > 0 && root.setActiveThemeById(requestedId))
            return;

        const fallbackId = String(nextLibrary[0].id || "");
        if (!fallbackId.length)
            return;
        store.activeThemeId = fallbackId;
        root.setActiveThemeById(fallbackId);
    }

    function defaultHyprlandDecoration() {
        return {
            gapsIn: 5,
            gapsOut: 10,
            borderSize: 2,
            rounding: 8,
            blurEnabled: true,
            blurSize: 8,
            blurPasses: 1,
            activeBorderColor: "#ff8c32",
            inactiveBorderColor: "#444444"
        };
    }

    function defaultHyprlandMonitors() {
        return [{
            name: "",
            mode: "preferred",
            positionX: 0,
            positionY: 0,
            scale: 1,
            transform: 0,
            mirrorOf: "",
            enabled: true
        }];
    }

    function defaultHyprlandBinds() {
        return [{
            mods: "SUPER",
            key: "Return",
            dispatcher: "exec",
            argument: "foot"
        }];
    }

    function defaultHyprlandWorkspaceRules() {
        return [{
            workspace: "1",
            monitor: "",
            defaultName: "",
            persistent: true,
            isDefault: true
        }];
    }

    function _themeNum(source, key, fallback) {
        const v = Number(source[key]);
        return Number.isFinite(v) ? v : fallback;
    }

    function _themeText(source, key, fallback) {
        const value = source && source[key] !== undefined ? String(source[key]) : "";
        const trimmed = value.trim();
        return trimmed.length > 0 ? trimmed : fallback;
    }

    function _themeOptionalText(source, key) {
        if (!source || source[key] === undefined || source[key] === null)
            return "";
        return String(source[key]).trim();
    }

    function _normalizeComponentTheme(source) {
        const component = source || {};
        return {
            backgroundColor: _themeOptionalText(component, "backgroundColor"),
            accentColor: _themeOptionalText(component, "accentColor"),
            textColor: _themeOptionalText(component, "textColor"),
            rounding: component.rounding !== undefined ? _themeNum(component, "rounding", -1) : -1,
            activeTextColor: _themeOptionalText(component, "activeTextColor"),
            activeGroupBackgroundColor: _themeOptionalText(component, "activeGroupBackgroundColor"),
            activeGroupBorderColor: _themeOptionalText(component, "activeGroupBorderColor"),
            highlightColor: _themeOptionalText(component, "highlightColor"),
            visualizationBorderColor: _themeOptionalText(component, "visualizationBorderColor"),
            visualizationBackgroundColor: _themeOptionalText(component, "visualizationBackgroundColor"),
            weatherAccentColor: _themeOptionalText(component, "weatherAccentColor"),
            weatherTextColor: _themeOptionalText(component, "weatherTextColor"),
            weatherIconColor: _themeOptionalText(component, "weatherIconColor"),
            weatherIconBackgroundColor: _themeOptionalText(component, "weatherIconBackgroundColor"),
            systemAccentColor: _themeOptionalText(component, "systemAccentColor"),
            clockHourColor: _themeOptionalText(component, "clockHourColor"),
            clockMinuteColor: _themeOptionalText(component, "clockMinuteColor"),
            clockSecondColor: _themeOptionalText(component, "clockSecondColor"),
            clockSecondsTimerColor: _themeOptionalText(component, "clockSecondsTimerColor"),
            calendarWeekendColor: _themeOptionalText(component, "calendarWeekendColor"),
            calendarActiveColor: _themeOptionalText(component, "calendarActiveColor"),
            calendarCurrentDayColor: _themeOptionalText(component, "calendarCurrentDayColor"),
            usageBarBackgroundColor: _themeOptionalText(component, "usageBarBackgroundColor"),
            wifiDownColor: _themeOptionalText(component, "wifiDownColor"),
            wifiUpColor: _themeOptionalText(component, "wifiUpColor"),
            batteryPerformanceColor: _themeOptionalText(component, "batteryPerformanceColor"),
            ramUsageColor: _themeOptionalText(component, "ramUsageColor"),
            diskUsageColor: _themeOptionalText(component, "diskUsageColor"),
            cpuColor: _themeOptionalText(component, "cpuColor"),
            gpuColor: _themeOptionalText(component, "gpuColor"),
            cpuBarColor: _themeOptionalText(component, "cpuBarColor"),
            ramBarColor: _themeOptionalText(component, "ramBarColor"),
            diskBarColor: _themeOptionalText(component, "diskBarColor"),
            mediaControlsColor: _themeOptionalText(component, "mediaControlsColor"),
            mediaDurationBarColor: _themeOptionalText(component, "mediaDurationBarColor"),
            performanceCpuBackgroundFillColor: _themeOptionalText(component, "performanceCpuBackgroundFillColor"),
            performanceCpuTempBarColor: _themeOptionalText(component, "performanceCpuTempBarColor"),
            performanceGpuBackgroundFillColor: _themeOptionalText(component, "performanceGpuBackgroundFillColor"),
            performanceGpuTempBarColor: _themeOptionalText(component, "performanceGpuTempBarColor"),
            performanceMemoryBarFillColor: _themeOptionalText(component, "performanceMemoryBarFillColor"),
            performanceDiskBarFillColor: _themeOptionalText(component, "performanceDiskBarFillColor"),
            performanceBatteryFillColor: _themeOptionalText(component, "performanceBatteryFillColor"),
            updatesPackageBarFillColor: _themeOptionalText(component, "updatesPackageBarFillColor"),
            updatesSecurityBarFillColor: _themeOptionalText(component, "updatesSecurityBarFillColor"),
            updatesAURBarFillColor: _themeOptionalText(component, "updatesAURBarFillColor"),
            updatesKernelBarFillColor: _themeOptionalText(component, "updatesKernelBarFillColor"),
            updatesSystemRadialFillColor: _themeOptionalText(component, "updatesSystemRadialFillColor"),
            updatesPackageRadialFillColor: _themeOptionalText(component, "updatesPackageRadialFillColor"),
            updatesSecurityRadialFillColor: _themeOptionalText(component, "updatesSecurityRadialFillColor"),
            updatesAURRadialFillColor: _themeOptionalText(component, "updatesAURRadialFillColor"),
            updatesKernelRadialFillColor: _themeOptionalText(component, "updatesKernelRadialFillColor"),
            dateColor: _themeOptionalText(component, "dateColor"),
            dateFormat: _themeOptionalText(component, "dateFormat"),
            timeFormat: _themeOptionalText(component, "timeFormat"),
            dateTimeFormat: _themeOptionalText(component, "dateTimeFormat"),
            buttonTextColor: _themeOptionalText(component, "buttonTextColor"),
            buttonBorderColor: _themeOptionalText(component, "buttonBorderColor"),
            buttonBackgroundColor: _themeOptionalText(component, "buttonBackgroundColor"),
            buttonActiveTextColor: _themeOptionalText(component, "buttonActiveTextColor"),
            buttonActiveBorderColor: _themeOptionalText(component, "buttonActiveBorderColor"),
            buttonActiveBackgroundColor: _themeOptionalText(component, "buttonActiveBackgroundColor"),
            batteryBarColorCritical: _themeOptionalText(component, "batteryBarColorCritical"),
            batteryBarColorLow: _themeOptionalText(component, "batteryBarColorLow"),
            batteryBarColorMedium: _themeOptionalText(component, "batteryBarColorMedium"),
            batteryBarColorHigh: _themeOptionalText(component, "batteryBarColorHigh"),
            batteryBarColorFull: _themeOptionalText(component, "batteryBarColorFull"),
            notificationTextColor: _themeOptionalText(component, "notificationTextColor"),
            notificationBorderColor: _themeOptionalText(component, "notificationBorderColor"),
            notificationBackgroundColor: _themeOptionalText(component, "notificationBackgroundColor"),
            notificationPadding: component.notificationPadding !== undefined ? _themeNum(component, "notificationPadding", -1) : -1,
            activeSettingTextColor: _themeOptionalText(component, "activeSettingTextColor"),
            activeSettingBorderColor: _themeOptionalText(component, "activeSettingBorderColor"),
            activeSettingBackgroundColor: _themeOptionalText(component, "activeSettingBackgroundColor"),
            settingTextColor: _themeOptionalText(component, "settingTextColor"),
            settingBorderColor: _themeOptionalText(component, "settingBorderColor"),
            settingBackgroundColor: _themeOptionalText(component, "settingBackgroundColor"),
            buttonHoverEffectColor: _themeOptionalText(component, "buttonHoverEffectColor"),
            buttonActiveColor: _themeOptionalText(component, "buttonActiveColor"),
            buttonInactiveColor: _themeOptionalText(component, "buttonInactiveColor")
        };
    }

    function _componentColor(components, name, key, fallback) {
        const component = components && components[name] ? components[name] : {};
        const value = _themeOptionalText(component, key);
        return value.length > 0 ? value : fallback;
    }

    function _componentRounding(components, name, fallback) {
        const component = components && components[name] ? components[name] : {};
        return component.rounding !== undefined && Number(component.rounding) >= 0
            ? Math.round(Number(component.rounding))
            : Math.round(fallback);
    }

    function normalizeTheme(theme, fallbackId) {
        const source = theme || {};
        const generalSource = source.general || {};
        const general = {
            accentColor: _themeText(generalSource, "accentColor", _themeText(source, "accentColor", "#ff8c32")),
            borderColor: _themeText(generalSource, "borderColor", _themeText(source, "borderColor", _themeText(source, "accentColor", "#ff8c32"))),
            backgroundColor: _themeText(generalSource, "backgroundColor", _themeText(source, "backgroundColor", "#0f0f12")),
            textColor: _themeText(generalSource, "textColor", _themeText(source, "textColor", "#e5e7eb")),
            panelColor: _themeOptionalText(generalSource, "panelColor") || _themeOptionalText(source, "panelColor"),
            mutedTextColor: _themeOptionalText(generalSource, "mutedTextColor") || _themeOptionalText(source, "mutedTextColor"),
            rounding: _themeNum(generalSource, "rounding", _themeNum(source, "rounding", 8)),
            borderWidth: _themeNum(generalSource, "borderWidth", _themeNum(source, "borderWidth", 1)),
            buttonBorderWidth: _themeNum(generalSource, "buttonBorderWidth", _themeNum(source, "buttonBorderWidth", 1)),
            overlayBorderWidth: _themeNum(generalSource, "overlayBorderWidth", _themeNum(source, "overlayBorderWidth", 1)),
            panelOpacity: _themeNum(generalSource, "panelOpacity", _themeNum(source, "panelOpacity", 0.96)),
            overlayDimOpacity: _themeNum(generalSource, "overlayDimOpacity", _themeNum(source, "overlayDimOpacity", 0.4))
        };
        const sourceComponents = source.components || {};
        const components = {
            bar: _normalizeComponentTheme(sourceComponents.bar || source.bar || {}),
            workspace: _normalizeComponentTheme(sourceComponents.workspace || source.workspace || {
                accentColor: source.workspaceAccentColor,
                textColor: source.workspaceColor
            }),
            dashboard: _normalizeComponentTheme(sourceComponents.dashboard || source.dashboard || {
                accentColor: source.dashboardColor
            }),
            sidebar: _normalizeComponentTheme(sourceComponents.sidebar || source.sidebar || {
                accentColor: source.quickSidebarColor
            }),
            overlay: _normalizeComponentTheme(sourceComponents.overlay || source.overlay || {
                accentColor: source.overlayAccentColor
            }),
            visualization: _normalizeComponentTheme(sourceComponents.visualization || source.visualization || {
                accentColor: source.volumeColor
            }),
            settings: _normalizeComponentTheme(sourceComponents.settings || source.settings || {})
        };
        return {
            id: String(source.id || fallbackId || ("theme-" + Date.now())),
            name: String(source.name || "Custom Theme"),
            themeMode: String(source.themeMode || "dark"),
            general: general,
            components: components,
            accentColor: general.accentColor,
            borderColor: general.borderColor,
            backgroundColor: general.backgroundColor,
            textColor: general.textColor,
            panelColor: general.panelColor,
            mutedTextColor: general.mutedTextColor,
            barAccentColor: _componentColor(components, "bar", "accentColor", general.accentColor),
            barBackgroundColor: _componentColor(components, "bar", "backgroundColor", general.panelColor || general.backgroundColor),
            barTextColor: _componentColor(components, "bar", "textColor", general.textColor),
            barRounding: _componentRounding(components, "bar", general.rounding),
            workspaceAccentColor: _componentColor(components, "workspace", "accentColor", general.accentColor),
            workspaceBackgroundColor: _componentColor(components, "workspace", "backgroundColor", general.panelColor || general.backgroundColor),
            workspaceColor: _componentColor(components, "workspace", "textColor", general.textColor),
            workspaceActiveTextColor: _componentColor(components, "workspace", "activeTextColor", _componentColor(components, "workspace", "textColor", general.textColor)),
            workspaceActiveGroupBackgroundColor: _componentColor(components, "workspace", "activeGroupBackgroundColor", _componentColor(components, "workspace", "accentColor", general.accentColor)),
            workspaceActiveGroupBorderColor: _componentColor(components, "workspace", "activeGroupBorderColor", _componentColor(components, "bar", "accentColor", general.accentColor)),
            workspaceHighlightColor: _componentColor(components, "workspace", "highlightColor", _componentColor(components, "workspace", "accentColor", general.accentColor)),
            workspaceRounding: _componentRounding(components, "workspace", general.rounding),
            dashboardColor: _componentColor(components, "dashboard", "accentColor", general.accentColor),
            dashboardBackgroundColor: _componentColor(components, "dashboard", "backgroundColor", general.panelColor || general.backgroundColor),
            dashboardTextColor: _componentColor(components, "dashboard", "textColor", general.textColor),
            dashboardWeatherAccentColor: _componentColor(components, "dashboard", "weatherAccentColor", _componentColor(components, "dashboard", "accentColor", general.accentColor)),
            dashboardWeatherTextColor: _componentColor(components, "dashboard", "weatherTextColor", _componentColor(components, "dashboard", "textColor", general.textColor)),
            dashboardWeatherIconColor: _componentColor(components, "dashboard", "weatherIconColor", _componentColor(components, "dashboard", "weatherAccentColor", _componentColor(components, "dashboard", "accentColor", general.accentColor))),
            dashboardWeatherIconBackgroundColor: _componentColor(components, "dashboard", "weatherIconBackgroundColor", _componentColor(components, "dashboard", "backgroundColor", general.panelColor || general.backgroundColor)),
            dashboardSystemAccentColor: _componentColor(components, "dashboard", "systemAccentColor", _componentColor(components, "dashboard", "accentColor", general.accentColor)),
            dashboardClockHourColor: _componentColor(components, "dashboard", "clockHourColor", _componentColor(components, "dashboard", "accentColor", general.accentColor)),
            dashboardClockMinuteColor: _componentColor(components, "dashboard", "clockMinuteColor", _componentColor(components, "dashboard", "textColor", general.textColor)),
            dashboardClockSecondColor: _componentColor(components, "dashboard", "clockSecondColor", general.mutedTextColor || _componentColor(components, "dashboard", "textColor", general.textColor)),
            dashboardClockSecondsTimerColor: _componentColor(components, "dashboard", "clockSecondsTimerColor", _componentColor(components, "dashboard", "clockSecondColor", general.mutedTextColor || _componentColor(components, "dashboard", "textColor", general.textColor))),
            dashboardCalendarWeekendColor: _componentColor(components, "dashboard", "calendarWeekendColor", _componentColor(components, "dashboard", "accentColor", general.accentColor)),
            dashboardCalendarActiveColor: _componentColor(components, "dashboard", "calendarActiveColor", _componentColor(components, "dashboard", "accentColor", general.accentColor)),
            dashboardCalendarCurrentDayColor: _componentColor(components, "dashboard", "calendarCurrentDayColor", _componentColor(components, "dashboard", "calendarActiveColor", _componentColor(components, "dashboard", "accentColor", general.accentColor))),
            dashboardUsageBarBackgroundColor: _componentColor(components, "dashboard", "usageBarBackgroundColor", general.mutedTextColor || _componentColor(components, "dashboard", "textColor", general.textColor)),
            dashboardWifiDownColor: _componentColor(components, "dashboard", "wifiDownColor", _componentColor(components, "dashboard", "accentColor", general.accentColor)),
            dashboardWifiUpColor: _componentColor(components, "dashboard", "wifiUpColor", "#22c55e"),
            dashboardBatteryPerformanceColor: _componentColor(components, "dashboard", "batteryPerformanceColor", _componentColor(components, "dashboard", "accentColor", general.accentColor)),
            dashboardRamUsageColor: _componentColor(components, "dashboard", "ramUsageColor", _componentColor(components, "dashboard", "textColor", general.textColor)),
            dashboardDiskUsageColor: _componentColor(components, "dashboard", "diskUsageColor", general.mutedTextColor || _componentColor(components, "dashboard", "textColor", general.textColor)),
            dashboardCpuColor: _componentColor(components, "dashboard", "cpuColor", _componentColor(components, "dashboard", "accentColor", general.accentColor)),
            dashboardGpuColor: _componentColor(components, "dashboard", "gpuColor", _componentColor(components, "dashboard", "accentColor", general.accentColor)),
            dashboardCpuBarColor: _componentColor(components, "dashboard", "cpuBarColor", _componentColor(components, "dashboard", "cpuColor", _componentColor(components, "dashboard", "accentColor", general.accentColor))),
            dashboardRamBarColor: _componentColor(components, "dashboard", "ramBarColor", _componentColor(components, "dashboard", "ramUsageColor", _componentColor(components, "dashboard", "textColor", general.textColor))),
            dashboardDiskBarColor: _componentColor(components, "dashboard", "diskBarColor", _componentColor(components, "dashboard", "diskUsageColor", general.mutedTextColor || _componentColor(components, "dashboard", "textColor", general.textColor))),
            dashboardMediaControlsColor: _componentColor(components, "dashboard", "mediaControlsColor", _componentColor(components, "dashboard", "accentColor", general.accentColor)),
            dashboardMediaDurationBarColor: _componentColor(components, "dashboard", "mediaDurationBarColor", _componentColor(components, "dashboard", "accentColor", general.accentColor)),
            dashboardPerformanceCpuBackgroundFillColor: _componentColor(components, "dashboard", "performanceCpuBackgroundFillColor", _componentColor(components, "dashboard", "usageBarBackgroundColor", general.mutedTextColor || _componentColor(components, "dashboard", "textColor", general.textColor))),
            dashboardPerformanceCpuTempBarColor: _componentColor(components, "dashboard", "performanceCpuTempBarColor", _componentColor(components, "dashboard", "cpuColor", _componentColor(components, "dashboard", "accentColor", general.accentColor))),
            dashboardPerformanceGpuBackgroundFillColor: _componentColor(components, "dashboard", "performanceGpuBackgroundFillColor", _componentColor(components, "dashboard", "usageBarBackgroundColor", general.mutedTextColor || _componentColor(components, "dashboard", "textColor", general.textColor))),
            dashboardPerformanceGpuTempBarColor: _componentColor(components, "dashboard", "performanceGpuTempBarColor", _componentColor(components, "dashboard", "gpuColor", _componentColor(components, "dashboard", "accentColor", general.accentColor))),
            dashboardPerformanceMemoryBarFillColor: _componentColor(components, "dashboard", "performanceMemoryBarFillColor", _componentColor(components, "dashboard", "ramUsageColor", _componentColor(components, "dashboard", "textColor", general.textColor))),
            dashboardPerformanceDiskBarFillColor: _componentColor(components, "dashboard", "performanceDiskBarFillColor", _componentColor(components, "dashboard", "diskUsageColor", general.mutedTextColor || _componentColor(components, "dashboard", "textColor", general.textColor))),
            dashboardPerformanceBatteryFillColor: _componentColor(components, "dashboard", "performanceBatteryFillColor", _componentColor(components, "dashboard", "batteryPerformanceColor", _componentColor(components, "dashboard", "accentColor", general.accentColor))),
            dashboardUpdatesPackageBarFillColor: _componentColor(components, "dashboard", "updatesPackageBarFillColor", _componentColor(components, "dashboard", "cpuColor", _componentColor(components, "dashboard", "accentColor", general.accentColor))),
            dashboardUpdatesSecurityBarFillColor: _componentColor(components, "dashboard", "updatesSecurityBarFillColor", _componentColor(components, "dashboard", "wifiUpColor", "#22c55e")),
            dashboardUpdatesAURBarFillColor: _componentColor(components, "dashboard", "updatesAURBarFillColor", _componentColor(components, "dashboard", "wifiUpColor", "#22c55e")),
            dashboardUpdatesKernelBarFillColor: _componentColor(components, "dashboard", "updatesKernelBarFillColor", _componentColor(components, "dashboard", "cpuColor", _componentColor(components, "dashboard", "accentColor", general.accentColor))),
            dashboardUpdatesSystemRadialFillColor: _componentColor(components, "dashboard", "updatesSystemRadialFillColor", _componentColor(components, "dashboard", "textColor", general.textColor)),
            dashboardUpdatesPackageRadialFillColor: _componentColor(components, "dashboard", "updatesPackageRadialFillColor", _componentColor(components, "dashboard", "textColor", general.textColor)),
            dashboardUpdatesSecurityRadialFillColor: _componentColor(components, "dashboard", "updatesSecurityRadialFillColor", _componentColor(components, "dashboard", "textColor", general.textColor)),
            dashboardUpdatesAURRadialFillColor: _componentColor(components, "dashboard", "updatesAURRadialFillColor", _componentColor(components, "dashboard", "textColor", general.textColor)),
            dashboardUpdatesKernelRadialFillColor: _componentColor(components, "dashboard", "updatesKernelRadialFillColor", _componentColor(components, "dashboard", "textColor", general.textColor)),
            dashboardRounding: _componentRounding(components, "dashboard", general.rounding),
            quickSidebarColor: _componentColor(components, "sidebar", "accentColor", general.accentColor),
            sidebarBackgroundColor: _componentColor(components, "sidebar", "backgroundColor", general.panelColor || general.backgroundColor),
            sidebarTextColor: _componentColor(components, "sidebar", "textColor", general.textColor),
            sidebarRounding: _componentRounding(components, "sidebar", general.rounding),
            overlayAccentColor: _componentColor(components, "overlay", "accentColor", general.accentColor),
            overlayBackgroundColor: _componentColor(components, "overlay", "backgroundColor", general.panelColor || general.backgroundColor),
            overlayTextColor: _componentColor(components, "overlay", "textColor", general.textColor),
            overlayDateColor: _componentColor(components, "overlay", "dateColor", _componentColor(components, "overlay", "textColor", general.textColor)),
            overlayDateFormat: _componentColor(components, "overlay", "dateFormat", "%a %d %b"),
            overlayTimeFormat: _componentColor(components, "overlay", "timeFormat", "%H:%M"),
            overlayDateTimeFormat: _componentColor(components, "overlay", "dateTimeFormat", "date-time"),
            buttonTextColor: _componentColor(components, "overlay", "buttonTextColor", _componentColor(components, "overlay", "textColor", general.textColor)),
            buttonBorderColor: _componentColor(components, "overlay", "buttonBorderColor", general.mutedTextColor || _componentColor(components, "overlay", "textColor", general.textColor)),
            buttonBackgroundColor: _componentColor(components, "overlay", "buttonBackgroundColor", "transparent"),
            buttonActiveTextColor: _componentColor(components, "overlay", "buttonActiveTextColor", _componentColor(components, "overlay", "accentColor", general.accentColor)),
            buttonActiveBorderColor: _componentColor(components, "overlay", "buttonActiveBorderColor", _componentColor(components, "overlay", "accentColor", general.accentColor)),
            buttonActiveBackgroundColor: _componentColor(components, "overlay", "buttonActiveBackgroundColor", "transparent"),
            overlayBatteryBarColorCritical: _componentColor(components, "overlay", "batteryBarColorCritical", "#ef4444"),
            overlayBatteryBarColorLow: _componentColor(components, "overlay", "batteryBarColorLow", "#f59e0b"),
            overlayBatteryBarColorMedium: _componentColor(components, "overlay", "batteryBarColorMedium", _componentColor(components, "overlay", "accentColor", general.accentColor)),
            overlayBatteryBarColorHigh: _componentColor(components, "overlay", "batteryBarColorHigh", _componentColor(components, "overlay", "textColor", general.textColor)),
            overlayBatteryBarColorFull: _componentColor(components, "overlay", "batteryBarColorFull", _componentColor(components, "overlay", "accentColor", general.accentColor)),
            overlayRounding: _componentRounding(components, "overlay", general.rounding),
            volumeColor: _componentColor(components, "visualization", "accentColor", general.accentColor),
            visualizationBackgroundColor: _componentColor(components, "visualization", "backgroundColor", general.panelColor || general.backgroundColor),
            visualizationTextColor: _componentColor(components, "visualization", "textColor", general.textColor),
            visualizationBorderColor: _componentColor(components, "workspace", "visualizationBorderColor", _componentColor(components, "visualization", "accentColor", general.accentColor)),
            workspaceVisualizationBackgroundColor: _componentColor(components, "workspace", "visualizationBackgroundColor", _componentColor(components, "visualization", "backgroundColor", general.panelColor || general.backgroundColor)),
            visualizationRounding: _componentRounding(components, "visualization", general.rounding),
            settingsAccentColor: _componentColor(components, "settings", "accentColor", general.accentColor),
            settingsBackgroundColor: _componentColor(components, "settings", "backgroundColor", general.panelColor || general.backgroundColor),
            settingsTextColor: _componentColor(components, "settings", "textColor", general.textColor),
            quickSettingsNotificationTextColor: _componentColor(components, "settings", "notificationTextColor", _componentColor(components, "settings", "textColor", general.textColor)),
            quickSettingsNotificationBorderColor: _componentColor(components, "settings", "notificationBorderColor", general.mutedTextColor || _componentColor(components, "settings", "textColor", general.textColor)),
            quickSettingsNotificationBackgroundColor: _componentColor(components, "settings", "notificationBackgroundColor", "transparent"),
            quickSettingsNotificationPopupBackgroundColor: _componentColor(components, "settings", "notificationPopupBackgroundColor", _componentColor(components, "overlay", "backgroundColor", general.panelColor || general.backgroundColor)),
            quickSettingsNotificationPopupBorderColor: _componentColor(components, "settings", "notificationPopupBorderColor", _componentColor(components, "overlay", "accentColor", general.accentColor)),
            quickSettingsNotificationPopupBorderWidth: components.settings.notificationPopupBorderWidth !== undefined && Number(components.settings.notificationPopupBorderWidth) >= 0
                ? Math.round(Number(components.settings.notificationPopupBorderWidth))
                : Math.max(0, Math.round(Number(general.overlayBorderWidth || 0))),
            quickSettingsNotificationPadding: components.settings.notificationPadding !== undefined && Number(components.settings.notificationPadding) >= 0
                ? Math.round(Number(components.settings.notificationPadding))
                : 8,
            quickSettingsNotificationHeightBoost: components.settings.notificationHeightBoost !== undefined && Number(components.settings.notificationHeightBoost) >= 0
                ? Math.round(Number(components.settings.notificationHeightBoost))
                : 18,
            quickSettingsActiveSettingTextColor: _componentColor(components, "settings", "activeSettingTextColor", _componentColor(components, "settings", "accentColor", general.accentColor)),
            quickSettingsActiveSettingBorderColor: _componentColor(components, "settings", "activeSettingBorderColor", _componentColor(components, "settings", "accentColor", general.accentColor)),
            quickSettingsActiveSettingBackgroundColor: _componentColor(components, "settings", "activeSettingBackgroundColor", "transparent"),
            quickSettingsSettingTextColor: _componentColor(components, "settings", "settingTextColor", _componentColor(components, "settings", "textColor", general.textColor)),
            quickSettingsSettingBorderColor: _componentColor(components, "settings", "settingBorderColor", general.mutedTextColor || _componentColor(components, "settings", "textColor", general.textColor)),
            quickSettingsSettingBackgroundColor: _componentColor(components, "settings", "settingBackgroundColor", "transparent"),
            quickSettingsButtonHoverEffectColor: _componentColor(components, "settings", "buttonHoverEffectColor", _componentColor(components, "settings", "accentColor", general.accentColor)),
            quickSettingsButtonActiveColor: _componentColor(components, "settings", "buttonActiveColor", _componentColor(components, "settings", "activeSettingBackgroundColor", "transparent")),
            quickSettingsButtonInactiveColor: _componentColor(components, "settings", "buttonInactiveColor", _componentColor(components, "settings", "settingBackgroundColor", "transparent")),
            settingsRounding: _componentRounding(components, "settings", general.rounding),
            wallpaperPath: String(source.wallpaperPath || ""),
            rounding: general.rounding,
            borderWidth: general.borderWidth,
            buttonBorderWidth: general.buttonBorderWidth,
            overlayBorderWidth: general.overlayBorderWidth,
            panelOpacity: general.panelOpacity,
            overlayDimOpacity: general.overlayDimOpacity
        };
    }

    function applyThemeObject(theme) {
        const next = normalizeTheme(theme);
        config.themeMode = next.themeMode;
        config.accentColor = next.accentColor;
        config.borderColor = next.borderColor;
        config.backgroundColor = next.backgroundColor;
        config.textColor = next.textColor;
        config.barAccentColor = next.barAccentColor;
        config.barBackgroundColor = next.barBackgroundColor;
        config.barTextColor = next.barTextColor;
        config.barRounding = next.barRounding;
        config.workspaceAccentColor = next.workspaceAccentColor;
        config.workspaceBackgroundColor = next.workspaceBackgroundColor;
        config.workspaceColor = next.workspaceColor;
        config.workspaceActiveTextColor = next.workspaceActiveTextColor;
        config.workspaceActiveGroupBackgroundColor = next.workspaceActiveGroupBackgroundColor;
        config.workspaceActiveGroupBorderColor = next.workspaceActiveGroupBorderColor;
        config.workspaceHighlightColor = next.workspaceHighlightColor;
        config.workspaceRounding = next.workspaceRounding;
        config.volumeColor = next.volumeColor;
        config.quickSidebarColor = next.quickSidebarColor;
        config.sidebarBackgroundColor = next.sidebarBackgroundColor;
        config.sidebarTextColor = next.sidebarTextColor;
        config.sidebarRounding = next.sidebarRounding;
        config.dashboardColor = next.dashboardColor;
        config.dashboardBackgroundColor = next.dashboardBackgroundColor;
        config.dashboardTextColor = next.dashboardTextColor;
        config.dashboardWeatherAccentColor = next.dashboardWeatherAccentColor;
        config.dashboardWeatherTextColor = next.dashboardWeatherTextColor;
        config.dashboardWeatherIconColor = next.dashboardWeatherIconColor;
        config.dashboardWeatherIconBackgroundColor = next.dashboardWeatherIconBackgroundColor;
        config.dashboardSystemAccentColor = next.dashboardSystemAccentColor;
        config.dashboardClockHourColor = next.dashboardClockHourColor;
        config.dashboardClockMinuteColor = next.dashboardClockMinuteColor;
        config.dashboardClockSecondColor = next.dashboardClockSecondColor;
        config.dashboardClockSecondsTimerColor = next.dashboardClockSecondsTimerColor;
        config.dashboardCalendarWeekendColor = next.dashboardCalendarWeekendColor;
        config.dashboardCalendarActiveColor = next.dashboardCalendarActiveColor;
        config.dashboardCalendarCurrentDayColor = next.dashboardCalendarCurrentDayColor;
        config.dashboardUsageBarBackgroundColor = next.dashboardUsageBarBackgroundColor;
        config.dashboardWifiDownColor = next.dashboardWifiDownColor;
        config.dashboardWifiUpColor = next.dashboardWifiUpColor;
        config.dashboardBatteryPerformanceColor = next.dashboardBatteryPerformanceColor;
        config.dashboardRamUsageColor = next.dashboardRamUsageColor;
        config.dashboardDiskUsageColor = next.dashboardDiskUsageColor;
        config.dashboardCpuColor = next.dashboardCpuColor;
        config.dashboardGpuColor = next.dashboardGpuColor;
        config.dashboardCpuBarColor = next.dashboardCpuBarColor;
        config.dashboardRamBarColor = next.dashboardRamBarColor;
        config.dashboardDiskBarColor = next.dashboardDiskBarColor;
        config.dashboardMediaControlsColor = next.dashboardMediaControlsColor;
        config.dashboardMediaDurationBarColor = next.dashboardMediaDurationBarColor;
        config.dashboardPerformanceCpuBackgroundFillColor = next.dashboardPerformanceCpuBackgroundFillColor;
        config.dashboardPerformanceCpuTempBarColor = next.dashboardPerformanceCpuTempBarColor;
        config.dashboardPerformanceGpuBackgroundFillColor = next.dashboardPerformanceGpuBackgroundFillColor;
        config.dashboardPerformanceGpuTempBarColor = next.dashboardPerformanceGpuTempBarColor;
        config.dashboardPerformanceMemoryBarFillColor = next.dashboardPerformanceMemoryBarFillColor;
        config.dashboardPerformanceDiskBarFillColor = next.dashboardPerformanceDiskBarFillColor;
        config.dashboardPerformanceBatteryFillColor = next.dashboardPerformanceBatteryFillColor;
        config.dashboardUpdatesPackageBarFillColor = next.dashboardUpdatesPackageBarFillColor;
        config.dashboardUpdatesSecurityBarFillColor = next.dashboardUpdatesSecurityBarFillColor;
        config.dashboardUpdatesAURBarFillColor = next.dashboardUpdatesAURBarFillColor;
        config.dashboardUpdatesKernelBarFillColor = next.dashboardUpdatesKernelBarFillColor;
        config.dashboardUpdatesSystemRadialFillColor = next.dashboardUpdatesSystemRadialFillColor;
        config.dashboardUpdatesPackageRadialFillColor = next.dashboardUpdatesPackageRadialFillColor;
        config.dashboardUpdatesSecurityRadialFillColor = next.dashboardUpdatesSecurityRadialFillColor;
        config.dashboardUpdatesAURRadialFillColor = next.dashboardUpdatesAURRadialFillColor;
        config.dashboardUpdatesKernelRadialFillColor = next.dashboardUpdatesKernelRadialFillColor;
        config.dashboardRounding = next.dashboardRounding;
        config.overlayAccentColor = next.overlayAccentColor;
        config.overlayBackgroundColor = next.overlayBackgroundColor;
        config.overlayTextColor = next.overlayTextColor;
        config.overlayDateColor = next.overlayDateColor;
        config.overlayDateFormat = next.overlayDateFormat;
        config.overlayTimeFormat = next.overlayTimeFormat;
        config.overlayDateTimeFormat = next.overlayDateTimeFormat;
        config.buttonTextColor = next.buttonTextColor;
        config.buttonBorderColor = next.buttonBorderColor;
        config.buttonBackgroundColor = next.buttonBackgroundColor;
        config.buttonActiveTextColor = next.buttonActiveTextColor;
        config.buttonActiveBorderColor = next.buttonActiveBorderColor;
        config.buttonActiveBackgroundColor = next.buttonActiveBackgroundColor;
        config.overlayBatteryBarColorCritical = next.overlayBatteryBarColorCritical;
        config.overlayBatteryBarColorLow = next.overlayBatteryBarColorLow;
        config.overlayBatteryBarColorMedium = next.overlayBatteryBarColorMedium;
        config.overlayBatteryBarColorHigh = next.overlayBatteryBarColorHigh;
        config.overlayBatteryBarColorFull = next.overlayBatteryBarColorFull;
        config.overlayRounding = next.overlayRounding;
        config.visualizationBackgroundColor = next.visualizationBackgroundColor;
        config.visualizationTextColor = next.visualizationTextColor;
        config.visualizationBorderColor = next.visualizationBorderColor;
        config.workspaceVisualizationBackgroundColor = next.workspaceVisualizationBackgroundColor;
        config.visualizationRounding = next.visualizationRounding;
        config.settingsAccentColor = next.settingsAccentColor;
        config.settingsBackgroundColor = next.settingsBackgroundColor;
        config.settingsTextColor = next.settingsTextColor;
        config.quickSettingsNotificationTextColor = next.quickSettingsNotificationTextColor;
        config.quickSettingsNotificationBorderColor = next.quickSettingsNotificationBorderColor;
        config.quickSettingsNotificationBackgroundColor = next.quickSettingsNotificationBackgroundColor;
        config.quickSettingsNotificationPopupBackgroundColor = next.quickSettingsNotificationPopupBackgroundColor;
        config.quickSettingsNotificationPopupBorderColor = next.quickSettingsNotificationPopupBorderColor;
        config.quickSettingsNotificationPopupBorderWidth = next.quickSettingsNotificationPopupBorderWidth;
        config.quickSettingsNotificationPadding = next.quickSettingsNotificationPadding;
        config.quickSettingsNotificationHeightBoost = next.quickSettingsNotificationHeightBoost;
        config.quickSettingsActiveSettingTextColor = next.quickSettingsActiveSettingTextColor;
        config.quickSettingsActiveSettingBorderColor = next.quickSettingsActiveSettingBorderColor;
        config.quickSettingsActiveSettingBackgroundColor = next.quickSettingsActiveSettingBackgroundColor;
        config.quickSettingsSettingTextColor = next.quickSettingsSettingTextColor;
        config.quickSettingsSettingBorderColor = next.quickSettingsSettingBorderColor;
        config.quickSettingsSettingBackgroundColor = next.quickSettingsSettingBackgroundColor;
        config.quickSettingsButtonHoverEffectColor = next.quickSettingsButtonHoverEffectColor;
        config.quickSettingsButtonActiveColor = next.quickSettingsButtonActiveColor;
        config.quickSettingsButtonInactiveColor = next.quickSettingsButtonInactiveColor;
        config.settingsRounding = next.settingsRounding;
        store.panelColor = String(next.panelColor || "");
        store.mutedTextColor = String(next.mutedTextColor || "");
        const themedWallpaper = String(next.wallpaperPath || "").trim();
        if (themedWallpaper.length > 0)
            store.wallpaperPath = themedWallpaper;
        config.rounding = Math.round(next.rounding);
        config.borderWidth = Math.round(next.borderWidth);
        config.buttonBorderWidth = Math.round(next.buttonBorderWidth);
        config.overlayBorderWidth = Math.round(next.overlayBorderWidth);
        config.panelOpacity = Math.max(0.55, Math.min(1, next.panelOpacity));
        config.overlayDimOpacity = Math.max(0, Math.min(0.9, next.overlayDimOpacity));
        root.applyWallpaper(store.wallpaperPath);
        if (root.detectedWindowManagerKey === "hyprland") {
            let deco = Object.assign({}, config.hyprlandDecoration || root.defaultHyprlandDecoration());
            deco.activeBorderColor = next.accentColor;
            config.hyprlandDecoration = deco;
        }
        root.queueStoreSave();
    }

    function createThemeFromCurrent(name, id) {
        return normalizeTheme({
            id: id || ("theme-" + Date.now()),
            name: name || "New Theme",
            themeMode: String(config.themeMode),
            general: {
                accentColor: String(config.accentColor),
                borderColor: String(config.borderColor),
                backgroundColor: String(config.backgroundColor),
                textColor: String(config.textColor),
                panelColor: String(store.panelColor || ""),
                mutedTextColor: String(store.mutedTextColor || ""),
                rounding: store.rounding,
                borderWidth: store.borderWidth,
                buttonBorderWidth: store.buttonBorderWidth,
                overlayBorderWidth: store.overlayBorderWidth,
                panelOpacity: store.panelOpacity,
                overlayDimOpacity: store.overlayDimOpacity
            },
            components: {
                bar: {
                    accentColor: String(store.barAccentColor || ""),
                    backgroundColor: String(store.barBackgroundColor || ""),
                    textColor: String(store.barTextColor || ""),
                    rounding: store.barRounding
                },
                workspace: {
                    accentColor: String(store.workspaceAccentColor || ""),
                    backgroundColor: String(store.workspaceBackgroundColor || ""),
                    textColor: String(store.workspaceColor || ""),
                    activeTextColor: String(store.workspaceActiveTextColor || ""),
                    activeGroupBackgroundColor: String(store.workspaceActiveGroupBackgroundColor || ""),
                    activeGroupBorderColor: String(store.workspaceActiveGroupBorderColor || ""),
                    highlightColor: String(store.workspaceHighlightColor || ""),
                    visualizationBorderColor: String(store.visualizationBorderColor || ""),
                    visualizationBackgroundColor: String(store.workspaceVisualizationBackgroundColor || ""),
                    rounding: store.workspaceRounding
                },
                dashboard: {
                    accentColor: String(store.dashboardColor || ""),
                    backgroundColor: String(store.dashboardBackgroundColor || ""),
                    textColor: String(store.dashboardTextColor || ""),
                    weatherAccentColor: String(store.dashboardWeatherAccentColor || ""),
                    weatherTextColor: String(store.dashboardWeatherTextColor || ""),
                    weatherIconColor: String(store.dashboardWeatherIconColor || ""),
                    weatherIconBackgroundColor: String(store.dashboardWeatherIconBackgroundColor || ""),
                    systemAccentColor: String(store.dashboardSystemAccentColor || ""),
                    clockHourColor: String(store.dashboardClockHourColor || ""),
                    clockMinuteColor: String(store.dashboardClockMinuteColor || ""),
                    clockSecondColor: String(store.dashboardClockSecondColor || ""),
                    clockSecondsTimerColor: String(store.dashboardClockSecondsTimerColor || ""),
                    calendarWeekendColor: String(store.dashboardCalendarWeekendColor || ""),
                    calendarActiveColor: String(store.dashboardCalendarActiveColor || ""),
                    calendarCurrentDayColor: String(store.dashboardCalendarCurrentDayColor || ""),
                    usageBarBackgroundColor: String(store.dashboardUsageBarBackgroundColor || ""),
                    wifiDownColor: String(store.dashboardWifiDownColor || ""),
                    wifiUpColor: String(store.dashboardWifiUpColor || ""),
                    batteryPerformanceColor: String(store.dashboardBatteryPerformanceColor || ""),
                    ramUsageColor: String(store.dashboardRamUsageColor || ""),
                    diskUsageColor: String(store.dashboardDiskUsageColor || ""),
                    cpuColor: String(store.dashboardCpuColor || ""),
                    gpuColor: String(store.dashboardGpuColor || ""),
                    cpuBarColor: String(store.dashboardCpuBarColor || ""),
                    ramBarColor: String(store.dashboardRamBarColor || ""),
                    diskBarColor: String(store.dashboardDiskBarColor || ""),
                    mediaControlsColor: String(store.dashboardMediaControlsColor || ""),
                    mediaDurationBarColor: String(store.dashboardMediaDurationBarColor || ""),
                    performanceCpuBackgroundFillColor: String(store.dashboardPerformanceCpuBackgroundFillColor || ""),
                    performanceCpuTempBarColor: String(store.dashboardPerformanceCpuTempBarColor || ""),
                    performanceGpuBackgroundFillColor: String(store.dashboardPerformanceGpuBackgroundFillColor || ""),
                    performanceGpuTempBarColor: String(store.dashboardPerformanceGpuTempBarColor || ""),
                    performanceMemoryBarFillColor: String(store.dashboardPerformanceMemoryBarFillColor || ""),
                    performanceDiskBarFillColor: String(store.dashboardPerformanceDiskBarFillColor || ""),
                    performanceBatteryFillColor: String(store.dashboardPerformanceBatteryFillColor || ""),
                    updatesPackageBarFillColor: String(store.dashboardUpdatesPackageBarFillColor || ""),
                    updatesSecurityBarFillColor: String(store.dashboardUpdatesSecurityBarFillColor || ""),
                    updatesAURBarFillColor: String(store.dashboardUpdatesAURBarFillColor || ""),
                    updatesKernelBarFillColor: String(store.dashboardUpdatesKernelBarFillColor || ""),
                    updatesSystemRadialFillColor: String(store.dashboardUpdatesSystemRadialFillColor || ""),
                    updatesPackageRadialFillColor: String(store.dashboardUpdatesPackageRadialFillColor || ""),
                    updatesSecurityRadialFillColor: String(store.dashboardUpdatesSecurityRadialFillColor || ""),
                    updatesAURRadialFillColor: String(store.dashboardUpdatesAURRadialFillColor || ""),
                    updatesKernelRadialFillColor: String(store.dashboardUpdatesKernelRadialFillColor || ""),
                    rounding: store.dashboardRounding
                },
                sidebar: {
                    accentColor: String(store.quickSidebarColor || ""),
                    backgroundColor: String(store.sidebarBackgroundColor || ""),
                    textColor: String(store.sidebarTextColor || ""),
                    rounding: store.sidebarRounding
                },
                overlay: {
                    accentColor: String(store.overlayAccentColor || ""),
                    backgroundColor: String(store.overlayBackgroundColor || ""),
                    textColor: String(store.overlayTextColor || ""),
                    dateColor: String(store.overlayDateColor || ""),
                    dateFormat: String(store.overlayDateFormat || ""),
                    timeFormat: String(store.overlayTimeFormat || ""),
                    dateTimeFormat: String(store.overlayDateTimeFormat || ""),
                    buttonTextColor: String(store.buttonTextColor || ""),
                    buttonBorderColor: String(store.buttonBorderColor || ""),
                    buttonBackgroundColor: String(store.buttonBackgroundColor || ""),
                    buttonActiveTextColor: String(store.buttonActiveTextColor || ""),
                    buttonActiveBorderColor: String(store.buttonActiveBorderColor || ""),
                    buttonActiveBackgroundColor: String(store.buttonActiveBackgroundColor || ""),
                    batteryBarColorCritical: String(store.overlayBatteryBarColorCritical || ""),
                    batteryBarColorLow: String(store.overlayBatteryBarColorLow || ""),
                    batteryBarColorMedium: String(store.overlayBatteryBarColorMedium || ""),
                    batteryBarColorHigh: String(store.overlayBatteryBarColorHigh || ""),
                    batteryBarColorFull: String(store.overlayBatteryBarColorFull || ""),
                    rounding: store.overlayRounding
                },
                visualization: {
                    accentColor: String(store.volumeColor || ""),
                    backgroundColor: String(store.visualizationBackgroundColor || ""),
                    textColor: String(store.visualizationTextColor || ""),
                    rounding: store.visualizationRounding
                },
                settings: {
                    accentColor: String(store.settingsAccentColor || ""),
                    backgroundColor: String(store.settingsBackgroundColor || ""),
                    textColor: String(store.settingsTextColor || ""),
                    notificationTextColor: String(store.quickSettingsNotificationTextColor || ""),
                    notificationBorderColor: String(store.quickSettingsNotificationBorderColor || ""),
                    notificationBackgroundColor: String(store.quickSettingsNotificationBackgroundColor || ""),
                    notificationPopupBackgroundColor: String(store.quickSettingsNotificationPopupBackgroundColor || ""),
                    notificationPopupBorderColor: String(store.quickSettingsNotificationPopupBorderColor || ""),
                    notificationPopupBorderWidth: store.quickSettingsNotificationPopupBorderWidth,
                    notificationPadding: store.quickSettingsNotificationPadding,
                    notificationHeightBoost: store.quickSettingsNotificationHeightBoost,
                    activeSettingTextColor: String(store.quickSettingsActiveSettingTextColor || ""),
                    activeSettingBorderColor: String(store.quickSettingsActiveSettingBorderColor || ""),
                    activeSettingBackgroundColor: String(store.quickSettingsActiveSettingBackgroundColor || ""),
                    settingTextColor: String(store.quickSettingsSettingTextColor || ""),
                    settingBorderColor: String(store.quickSettingsSettingBorderColor || ""),
                    settingBackgroundColor: String(store.quickSettingsSettingBackgroundColor || ""),
                    buttonHoverEffectColor: String(store.quickSettingsButtonHoverEffectColor || ""),
                    buttonActiveColor: String(store.quickSettingsButtonActiveColor || ""),
                    buttonInactiveColor: String(store.quickSettingsButtonInactiveColor || ""),
                    rounding: store.settingsRounding
                }
            },
            panelColor: String(store.panelColor || ""),
            mutedTextColor: String(store.mutedTextColor || ""),
            wallpaperPath: String(store.wallpaperPath || ""),
            rounding: store.rounding,
            borderWidth: store.borderWidth,
            buttonBorderWidth: store.buttonBorderWidth,
            overlayBorderWidth: store.overlayBorderWidth,
            panelOpacity: store.panelOpacity,
            overlayDimOpacity: store.overlayDimOpacity
        });
    }

    function applyWallpaper(path) {
        const p = String(path || "").trim();
        if (!p.length)
            return;
        const q = p.replace(/'/g, "'\"'\"'");
        wallpaperProc.exec({
            command: ["bash", "-lc", "if command -v hyprctl >/dev/null 2>&1; then hyprctl hyprpaper preload '" + q + "' 2>/dev/null; hyprctl hyprpaper wallpaper '," + q + "' 2>/dev/null; fi"]
        });
    }

    function setActiveThemeById(themeId) {
        const id = String(themeId || "");
        for (let i = 0; i < config.themeLibrary.length; i++) {
            if (String(config.themeLibrary[i].id) !== id)
                continue;
            config.activeThemeId = id;
            applyThemeObject(config.themeLibrary[i]);
            return true;
        }
        return false;
    }

    function saveTheme(theme) {
        const nextTheme = normalizeTheme(theme);
        let nextLibrary = _deepCopy(config.themeLibrary || []);
        let replaced = false;
        for (let i = 0; i < nextLibrary.length; i++) {
            if (String(nextLibrary[i].id) === nextTheme.id) {
                nextLibrary[i] = nextTheme;
                replaced = true;
                break;
            }
        }
        if (!replaced)
            nextLibrary.push(nextTheme);
        config.themeLibrary = nextLibrary;
        config.activeThemeId = nextTheme.id;
        applyThemeObject(nextTheme);
        return nextTheme.id;
    }

    function duplicateTheme(themeId) {
        for (let i = 0; i < config.themeLibrary.length; i++) {
            const theme = config.themeLibrary[i];
            if (String(theme.id) !== String(themeId))
                continue;
            return saveTheme(normalizeTheme(Object.assign({}, theme, {
                id: "theme-" + Date.now(),
                name: String(theme.name || "Theme") + " Copy"
            })));
        }
        return "";
    }

    function deleteTheme(themeId) {
        const currentId = String(themeId || "");
        let nextLibrary = [];
        for (let i = 0; i < config.themeLibrary.length; i++) {
            if (String(config.themeLibrary[i].id) !== currentId)
                nextLibrary.push(config.themeLibrary[i]);
        }
        if (nextLibrary.length < 1)
            nextLibrary = defaultThemeLibrary();
        config.themeLibrary = _deepCopy(nextLibrary);
        if (!setActiveThemeById(config.activeThemeId))
            setActiveThemeById(nextLibrary[0].id);
    }

    function queueHyprlandSync() {
        hyprlandSyncTimer.restart();
    }

    QtObject {
        id: store

        property string barOrientation: "top"
        property string themeMode: "dark"
        property string accentColor: "#ff8c32"
        property string borderColor: "#ff8c32"
        property string backgroundColor: "#0f0f12"
        property string workspaceColor: "#111827"
        property string textColor: "#be5103"
        property string barAccentColor: "#ff8c32"
        property string barBackgroundColor: ""
        property string barTextColor: ""
        property int barRounding: 8
        property string workspaceAccentColor: "#ff8c32"
        property string workspaceBackgroundColor: ""
        property string workspaceActiveTextColor: ""
        property string workspaceActiveGroupBackgroundColor: ""
        property string workspaceActiveGroupBorderColor: ""
        property string workspaceHighlightColor: ""
        property int workspaceRounding: 8
        property string volumeColor: "#ff8c32"
        property string quickSidebarColor: "#ff8c32"
        property string sidebarBackgroundColor: ""
        property string sidebarTextColor: ""
        property int sidebarRounding: 8
        property string dashboardColor: "#41aefc"
        property string dashboardBackgroundColor: ""
        property string dashboardTextColor: ""
        property string dashboardWeatherAccentColor: ""
        property string dashboardWeatherTextColor: ""
        property string dashboardWeatherIconColor: ""
        property string dashboardWeatherIconBackgroundColor: ""
        property string dashboardSystemAccentColor: ""
        property string dashboardClockHourColor: ""
        property string dashboardClockMinuteColor: ""
        property string dashboardClockSecondColor: ""
        property string dashboardClockSecondsTimerColor: ""
        property string dashboardCalendarWeekendColor: ""
        property string dashboardCalendarActiveColor: ""
        property string dashboardCalendarCurrentDayColor: ""
        property string dashboardUsageBarBackgroundColor: ""
        property string dashboardWifiDownColor: ""
        property string dashboardWifiUpColor: ""
        property string dashboardBatteryPerformanceColor: ""
        property string dashboardRamUsageColor: ""
        property string dashboardDiskUsageColor: ""
        property string dashboardCpuColor: ""
        property string dashboardGpuColor: ""
        property string dashboardCpuBarColor: ""
        property string dashboardRamBarColor: ""
        property string dashboardDiskBarColor: ""
        property string dashboardMediaControlsColor: ""
        property string dashboardMediaDurationBarColor: ""
        property string dashboardPerformanceCpuBackgroundFillColor: ""
        property string dashboardPerformanceCpuTempBarColor: ""
        property string dashboardPerformanceGpuBackgroundFillColor: ""
        property string dashboardPerformanceGpuTempBarColor: ""
        property string dashboardPerformanceMemoryBarFillColor: ""
        property string dashboardPerformanceDiskBarFillColor: ""
        property string dashboardPerformanceBatteryFillColor: ""
        property string dashboardUpdatesPackageBarFillColor: ""
        property string dashboardUpdatesSecurityBarFillColor: ""
        property string dashboardUpdatesAURBarFillColor: ""
        property string dashboardUpdatesKernelBarFillColor: ""
        property string dashboardUpdatesSystemRadialFillColor: ""
        property string dashboardUpdatesPackageRadialFillColor: ""
        property string dashboardUpdatesSecurityRadialFillColor: ""
        property string dashboardUpdatesAURRadialFillColor: ""
        property string dashboardUpdatesKernelRadialFillColor: ""
        property int dashboardRounding: 8
        property string overlayAccentColor: "#ff8c32"
        property string overlayBackgroundColor: ""
        property string overlayTextColor: ""
        property string overlayDateColor: ""
        property string overlayDateFormat: "%a %d %b"
        property string overlayTimeFormat: "%H:%M"
        property string overlayDateTimeFormat: "date-time"
        property string buttonTextColor: ""
        property string buttonBorderColor: ""
        property string buttonBackgroundColor: "transparent"
        property string buttonActiveTextColor: ""
        property string buttonActiveBorderColor: ""
        property string buttonActiveBackgroundColor: "transparent"
        property string overlayBatteryBarColorCritical: "#ef4444"
        property string overlayBatteryBarColorLow: "#f59e0b"
        property string overlayBatteryBarColorMedium: ""
        property string overlayBatteryBarColorHigh: ""
        property string overlayBatteryBarColorFull: ""
        property int overlayRounding: 8
        property string visualizationBackgroundColor: ""
        property string visualizationTextColor: ""
        property string visualizationBorderColor: ""
        property string workspaceVisualizationBackgroundColor: ""
        property int visualizationRounding: 8
        property string settingsAccentColor: "#ff8c32"
        property string settingsBackgroundColor: ""
        property string settingsTextColor: ""
        property string quickSettingsNotificationTextColor: ""
        property string quickSettingsNotificationBorderColor: ""
        property string quickSettingsNotificationBackgroundColor: "transparent"
        property string quickSettingsNotificationPopupBackgroundColor: ""
        property string quickSettingsNotificationPopupBorderColor: ""
        property int quickSettingsNotificationPopupBorderWidth: 1
        property int quickSettingsNotificationPadding: 8
        property int quickSettingsNotificationHeightBoost: 18
        property string quickSettingsActiveSettingTextColor: ""
        property string quickSettingsActiveSettingBorderColor: ""
        property string quickSettingsActiveSettingBackgroundColor: "transparent"
        property string quickSettingsSettingTextColor: ""
        property string quickSettingsSettingBorderColor: ""
        property string quickSettingsSettingBackgroundColor: "transparent"
        property string quickSettingsButtonHoverEffectColor: ""
        property string quickSettingsButtonActiveColor: ""
        property string quickSettingsButtonInactiveColor: ""
        property int settingsRounding: 8
        property string panelColor: ""
        property string mutedTextColor: ""
        property string wallpaperPath: ""
        property var themeLibrary: root.defaultThemeLibrary()
        property string activeThemeId: "ember-all"
        property int rounding: 8
        property int borderWidth: 1
        property int buttonBorderWidth: 1
        property int overlayBorderWidth: 1
        property real panelOpacity: 0.96
        property real overlayDimOpacity: 0.4
        property string fontFamily: "JetBrainsMono Nerd Font"
        property int fontPixelSize: 12
        property bool sidebarEnabled: true
        property var barOverlayVisibility: root.defaultBarOverlayVisibility()
        property var dashboardTabVisibility: root.defaultDashboardTabVisibility()
        property int sidebarEdgeHoldMs: 550
        property int sidebarEdgeThresholdPx: 2
        property int hoverReleaseMs: 220
        property int sidebarSliderHeight: 100
        property int barWorkspacePollMs: 450
        property int barMediumPollMs: 700
        property int barSlowPollMs: 1800
        property int quickSidebarPollMs: 1500
        property bool dashboardEnabled: true
        property int dashboardRefreshMs: 1200
        property int dashboardFastPollMs: 1200
        property int dashboardMediumPollMs: 2400
        property int dashboardSlowPollMs: 4800
        property bool showShellTitle: true
        property bool workspaceShowAllScreens: false
        property bool workspaceActiveScreenBackground: true
        property bool workspaceHighlightCurrent: true
        property bool workspaceShowWindowIcons: true
        property bool workspaceShowLayoutOnHover: true
        property bool workspaceSegmentVisible: true
        property int workspaceVisibleCount: 8
        property int workspaceMaxIcons: 1
        // "standard" | "uppercase" — titles, buttons, and chrome labels
        property string uiTextStyle: "standard"
        property bool controlCenterEnableHotkey: true
        property string controlCenterHotkey: "Ctrl+Alt+C"
        property bool dashboardEnableHotkey: true
        property string dashboardHotkey: "Ctrl+Alt+D"
        property bool sidebarEnableHotkey: true
        property string sidebarHotkey: "Ctrl+Alt+B"
        property bool hyprlandManagedEnabled: true
        property bool hyprlandShowInfoMessage: true
        property bool hyprlandDisableSplash: false
        property var hyprlandMonitors: root.defaultHyprlandMonitors()
        property var hyprlandDecoration: root.defaultHyprlandDecoration()
        property var hyprlandBinds: root.defaultHyprlandBinds()
        property var hyprlandWorkspaceRules: root.defaultHyprlandWorkspaceRules()
        property var quickSettingsTiles: root.defaultQuickSettingsTiles()
    }

    function saveStore() {
        const payload = {
            barOrientation: store.barOrientation,
            themeMode: store.themeMode,
            accentColor: store.accentColor,
            borderColor: store.borderColor,
            backgroundColor: store.backgroundColor,
            workspaceColor: store.workspaceColor,
            textColor: store.textColor,
            barAccentColor: store.barAccentColor,
            barBackgroundColor: store.barBackgroundColor,
            barTextColor: store.barTextColor,
            barRounding: store.barRounding,
            workspaceAccentColor: store.workspaceAccentColor,
            workspaceBackgroundColor: store.workspaceBackgroundColor,
            workspaceActiveTextColor: store.workspaceActiveTextColor,
            workspaceActiveGroupBackgroundColor: store.workspaceActiveGroupBackgroundColor,
            workspaceActiveGroupBorderColor: store.workspaceActiveGroupBorderColor,
            workspaceHighlightColor: store.workspaceHighlightColor,
            workspaceRounding: store.workspaceRounding,
            volumeColor: store.volumeColor,
            quickSidebarColor: store.quickSidebarColor,
            sidebarBackgroundColor: store.sidebarBackgroundColor,
            sidebarTextColor: store.sidebarTextColor,
            sidebarRounding: store.sidebarRounding,
            dashboardColor: store.dashboardColor,
            dashboardBackgroundColor: store.dashboardBackgroundColor,
            dashboardTextColor: store.dashboardTextColor,
            dashboardWeatherAccentColor: store.dashboardWeatherAccentColor,
            dashboardWeatherTextColor: store.dashboardWeatherTextColor,
            dashboardWeatherIconColor: store.dashboardWeatherIconColor,
            dashboardWeatherIconBackgroundColor: store.dashboardWeatherIconBackgroundColor,
            dashboardSystemAccentColor: store.dashboardSystemAccentColor,
            dashboardClockHourColor: store.dashboardClockHourColor,
            dashboardClockMinuteColor: store.dashboardClockMinuteColor,
            dashboardClockSecondColor: store.dashboardClockSecondColor,
            dashboardClockSecondsTimerColor: store.dashboardClockSecondsTimerColor,
            dashboardCalendarWeekendColor: store.dashboardCalendarWeekendColor,
            dashboardCalendarActiveColor: store.dashboardCalendarActiveColor,
            dashboardCalendarCurrentDayColor: store.dashboardCalendarCurrentDayColor,
            dashboardUsageBarBackgroundColor: store.dashboardUsageBarBackgroundColor,
            dashboardWifiDownColor: store.dashboardWifiDownColor,
            dashboardWifiUpColor: store.dashboardWifiUpColor,
            dashboardBatteryPerformanceColor: store.dashboardBatteryPerformanceColor,
            dashboardRamUsageColor: store.dashboardRamUsageColor,
            dashboardDiskUsageColor: store.dashboardDiskUsageColor,
            dashboardCpuColor: store.dashboardCpuColor,
            dashboardGpuColor: store.dashboardGpuColor,
            dashboardCpuBarColor: store.dashboardCpuBarColor,
            dashboardRamBarColor: store.dashboardRamBarColor,
            dashboardDiskBarColor: store.dashboardDiskBarColor,
            dashboardMediaControlsColor: store.dashboardMediaControlsColor,
            dashboardMediaDurationBarColor: store.dashboardMediaDurationBarColor,
            dashboardPerformanceCpuBackgroundFillColor: store.dashboardPerformanceCpuBackgroundFillColor,
            dashboardPerformanceCpuTempBarColor: store.dashboardPerformanceCpuTempBarColor,
            dashboardPerformanceGpuBackgroundFillColor: store.dashboardPerformanceGpuBackgroundFillColor,
            dashboardPerformanceGpuTempBarColor: store.dashboardPerformanceGpuTempBarColor,
            dashboardPerformanceMemoryBarFillColor: store.dashboardPerformanceMemoryBarFillColor,
            dashboardPerformanceDiskBarFillColor: store.dashboardPerformanceDiskBarFillColor,
            dashboardPerformanceBatteryFillColor: store.dashboardPerformanceBatteryFillColor,
            dashboardUpdatesPackageBarFillColor: store.dashboardUpdatesPackageBarFillColor,
            dashboardUpdatesSecurityBarFillColor: store.dashboardUpdatesSecurityBarFillColor,
            dashboardUpdatesAURBarFillColor: store.dashboardUpdatesAURBarFillColor,
            dashboardUpdatesKernelBarFillColor: store.dashboardUpdatesKernelBarFillColor,
            dashboardUpdatesSystemRadialFillColor: store.dashboardUpdatesSystemRadialFillColor,
            dashboardUpdatesPackageRadialFillColor: store.dashboardUpdatesPackageRadialFillColor,
            dashboardUpdatesSecurityRadialFillColor: store.dashboardUpdatesSecurityRadialFillColor,
            dashboardUpdatesAURRadialFillColor: store.dashboardUpdatesAURRadialFillColor,
            dashboardUpdatesKernelRadialFillColor: store.dashboardUpdatesKernelRadialFillColor,
            dashboardRounding: store.dashboardRounding,
            overlayAccentColor: store.overlayAccentColor,
            overlayBackgroundColor: store.overlayBackgroundColor,
            overlayTextColor: store.overlayTextColor,
            overlayDateColor: store.overlayDateColor,
            overlayDateFormat: store.overlayDateFormat,
            overlayTimeFormat: store.overlayTimeFormat,
            overlayDateTimeFormat: store.overlayDateTimeFormat,
            buttonTextColor: store.buttonTextColor,
            buttonBorderColor: store.buttonBorderColor,
            buttonBackgroundColor: store.buttonBackgroundColor,
            buttonActiveTextColor: store.buttonActiveTextColor,
            buttonActiveBorderColor: store.buttonActiveBorderColor,
            buttonActiveBackgroundColor: store.buttonActiveBackgroundColor,
            overlayBatteryBarColorCritical: store.overlayBatteryBarColorCritical,
            overlayBatteryBarColorLow: store.overlayBatteryBarColorLow,
            overlayBatteryBarColorMedium: store.overlayBatteryBarColorMedium,
            overlayBatteryBarColorHigh: store.overlayBatteryBarColorHigh,
            overlayBatteryBarColorFull: store.overlayBatteryBarColorFull,
            overlayRounding: store.overlayRounding,
            visualizationBackgroundColor: store.visualizationBackgroundColor,
            visualizationTextColor: store.visualizationTextColor,
            visualizationBorderColor: store.visualizationBorderColor,
            workspaceVisualizationBackgroundColor: store.workspaceVisualizationBackgroundColor,
            visualizationRounding: store.visualizationRounding,
            settingsAccentColor: store.settingsAccentColor,
            settingsBackgroundColor: store.settingsBackgroundColor,
            settingsTextColor: store.settingsTextColor,
            quickSettingsNotificationTextColor: store.quickSettingsNotificationTextColor,
            quickSettingsNotificationBorderColor: store.quickSettingsNotificationBorderColor,
            quickSettingsNotificationBackgroundColor: store.quickSettingsNotificationBackgroundColor,
            quickSettingsNotificationPopupBackgroundColor: store.quickSettingsNotificationPopupBackgroundColor,
            quickSettingsNotificationPopupBorderColor: store.quickSettingsNotificationPopupBorderColor,
            quickSettingsNotificationPopupBorderWidth: store.quickSettingsNotificationPopupBorderWidth,
            quickSettingsNotificationPadding: store.quickSettingsNotificationPadding,
            quickSettingsNotificationHeightBoost: store.quickSettingsNotificationHeightBoost,
            quickSettingsActiveSettingTextColor: store.quickSettingsActiveSettingTextColor,
            quickSettingsActiveSettingBorderColor: store.quickSettingsActiveSettingBorderColor,
            quickSettingsActiveSettingBackgroundColor: store.quickSettingsActiveSettingBackgroundColor,
            quickSettingsSettingTextColor: store.quickSettingsSettingTextColor,
            quickSettingsSettingBorderColor: store.quickSettingsSettingBorderColor,
            quickSettingsSettingBackgroundColor: store.quickSettingsSettingBackgroundColor,
            quickSettingsButtonHoverEffectColor: store.quickSettingsButtonHoverEffectColor,
            quickSettingsButtonActiveColor: store.quickSettingsButtonActiveColor,
            quickSettingsButtonInactiveColor: store.quickSettingsButtonInactiveColor,
            settingsRounding: store.settingsRounding,
            panelColor: store.panelColor,
            mutedTextColor: store.mutedTextColor,
            wallpaperPath: store.wallpaperPath,
            activeThemeId: store.activeThemeId,
            rounding: store.rounding,
            borderWidth: store.borderWidth,
            buttonBorderWidth: store.buttonBorderWidth,
            overlayBorderWidth: store.overlayBorderWidth,
            panelOpacity: store.panelOpacity,
            overlayDimOpacity: store.overlayDimOpacity,
            fontFamily: store.fontFamily,
            fontPixelSize: store.fontPixelSize,
            sidebarEnabled: store.sidebarEnabled,
            barOverlayVisibility: store.barOverlayVisibility,
            dashboardTabVisibility: store.dashboardTabVisibility,
            sidebarEdgeHoldMs: store.sidebarEdgeHoldMs,
            sidebarEdgeThresholdPx: store.sidebarEdgeThresholdPx,
            hoverReleaseMs: store.hoverReleaseMs,
            sidebarSliderHeight: store.sidebarSliderHeight,
            barWorkspacePollMs: store.barWorkspacePollMs,
            barMediumPollMs: store.barMediumPollMs,
            barSlowPollMs: store.barSlowPollMs,
            quickSidebarPollMs: store.quickSidebarPollMs,
            dashboardEnabled: store.dashboardEnabled,
            dashboardRefreshMs: store.dashboardRefreshMs,
            dashboardFastPollMs: store.dashboardFastPollMs,
            dashboardMediumPollMs: store.dashboardMediumPollMs,
            dashboardSlowPollMs: store.dashboardSlowPollMs,
            showShellTitle: store.showShellTitle,
            workspaceShowAllScreens: store.workspaceShowAllScreens,
            workspaceActiveScreenBackground: store.workspaceActiveScreenBackground,
            workspaceHighlightCurrent: store.workspaceHighlightCurrent,
            workspaceShowWindowIcons: store.workspaceShowWindowIcons,
            workspaceShowLayoutOnHover: store.workspaceShowLayoutOnHover,
            workspaceSegmentVisible: store.workspaceSegmentVisible,
            workspaceVisibleCount: store.workspaceVisibleCount,
            workspaceMaxIcons: store.workspaceMaxIcons,
            uiTextStyle: store.uiTextStyle,
            controlCenterEnableHotkey: store.controlCenterEnableHotkey,
            controlCenterHotkey: store.controlCenterHotkey,
            dashboardEnableHotkey: store.dashboardEnableHotkey,
            dashboardHotkey: store.dashboardHotkey,
            sidebarEnableHotkey: store.sidebarEnableHotkey,
            sidebarHotkey: store.sidebarHotkey,
            hyprlandManagedEnabled: store.hyprlandManagedEnabled,
            hyprlandShowInfoMessage: store.hyprlandShowInfoMessage,
            hyprlandDisableSplash: store.hyprlandDisableSplash,
            hyprlandMonitors: store.hyprlandMonitors,
            hyprlandDecoration: store.hyprlandDecoration,
            hyprlandBinds: store.hyprlandBinds,
            hyprlandWorkspaceRules: store.hyprlandWorkspaceRules,
            quickSettingsTiles: store.quickSettingsTiles
        };
        settingsFile.setText(JSON.stringify(payload, null, 2));
        root.queueSettingsSavedToast();
    }

    function queueStoreSave() {
        saveTimer.restart();
    }

    function queueSettingsSavedToast() {
        root.settingsSaveToastPending = true;
        if (root.controlCenterVisible)
            return;
        settingsSavedToastTimer.restart();
    }

    Timer {
        id: saveTimer
        interval: 120
        repeat: false
        onTriggered: root.saveStore()
    }

    Timer {
        id: settingsSavedToastTimer
        interval: 1200
        repeat: false
        onTriggered: {
            if (!root.settingsSaveToastPending)
                return;
            root.settingsSaveToastPending = false;
            root.pushSystemNotification("Settings saved", "Your preferences were saved.", 0, "Settings");
        }
    }

    Timer {
        id: hyprlandSyncTimer
        interval: 220
        repeat: false
        onTriggered: hyprlandSyncProc.exec({
            command: ["bash", Quickshell.shellDir + "/scripts/sync-hyprland.sh", settingsFile.path]
        })
    }

    Process {
        id: hyprlandSyncProc
    }

    Process {
        id: wallpaperProc
    }

    Process {
        id: themeLibraryProc
        command: ["python3", Quickshell.shellDir + "/scripts/load-themes.py", Quickshell.shellDir + "/themes"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.applyBundledThemeLibrary(String(text))
        }
    }

    FileView {
        id: settingsFile
        path: Quickshell.shellDir + "/settings.json"
        watchChanges: false

        onLoaded: {
            try {
                const cfg = JSON.parse(text());
                if (cfg.barOrientation !== undefined)
                    store.barOrientation = cfg.barOrientation;
                if (cfg.themeMode !== undefined)
                    store.themeMode = cfg.themeMode;
                if (cfg.accentColor !== undefined)
                    store.accentColor = cfg.accentColor;
                if (cfg.borderColor !== undefined)
                    store.borderColor = cfg.borderColor;
                if (cfg.backgroundColor !== undefined)
                    store.backgroundColor = cfg.backgroundColor;
                if (cfg.workspaceColor !== undefined)
                    store.workspaceColor = cfg.workspaceColor;
                if (cfg.textColor !== undefined)
                    store.textColor = cfg.textColor;
                if (cfg.barAccentColor !== undefined)
                    store.barAccentColor = cfg.barAccentColor;
                if (cfg.barBackgroundColor !== undefined)
                    store.barBackgroundColor = String(cfg.barBackgroundColor);
                if (cfg.barTextColor !== undefined)
                    store.barTextColor = String(cfg.barTextColor);
                if (cfg.barRounding !== undefined)
                    store.barRounding = cfg.barRounding;
                if (cfg.workspaceAccentColor !== undefined)
                    store.workspaceAccentColor = cfg.workspaceAccentColor;
                if (cfg.workspaceBackgroundColor !== undefined)
                    store.workspaceBackgroundColor = String(cfg.workspaceBackgroundColor);
                if (cfg.workspaceActiveTextColor !== undefined)
                    store.workspaceActiveTextColor = String(cfg.workspaceActiveTextColor);
                if (cfg.workspaceActiveGroupBackgroundColor !== undefined)
                    store.workspaceActiveGroupBackgroundColor = String(cfg.workspaceActiveGroupBackgroundColor);
                if (cfg.workspaceActiveGroupBorderColor !== undefined)
                    store.workspaceActiveGroupBorderColor = String(cfg.workspaceActiveGroupBorderColor);
                if (cfg.workspaceHighlightColor !== undefined)
                    store.workspaceHighlightColor = String(cfg.workspaceHighlightColor);
                if (cfg.workspaceRounding !== undefined)
                    store.workspaceRounding = cfg.workspaceRounding;
                if (cfg.volumeColor !== undefined)
                    store.volumeColor = cfg.volumeColor;
                if (cfg.quickSidebarColor !== undefined)
                    store.quickSidebarColor = cfg.quickSidebarColor;
                if (cfg.sidebarBackgroundColor !== undefined)
                    store.sidebarBackgroundColor = String(cfg.sidebarBackgroundColor);
                if (cfg.sidebarTextColor !== undefined)
                    store.sidebarTextColor = String(cfg.sidebarTextColor);
                if (cfg.sidebarRounding !== undefined)
                    store.sidebarRounding = cfg.sidebarRounding;
                if (cfg.dashboardColor !== undefined)
                    store.dashboardColor = cfg.dashboardColor;
                if (cfg.dashboardBackgroundColor !== undefined)
                    store.dashboardBackgroundColor = String(cfg.dashboardBackgroundColor);
                if (cfg.dashboardTextColor !== undefined)
                    store.dashboardTextColor = String(cfg.dashboardTextColor);
                if (cfg.dashboardWeatherAccentColor !== undefined)
                    store.dashboardWeatherAccentColor = String(cfg.dashboardWeatherAccentColor);
                if (cfg.dashboardWeatherTextColor !== undefined)
                    store.dashboardWeatherTextColor = String(cfg.dashboardWeatherTextColor);
                if (cfg.dashboardWeatherIconColor !== undefined)
                    store.dashboardWeatherIconColor = String(cfg.dashboardWeatherIconColor);
                if (cfg.dashboardWeatherIconBackgroundColor !== undefined)
                    store.dashboardWeatherIconBackgroundColor = String(cfg.dashboardWeatherIconBackgroundColor);
                if (cfg.dashboardSystemAccentColor !== undefined)
                    store.dashboardSystemAccentColor = String(cfg.dashboardSystemAccentColor);
                if (cfg.dashboardClockHourColor !== undefined)
                    store.dashboardClockHourColor = String(cfg.dashboardClockHourColor);
                if (cfg.dashboardClockMinuteColor !== undefined)
                    store.dashboardClockMinuteColor = String(cfg.dashboardClockMinuteColor);
                if (cfg.dashboardClockSecondColor !== undefined)
                    store.dashboardClockSecondColor = String(cfg.dashboardClockSecondColor);
                if (cfg.dashboardClockSecondsTimerColor !== undefined)
                    store.dashboardClockSecondsTimerColor = String(cfg.dashboardClockSecondsTimerColor);
                if (cfg.dashboardCalendarWeekendColor !== undefined)
                    store.dashboardCalendarWeekendColor = String(cfg.dashboardCalendarWeekendColor);
                if (cfg.dashboardCalendarActiveColor !== undefined)
                    store.dashboardCalendarActiveColor = String(cfg.dashboardCalendarActiveColor);
                if (cfg.dashboardCalendarCurrentDayColor !== undefined)
                    store.dashboardCalendarCurrentDayColor = String(cfg.dashboardCalendarCurrentDayColor);
                if (cfg.dashboardUsageBarBackgroundColor !== undefined)
                    store.dashboardUsageBarBackgroundColor = String(cfg.dashboardUsageBarBackgroundColor);
                if (cfg.dashboardWifiDownColor !== undefined)
                    store.dashboardWifiDownColor = String(cfg.dashboardWifiDownColor);
                if (cfg.dashboardWifiUpColor !== undefined)
                    store.dashboardWifiUpColor = String(cfg.dashboardWifiUpColor);
                if (cfg.dashboardBatteryPerformanceColor !== undefined)
                    store.dashboardBatteryPerformanceColor = String(cfg.dashboardBatteryPerformanceColor);
                if (cfg.dashboardRamUsageColor !== undefined)
                    store.dashboardRamUsageColor = String(cfg.dashboardRamUsageColor);
                if (cfg.dashboardDiskUsageColor !== undefined)
                    store.dashboardDiskUsageColor = String(cfg.dashboardDiskUsageColor);
                if (cfg.dashboardCpuColor !== undefined)
                    store.dashboardCpuColor = String(cfg.dashboardCpuColor);
                if (cfg.dashboardGpuColor !== undefined)
                    store.dashboardGpuColor = String(cfg.dashboardGpuColor);
                if (cfg.dashboardCpuBarColor !== undefined)
                    store.dashboardCpuBarColor = String(cfg.dashboardCpuBarColor);
                if (cfg.dashboardRamBarColor !== undefined)
                    store.dashboardRamBarColor = String(cfg.dashboardRamBarColor);
                if (cfg.dashboardDiskBarColor !== undefined)
                    store.dashboardDiskBarColor = String(cfg.dashboardDiskBarColor);
                if (cfg.dashboardMediaControlsColor !== undefined)
                    store.dashboardMediaControlsColor = String(cfg.dashboardMediaControlsColor);
                if (cfg.dashboardMediaDurationBarColor !== undefined)
                    store.dashboardMediaDurationBarColor = String(cfg.dashboardMediaDurationBarColor);
                if (cfg.dashboardPerformanceCpuBackgroundFillColor !== undefined)
                    store.dashboardPerformanceCpuBackgroundFillColor = String(cfg.dashboardPerformanceCpuBackgroundFillColor);
                if (cfg.dashboardPerformanceCpuTempBarColor !== undefined)
                    store.dashboardPerformanceCpuTempBarColor = String(cfg.dashboardPerformanceCpuTempBarColor);
                if (cfg.dashboardPerformanceGpuBackgroundFillColor !== undefined)
                    store.dashboardPerformanceGpuBackgroundFillColor = String(cfg.dashboardPerformanceGpuBackgroundFillColor);
                if (cfg.dashboardPerformanceGpuTempBarColor !== undefined)
                    store.dashboardPerformanceGpuTempBarColor = String(cfg.dashboardPerformanceGpuTempBarColor);
                if (cfg.dashboardPerformanceMemoryBarFillColor !== undefined)
                    store.dashboardPerformanceMemoryBarFillColor = String(cfg.dashboardPerformanceMemoryBarFillColor);
                if (cfg.dashboardPerformanceDiskBarFillColor !== undefined)
                    store.dashboardPerformanceDiskBarFillColor = String(cfg.dashboardPerformanceDiskBarFillColor);
                if (cfg.dashboardPerformanceBatteryFillColor !== undefined)
                    store.dashboardPerformanceBatteryFillColor = String(cfg.dashboardPerformanceBatteryFillColor);
                if (cfg.dashboardUpdatesPackageBarFillColor !== undefined)
                    store.dashboardUpdatesPackageBarFillColor = String(cfg.dashboardUpdatesPackageBarFillColor);
                if (cfg.dashboardUpdatesSecurityBarFillColor !== undefined)
                    store.dashboardUpdatesSecurityBarFillColor = String(cfg.dashboardUpdatesSecurityBarFillColor);
                if (cfg.dashboardUpdatesAURBarFillColor !== undefined)
                    store.dashboardUpdatesAURBarFillColor = String(cfg.dashboardUpdatesAURBarFillColor);
                if (cfg.dashboardUpdatesKernelBarFillColor !== undefined)
                    store.dashboardUpdatesKernelBarFillColor = String(cfg.dashboardUpdatesKernelBarFillColor);
                if (cfg.dashboardUpdatesSystemRadialFillColor !== undefined)
                    store.dashboardUpdatesSystemRadialFillColor = String(cfg.dashboardUpdatesSystemRadialFillColor);
                if (cfg.dashboardUpdatesPackageRadialFillColor !== undefined)
                    store.dashboardUpdatesPackageRadialFillColor = String(cfg.dashboardUpdatesPackageRadialFillColor);
                if (cfg.dashboardUpdatesSecurityRadialFillColor !== undefined)
                    store.dashboardUpdatesSecurityRadialFillColor = String(cfg.dashboardUpdatesSecurityRadialFillColor);
                if (cfg.dashboardUpdatesAURRadialFillColor !== undefined)
                    store.dashboardUpdatesAURRadialFillColor = String(cfg.dashboardUpdatesAURRadialFillColor);
                if (cfg.dashboardUpdatesKernelRadialFillColor !== undefined)
                    store.dashboardUpdatesKernelRadialFillColor = String(cfg.dashboardUpdatesKernelRadialFillColor);
                if (cfg.dashboardRounding !== undefined)
                    store.dashboardRounding = cfg.dashboardRounding;
                if (cfg.overlayAccentColor !== undefined)
                    store.overlayAccentColor = cfg.overlayAccentColor;
                if (cfg.overlayBackgroundColor !== undefined)
                    store.overlayBackgroundColor = String(cfg.overlayBackgroundColor);
                if (cfg.overlayTextColor !== undefined)
                    store.overlayTextColor = String(cfg.overlayTextColor);
                if (cfg.overlayDateColor !== undefined)
                    store.overlayDateColor = String(cfg.overlayDateColor);
                if (cfg.overlayDateFormat !== undefined)
                    store.overlayDateFormat = String(cfg.overlayDateFormat);
                if (cfg.overlayTimeFormat !== undefined)
                    store.overlayTimeFormat = String(cfg.overlayTimeFormat);
                if (cfg.overlayDateTimeFormat !== undefined)
                    store.overlayDateTimeFormat = String(cfg.overlayDateTimeFormat);
                if (cfg.buttonTextColor !== undefined)
                    store.buttonTextColor = String(cfg.buttonTextColor);
                if (cfg.buttonBorderColor !== undefined)
                    store.buttonBorderColor = String(cfg.buttonBorderColor);
                if (cfg.buttonBackgroundColor !== undefined)
                    store.buttonBackgroundColor = String(cfg.buttonBackgroundColor);
                if (cfg.buttonActiveTextColor !== undefined)
                    store.buttonActiveTextColor = String(cfg.buttonActiveTextColor);
                if (cfg.buttonActiveBorderColor !== undefined)
                    store.buttonActiveBorderColor = String(cfg.buttonActiveBorderColor);
                if (cfg.buttonActiveBackgroundColor !== undefined)
                    store.buttonActiveBackgroundColor = String(cfg.buttonActiveBackgroundColor);
                if (cfg.overlayBatteryBarColorCritical !== undefined)
                    store.overlayBatteryBarColorCritical = String(cfg.overlayBatteryBarColorCritical);
                if (cfg.overlayBatteryBarColorLow !== undefined)
                    store.overlayBatteryBarColorLow = String(cfg.overlayBatteryBarColorLow);
                if (cfg.overlayBatteryBarColorMedium !== undefined)
                    store.overlayBatteryBarColorMedium = String(cfg.overlayBatteryBarColorMedium);
                if (cfg.overlayBatteryBarColorHigh !== undefined)
                    store.overlayBatteryBarColorHigh = String(cfg.overlayBatteryBarColorHigh);
                if (cfg.overlayBatteryBarColorFull !== undefined)
                    store.overlayBatteryBarColorFull = String(cfg.overlayBatteryBarColorFull);
                if (cfg.overlayRounding !== undefined)
                    store.overlayRounding = cfg.overlayRounding;
                if (cfg.visualizationBackgroundColor !== undefined)
                    store.visualizationBackgroundColor = String(cfg.visualizationBackgroundColor);
                if (cfg.visualizationTextColor !== undefined)
                    store.visualizationTextColor = String(cfg.visualizationTextColor);
                if (cfg.visualizationBorderColor !== undefined)
                    store.visualizationBorderColor = String(cfg.visualizationBorderColor);
                if (cfg.workspaceVisualizationBackgroundColor !== undefined)
                    store.workspaceVisualizationBackgroundColor = String(cfg.workspaceVisualizationBackgroundColor);
                if (cfg.visualizationRounding !== undefined)
                    store.visualizationRounding = cfg.visualizationRounding;
                if (cfg.settingsAccentColor !== undefined)
                    store.settingsAccentColor = String(cfg.settingsAccentColor);
                if (cfg.settingsBackgroundColor !== undefined)
                    store.settingsBackgroundColor = String(cfg.settingsBackgroundColor);
                if (cfg.settingsTextColor !== undefined)
                    store.settingsTextColor = String(cfg.settingsTextColor);
                if (cfg.quickSettingsNotificationTextColor !== undefined)
                    store.quickSettingsNotificationTextColor = String(cfg.quickSettingsNotificationTextColor);
                if (cfg.quickSettingsNotificationBorderColor !== undefined)
                    store.quickSettingsNotificationBorderColor = String(cfg.quickSettingsNotificationBorderColor);
                if (cfg.quickSettingsNotificationBackgroundColor !== undefined)
                    store.quickSettingsNotificationBackgroundColor = String(cfg.quickSettingsNotificationBackgroundColor);
                if (cfg.quickSettingsNotificationPopupBackgroundColor !== undefined)
                    store.quickSettingsNotificationPopupBackgroundColor = String(cfg.quickSettingsNotificationPopupBackgroundColor);
                if (cfg.quickSettingsNotificationPopupBorderColor !== undefined)
                    store.quickSettingsNotificationPopupBorderColor = String(cfg.quickSettingsNotificationPopupBorderColor);
                if (cfg.quickSettingsNotificationPopupBorderWidth !== undefined)
                    store.quickSettingsNotificationPopupBorderWidth = Math.max(0, Number(cfg.quickSettingsNotificationPopupBorderWidth));
                if (cfg.quickSettingsNotificationPadding !== undefined)
                    store.quickSettingsNotificationPadding = Number(cfg.quickSettingsNotificationPadding);
                if (cfg.quickSettingsNotificationHeightBoost !== undefined)
                    store.quickSettingsNotificationHeightBoost = Math.max(0, Number(cfg.quickSettingsNotificationHeightBoost));
                if (cfg.quickSettingsActiveSettingTextColor !== undefined)
                    store.quickSettingsActiveSettingTextColor = String(cfg.quickSettingsActiveSettingTextColor);
                if (cfg.quickSettingsActiveSettingBorderColor !== undefined)
                    store.quickSettingsActiveSettingBorderColor = String(cfg.quickSettingsActiveSettingBorderColor);
                if (cfg.quickSettingsActiveSettingBackgroundColor !== undefined)
                    store.quickSettingsActiveSettingBackgroundColor = String(cfg.quickSettingsActiveSettingBackgroundColor);
                if (cfg.quickSettingsSettingTextColor !== undefined)
                    store.quickSettingsSettingTextColor = String(cfg.quickSettingsSettingTextColor);
                if (cfg.quickSettingsSettingBorderColor !== undefined)
                    store.quickSettingsSettingBorderColor = String(cfg.quickSettingsSettingBorderColor);
                if (cfg.quickSettingsSettingBackgroundColor !== undefined)
                    store.quickSettingsSettingBackgroundColor = String(cfg.quickSettingsSettingBackgroundColor);
                if (cfg.quickSettingsButtonHoverEffectColor !== undefined)
                    store.quickSettingsButtonHoverEffectColor = String(cfg.quickSettingsButtonHoverEffectColor);
                if (cfg.quickSettingsButtonActiveColor !== undefined)
                    store.quickSettingsButtonActiveColor = String(cfg.quickSettingsButtonActiveColor);
                if (cfg.quickSettingsButtonInactiveColor !== undefined)
                    store.quickSettingsButtonInactiveColor = String(cfg.quickSettingsButtonInactiveColor);
                if (cfg.settingsRounding !== undefined)
                    store.settingsRounding = cfg.settingsRounding;
                if (cfg.panelColor !== undefined)
                    store.panelColor = String(cfg.panelColor);
                if (cfg.mutedTextColor !== undefined)
                    store.mutedTextColor = String(cfg.mutedTextColor);
                if (cfg.wallpaperPath !== undefined)
                    store.wallpaperPath = String(cfg.wallpaperPath);
                if (cfg.activeThemeId !== undefined)
                    store.activeThemeId = String(cfg.activeThemeId);
                if (cfg.rounding !== undefined)
                    store.rounding = cfg.rounding;
                if (cfg.borderWidth !== undefined)
                    store.borderWidth = cfg.borderWidth;
                if (cfg.buttonBorderWidth !== undefined)
                    store.buttonBorderWidth = cfg.buttonBorderWidth;
                if (cfg.overlayBorderWidth !== undefined)
                    store.overlayBorderWidth = cfg.overlayBorderWidth;
                if (cfg.panelOpacity !== undefined)
                    store.panelOpacity = cfg.panelOpacity;
                if (cfg.overlayDimOpacity !== undefined)
                    store.overlayDimOpacity = cfg.overlayDimOpacity;
                if (cfg.fontFamily !== undefined)
                    store.fontFamily = cfg.fontFamily;
                if (cfg.fontPixelSize !== undefined)
                    store.fontPixelSize = cfg.fontPixelSize;
                if (cfg.sidebarEnabled !== undefined)
                    store.sidebarEnabled = cfg.sidebarEnabled;
                if (cfg.barOverlayVisibility !== undefined && typeof cfg.barOverlayVisibility === "object")
                    store.barOverlayVisibility = cfg.barOverlayVisibility;
                if (cfg.dashboardTabVisibility !== undefined && typeof cfg.dashboardTabVisibility === "object")
                    store.dashboardTabVisibility = cfg.dashboardTabVisibility;
                if (cfg.sidebarEdgeHoldMs !== undefined)
                    store.sidebarEdgeHoldMs = cfg.sidebarEdgeHoldMs;
                if (cfg.sidebarEdgeThresholdPx !== undefined)
                    store.sidebarEdgeThresholdPx = cfg.sidebarEdgeThresholdPx;
                if (cfg.hoverReleaseMs !== undefined)
                    store.hoverReleaseMs = cfg.hoverReleaseMs;
                if (cfg.sidebarSliderHeight !== undefined)
                    store.sidebarSliderHeight = cfg.sidebarSliderHeight;
                if (cfg.barWorkspacePollMs !== undefined)
                    store.barWorkspacePollMs = cfg.barWorkspacePollMs;
                if (cfg.barMediumPollMs !== undefined)
                    store.barMediumPollMs = cfg.barMediumPollMs;
                if (cfg.barSlowPollMs !== undefined)
                    store.barSlowPollMs = cfg.barSlowPollMs;
                if (cfg.quickSidebarPollMs !== undefined)
                    store.quickSidebarPollMs = cfg.quickSidebarPollMs;
                if (cfg.dashboardEnabled !== undefined)
                    store.dashboardEnabled = cfg.dashboardEnabled;
                if (cfg.dashboardRefreshMs !== undefined)
                    store.dashboardRefreshMs = cfg.dashboardRefreshMs;
                if (cfg.dashboardFastPollMs !== undefined)
                    store.dashboardFastPollMs = cfg.dashboardFastPollMs;
                else if (cfg.dashboardRefreshMs !== undefined)
                    store.dashboardFastPollMs = cfg.dashboardRefreshMs;
                if (cfg.dashboardMediumPollMs !== undefined)
                    store.dashboardMediumPollMs = cfg.dashboardMediumPollMs;
                else if (cfg.dashboardRefreshMs !== undefined)
                    store.dashboardMediumPollMs = Math.max(1000, cfg.dashboardRefreshMs * 2);
                if (cfg.dashboardSlowPollMs !== undefined)
                    store.dashboardSlowPollMs = cfg.dashboardSlowPollMs;
                else if (cfg.dashboardRefreshMs !== undefined)
                    store.dashboardSlowPollMs = Math.max(3000, cfg.dashboardRefreshMs * 4);
                if (cfg.showShellTitle !== undefined)
                    store.showShellTitle = cfg.showShellTitle;
                if (cfg.workspaceShowAllScreens !== undefined)
                    store.workspaceShowAllScreens = cfg.workspaceShowAllScreens;
                if (cfg.workspaceActiveScreenBackground !== undefined)
                    store.workspaceActiveScreenBackground = cfg.workspaceActiveScreenBackground;
                if (cfg.workspaceHighlightCurrent !== undefined)
                    store.workspaceHighlightCurrent = cfg.workspaceHighlightCurrent;
                if (cfg.workspaceShowWindowIcons !== undefined)
                    store.workspaceShowWindowIcons = cfg.workspaceShowWindowIcons;
                if (cfg.workspaceShowLayoutOnHover !== undefined)
                    store.workspaceShowLayoutOnHover = cfg.workspaceShowLayoutOnHover;
                if (cfg.workspaceSegmentVisible !== undefined)
                    store.workspaceSegmentVisible = cfg.workspaceSegmentVisible;
                if (cfg.workspaceVisibleCount !== undefined)
                    store.workspaceVisibleCount = cfg.workspaceVisibleCount;
                if (cfg.workspaceMaxIcons !== undefined)
                    store.workspaceMaxIcons = cfg.workspaceMaxIcons;
                if (cfg.uiTextStyle === "uppercase" || cfg.uiTextStyle === "standard")
                    store.uiTextStyle = cfg.uiTextStyle;
                if (cfg.controlCenterEnableHotkey !== undefined)
                    store.controlCenterEnableHotkey = cfg.controlCenterEnableHotkey;
                if (cfg.controlCenterHotkey !== undefined)
                    store.controlCenterHotkey = cfg.controlCenterHotkey;
                if (cfg.dashboardEnableHotkey !== undefined)
                    store.dashboardEnableHotkey = cfg.dashboardEnableHotkey;
                if (cfg.dashboardHotkey !== undefined)
                    store.dashboardHotkey = cfg.dashboardHotkey;
                if (cfg.sidebarEnableHotkey !== undefined)
                    store.sidebarEnableHotkey = cfg.sidebarEnableHotkey;
                if (cfg.sidebarHotkey !== undefined)
                    store.sidebarHotkey = cfg.sidebarHotkey;
                if (cfg.hyprlandManagedEnabled !== undefined)
                    store.hyprlandManagedEnabled = cfg.hyprlandManagedEnabled;
                if (cfg.hyprlandShowInfoMessage !== undefined)
                    store.hyprlandShowInfoMessage = cfg.hyprlandShowInfoMessage;
                if (cfg.hyprlandDisableSplash !== undefined)
                    store.hyprlandDisableSplash = cfg.hyprlandDisableSplash;
                if (cfg.hyprlandMonitors !== undefined && Array.isArray(cfg.hyprlandMonitors))
                    store.hyprlandMonitors = cfg.hyprlandMonitors;
                if (cfg.hyprlandDecoration !== undefined)
                    store.hyprlandDecoration = cfg.hyprlandDecoration;
                if (cfg.hyprlandBinds !== undefined && Array.isArray(cfg.hyprlandBinds))
                    store.hyprlandBinds = cfg.hyprlandBinds;
                if (cfg.hyprlandWorkspaceRules !== undefined && Array.isArray(cfg.hyprlandWorkspaceRules))
                    store.hyprlandWorkspaceRules = cfg.hyprlandWorkspaceRules;
                if (cfg.quickSettingsTiles !== undefined && Array.isArray(cfg.quickSettingsTiles))
                    store.quickSettingsTiles = cfg.quickSettingsTiles;
                config.barOverlayVisibility = root._deepCopy(store.barOverlayVisibility || root.defaultBarOverlayVisibility());
                config.dashboardTabVisibility = root._deepCopy(store.dashboardTabVisibility || root.defaultDashboardTabVisibility());
                config.hyprlandMonitors = root._deepCopy(store.hyprlandMonitors || []);
                config.hyprlandDecoration = root._deepCopy(store.hyprlandDecoration || {});
                config.hyprlandBinds = root._deepCopy(store.hyprlandBinds || []);
                config.hyprlandWorkspaceRules = root._deepCopy(store.hyprlandWorkspaceRules || []);
            } catch (e) {
                console.warn("settings.json parse failed:", e);
            }
            themeLibraryProc.exec({ command: themeLibraryProc.command });
            root.queueHyprlandSync();
        }

        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                root.saveStore();
            themeLibraryProc.exec({ command: themeLibraryProc.command });
            root.queueHyprlandSync();
        }
    }

    QtObject {
        id: config

        property string barOrientation: (store.barOrientation === "top" || store.barOrientation === "left") ? store.barOrientation : "top"
        property string themeMode: store.themeMode
        property color accentColor: store.accentColor
        property color borderColor: store.borderColor
        property color backgroundColor: store.backgroundColor
        property color workspaceColor: store.workspaceColor
        property color textColor: store.textColor
        property color barAccentColor: store.barAccentColor.length > 0 ? store.barAccentColor : accentColor
        property color barBackgroundColor: store.barBackgroundColor.length > 0 ? store.barBackgroundColor : panelColor
        property color barTextColor: store.barTextColor.length > 0 ? store.barTextColor : textColor
        property int barRounding: store.barRounding
        property color workspaceAccentColor: store.workspaceAccentColor
        property color workspaceBackgroundColor: store.workspaceBackgroundColor.length > 0 ? store.workspaceBackgroundColor : panelColor
        property color workspaceActiveTextColor: store.workspaceActiveTextColor.length > 0 ? store.workspaceActiveTextColor : workspaceColor
        property color workspaceActiveGroupBackgroundColor: store.workspaceActiveGroupBackgroundColor.length > 0 ? store.workspaceActiveGroupBackgroundColor : workspaceAccentColor
        property color workspaceActiveGroupBorderColor: store.workspaceActiveGroupBorderColor.length > 0 ? store.workspaceActiveGroupBorderColor : barAccentColor
        property color workspaceHighlightColor: store.workspaceHighlightColor.length > 0 ? store.workspaceHighlightColor : workspaceAccentColor
        property int workspaceRounding: store.workspaceRounding
        property color volumeColor: store.volumeColor
        property color quickSidebarColor: store.quickSidebarColor
        property color sidebarBackgroundColor: store.sidebarBackgroundColor.length > 0 ? store.sidebarBackgroundColor : panelColor
        property color sidebarTextColor: store.sidebarTextColor.length > 0 ? store.sidebarTextColor : textColor
        property int sidebarRounding: store.sidebarRounding
        property color dashboardColor: store.dashboardColor
        property color dashboardBackgroundColor: store.dashboardBackgroundColor.length > 0 ? store.dashboardBackgroundColor : panelColor
        property color dashboardTextColor: store.dashboardTextColor.length > 0 ? store.dashboardTextColor : textColor
        property color dashboardWeatherAccentColor: store.dashboardWeatherAccentColor.length > 0 ? store.dashboardWeatherAccentColor : dashboardColor
        property color dashboardWeatherTextColor: store.dashboardWeatherTextColor.length > 0 ? store.dashboardWeatherTextColor : dashboardTextColor
        property color dashboardWeatherIconColor: store.dashboardWeatherIconColor.length > 0 ? store.dashboardWeatherIconColor : dashboardWeatherAccentColor
        property color dashboardWeatherIconBackgroundColor: store.dashboardWeatherIconBackgroundColor.length > 0 ? store.dashboardWeatherIconBackgroundColor : dashboardBackgroundColor
        property color dashboardSystemAccentColor: store.dashboardSystemAccentColor.length > 0 ? store.dashboardSystemAccentColor : dashboardColor
        property color dashboardClockHourColor: store.dashboardClockHourColor.length > 0 ? store.dashboardClockHourColor : dashboardColor
        property color dashboardClockMinuteColor: store.dashboardClockMinuteColor.length > 0 ? store.dashboardClockMinuteColor : dashboardTextColor
        property color dashboardClockSecondColor: store.dashboardClockSecondColor.length > 0 ? store.dashboardClockSecondColor : mutedTextColor
        property color dashboardClockSecondsTimerColor: store.dashboardClockSecondsTimerColor.length > 0 ? store.dashboardClockSecondsTimerColor : dashboardClockSecondColor
        property color dashboardCalendarWeekendColor: store.dashboardCalendarWeekendColor.length > 0 ? store.dashboardCalendarWeekendColor : dashboardColor
        property color dashboardCalendarActiveColor: store.dashboardCalendarActiveColor.length > 0 ? store.dashboardCalendarActiveColor : dashboardColor
        property color dashboardCalendarCurrentDayColor: store.dashboardCalendarCurrentDayColor.length > 0 ? store.dashboardCalendarCurrentDayColor : dashboardCalendarActiveColor
        property color dashboardUsageBarBackgroundColor: store.dashboardUsageBarBackgroundColor.length > 0 ? store.dashboardUsageBarBackgroundColor : mutedTextColor
        property color dashboardWifiDownColor: store.dashboardWifiDownColor.length > 0 ? store.dashboardWifiDownColor : dashboardColor
        property color dashboardWifiUpColor: store.dashboardWifiUpColor.length > 0 ? store.dashboardWifiUpColor : "#22c55e"
        property color dashboardBatteryPerformanceColor: store.dashboardBatteryPerformanceColor.length > 0 ? store.dashboardBatteryPerformanceColor : dashboardColor
        property color dashboardRamUsageColor: store.dashboardRamUsageColor.length > 0 ? store.dashboardRamUsageColor : textColor
        property color dashboardDiskUsageColor: store.dashboardDiskUsageColor.length > 0 ? store.dashboardDiskUsageColor : mutedTextColor
        property color dashboardCpuColor: store.dashboardCpuColor.length > 0 ? store.dashboardCpuColor : dashboardColor
        property color dashboardGpuColor: store.dashboardGpuColor.length > 0 ? store.dashboardGpuColor : dashboardColor
        property color dashboardCpuBarColor: store.dashboardCpuBarColor.length > 0 ? store.dashboardCpuBarColor : dashboardCpuColor
        property color dashboardRamBarColor: store.dashboardRamBarColor.length > 0 ? store.dashboardRamBarColor : dashboardRamUsageColor
        property color dashboardDiskBarColor: store.dashboardDiskBarColor.length > 0 ? store.dashboardDiskBarColor : dashboardDiskUsageColor
        property color dashboardMediaControlsColor: store.dashboardMediaControlsColor.length > 0 ? store.dashboardMediaControlsColor : dashboardColor
        property color dashboardMediaDurationBarColor: store.dashboardMediaDurationBarColor.length > 0 ? store.dashboardMediaDurationBarColor : dashboardColor
        property color dashboardPerformanceCpuBackgroundFillColor: store.dashboardPerformanceCpuBackgroundFillColor.length > 0 ? store.dashboardPerformanceCpuBackgroundFillColor : dashboardUsageBarBackgroundColor
        property color dashboardPerformanceCpuTempBarColor: store.dashboardPerformanceCpuTempBarColor.length > 0 ? store.dashboardPerformanceCpuTempBarColor : dashboardCpuColor
        property color dashboardPerformanceGpuBackgroundFillColor: store.dashboardPerformanceGpuBackgroundFillColor.length > 0 ? store.dashboardPerformanceGpuBackgroundFillColor : dashboardUsageBarBackgroundColor
        property color dashboardPerformanceGpuTempBarColor: store.dashboardPerformanceGpuTempBarColor.length > 0 ? store.dashboardPerformanceGpuTempBarColor : dashboardGpuColor
        property color dashboardPerformanceMemoryBarFillColor: store.dashboardPerformanceMemoryBarFillColor.length > 0 ? store.dashboardPerformanceMemoryBarFillColor : dashboardRamUsageColor
        property color dashboardPerformanceDiskBarFillColor: store.dashboardPerformanceDiskBarFillColor.length > 0 ? store.dashboardPerformanceDiskBarFillColor : dashboardDiskUsageColor
        property color dashboardPerformanceBatteryFillColor: store.dashboardPerformanceBatteryFillColor.length > 0 ? store.dashboardPerformanceBatteryFillColor : dashboardBatteryPerformanceColor
        property color dashboardUpdatesPackageBarFillColor: store.dashboardUpdatesPackageBarFillColor.length > 0 ? store.dashboardUpdatesPackageBarFillColor : dashboardCpuColor
        property color dashboardUpdatesSecurityBarFillColor: store.dashboardUpdatesSecurityBarFillColor.length > 0 ? store.dashboardUpdatesSecurityBarFillColor : dashboardWifiUpColor
        property color dashboardUpdatesAURBarFillColor: store.dashboardUpdatesAURBarFillColor.length > 0 ? store.dashboardUpdatesAURBarFillColor : dashboardWifiUpColor
        property color dashboardUpdatesKernelBarFillColor: store.dashboardUpdatesKernelBarFillColor.length > 0 ? store.dashboardUpdatesKernelBarFillColor : dashboardCpuColor
        property color dashboardUpdatesSystemRadialFillColor: store.dashboardUpdatesSystemRadialFillColor.length > 0 ? store.dashboardUpdatesSystemRadialFillColor : dashboardTextColor
        property color dashboardUpdatesPackageRadialFillColor: store.dashboardUpdatesPackageRadialFillColor.length > 0 ? store.dashboardUpdatesPackageRadialFillColor : dashboardTextColor
        property color dashboardUpdatesSecurityRadialFillColor: store.dashboardUpdatesSecurityRadialFillColor.length > 0 ? store.dashboardUpdatesSecurityRadialFillColor : dashboardTextColor
        property color dashboardUpdatesAURRadialFillColor: store.dashboardUpdatesAURRadialFillColor.length > 0 ? store.dashboardUpdatesAURRadialFillColor : dashboardTextColor
        property color dashboardUpdatesKernelRadialFillColor: store.dashboardUpdatesKernelRadialFillColor.length > 0 ? store.dashboardUpdatesKernelRadialFillColor : dashboardTextColor
        property int dashboardRounding: store.dashboardRounding
        property color overlayAccentColor: store.overlayAccentColor
        property color overlayBackgroundColor: store.overlayBackgroundColor.length > 0 ? store.overlayBackgroundColor : panelColor
        property color overlayTextColor: store.overlayTextColor.length > 0 ? store.overlayTextColor : textColor
        property color overlayDateColor: store.overlayDateColor.length > 0 ? store.overlayDateColor : overlayTextColor
        property string overlayDateFormat: store.overlayDateFormat.length > 0 ? store.overlayDateFormat : "%a %d %b"
        property string overlayTimeFormat: store.overlayTimeFormat.length > 0 ? store.overlayTimeFormat : "%H:%M"
        property string overlayDateTimeFormat: store.overlayDateTimeFormat.length > 0 ? store.overlayDateTimeFormat : "date-time"
        property color buttonTextColor: store.buttonTextColor.length > 0 ? store.buttonTextColor : overlayTextColor
        property color buttonBorderColor: store.buttonBorderColor.length > 0 ? store.buttonBorderColor : mutedTextColor
        property color buttonBackgroundColor: store.buttonBackgroundColor.length > 0 ? store.buttonBackgroundColor : "transparent"
        property color buttonActiveTextColor: store.buttonActiveTextColor.length > 0 ? store.buttonActiveTextColor : overlayAccentColor
        property color buttonActiveBorderColor: store.buttonActiveBorderColor.length > 0 ? store.buttonActiveBorderColor : overlayAccentColor
        property color buttonActiveBackgroundColor: store.buttonActiveBackgroundColor.length > 0 ? store.buttonActiveBackgroundColor : "transparent"
        property color overlayBatteryBarColorCritical: store.overlayBatteryBarColorCritical.length > 0 ? store.overlayBatteryBarColorCritical : "#ef4444"
        property color overlayBatteryBarColorLow: store.overlayBatteryBarColorLow.length > 0 ? store.overlayBatteryBarColorLow : "#f59e0b"
        property color overlayBatteryBarColorMedium: store.overlayBatteryBarColorMedium.length > 0 ? store.overlayBatteryBarColorMedium : overlayAccentColor
        property color overlayBatteryBarColorHigh: store.overlayBatteryBarColorHigh.length > 0 ? store.overlayBatteryBarColorHigh : overlayTextColor
        property color overlayBatteryBarColorFull: store.overlayBatteryBarColorFull.length > 0 ? store.overlayBatteryBarColorFull : overlayAccentColor
        property int overlayRounding: store.overlayRounding
        property color visualizationBackgroundColor: store.visualizationBackgroundColor.length > 0 ? store.visualizationBackgroundColor : panelColor
        property color visualizationTextColor: store.visualizationTextColor.length > 0 ? store.visualizationTextColor : textColor
        property color visualizationBorderColor: store.visualizationBorderColor.length > 0 ? store.visualizationBorderColor : volumeColor
        property color workspaceVisualizationBackgroundColor: store.workspaceVisualizationBackgroundColor.length > 0 ? store.workspaceVisualizationBackgroundColor : visualizationBackgroundColor
        property int visualizationRounding: store.visualizationRounding
        property color settingsAccentColor: store.settingsAccentColor.length > 0 ? store.settingsAccentColor : accentColor
        property color settingsBackgroundColor: store.settingsBackgroundColor.length > 0 ? store.settingsBackgroundColor : panelColor
        property color settingsTextColor: store.settingsTextColor.length > 0 ? store.settingsTextColor : textColor
        property color quickSettingsNotificationTextColor: store.quickSettingsNotificationTextColor.length > 0 ? store.quickSettingsNotificationTextColor : settingsTextColor
        property color quickSettingsNotificationBorderColor: store.quickSettingsNotificationBorderColor.length > 0 ? store.quickSettingsNotificationBorderColor : mutedTextColor
        property color quickSettingsNotificationBackgroundColor: store.quickSettingsNotificationBackgroundColor.length > 0 ? store.quickSettingsNotificationBackgroundColor : "transparent"
        property color quickSettingsNotificationPopupBackgroundColor: store.quickSettingsNotificationPopupBackgroundColor.length > 0 ? store.quickSettingsNotificationPopupBackgroundColor : overlayBackgroundColor
        property color quickSettingsNotificationPopupBorderColor: store.quickSettingsNotificationPopupBorderColor.length > 0 ? store.quickSettingsNotificationPopupBorderColor : overlayAccentColor
        property int quickSettingsNotificationPopupBorderWidth: Number.isFinite(store.quickSettingsNotificationPopupBorderWidth) ? Math.max(0, Math.round(store.quickSettingsNotificationPopupBorderWidth)) : Math.max(0, overlayBorderWidth)
        property int quickSettingsNotificationPadding: Number.isFinite(store.quickSettingsNotificationPadding) ? Math.max(0, Math.round(store.quickSettingsNotificationPadding)) : 8
        property int quickSettingsNotificationHeightBoost: Number.isFinite(store.quickSettingsNotificationHeightBoost) ? Math.max(0, Math.round(store.quickSettingsNotificationHeightBoost)) : 18
        property color quickSettingsActiveSettingTextColor: store.quickSettingsActiveSettingTextColor.length > 0 ? store.quickSettingsActiveSettingTextColor : settingsAccentColor
        property color quickSettingsActiveSettingBorderColor: store.quickSettingsActiveSettingBorderColor.length > 0 ? store.quickSettingsActiveSettingBorderColor : settingsAccentColor
        property color quickSettingsActiveSettingBackgroundColor: store.quickSettingsActiveSettingBackgroundColor.length > 0 ? store.quickSettingsActiveSettingBackgroundColor : "transparent"
        property color quickSettingsSettingTextColor: store.quickSettingsSettingTextColor.length > 0 ? store.quickSettingsSettingTextColor : settingsTextColor
        property color quickSettingsSettingBorderColor: store.quickSettingsSettingBorderColor.length > 0 ? store.quickSettingsSettingBorderColor : mutedTextColor
        property color quickSettingsSettingBackgroundColor: store.quickSettingsSettingBackgroundColor.length > 0 ? store.quickSettingsSettingBackgroundColor : "transparent"
        property color quickSettingsButtonHoverEffectColor: store.quickSettingsButtonHoverEffectColor.length > 0 ? store.quickSettingsButtonHoverEffectColor : settingsAccentColor
        property color quickSettingsButtonActiveColor: store.quickSettingsButtonActiveColor.length > 0 ? store.quickSettingsButtonActiveColor : quickSettingsActiveSettingBackgroundColor
        property color quickSettingsButtonInactiveColor: store.quickSettingsButtonInactiveColor.length > 0 ? store.quickSettingsButtonInactiveColor : quickSettingsSettingBackgroundColor
        property int settingsRounding: store.settingsRounding
        property var themeLibrary: []
        property string activeThemeId: store.activeThemeId
        property int rounding: store.rounding
        property int borderWidth: store.borderWidth
        property int buttonBorderWidth: store.buttonBorderWidth
        property int overlayBorderWidth: store.overlayBorderWidth
        property real panelOpacity: store.panelOpacity
        property real overlayDimOpacity: store.overlayDimOpacity
        property string fontFamily: store.fontFamily
        property int fontPixelSize: store.fontPixelSize
        readonly property color bgColor: backgroundColor
        readonly property color panelColor: store.panelColor.length > 0 ? store.panelColor : backgroundColor
        readonly property color mutedTextColor: store.mutedTextColor.length > 0
            ? store.mutedTextColor
            : (themeMode === "light" ? "#52525b" : "#a1a1aa")
        readonly property string wallpaperPath: store.wallpaperPath
        property bool sidebarEnabled: store.sidebarEnabled
        property var barOverlayVisibility: root._deepCopy(store.barOverlayVisibility || root.defaultBarOverlayVisibility())
        property var dashboardTabVisibility: root._deepCopy(store.dashboardTabVisibility || root.defaultDashboardTabVisibility())
        property int sidebarEdgeHoldMs: store.sidebarEdgeHoldMs
        property int sidebarEdgeThresholdPx: store.sidebarEdgeThresholdPx
        property int hoverReleaseMs: store.hoverReleaseMs
        property int sidebarSliderHeight: store.sidebarSliderHeight
        property int barWorkspacePollMs: store.barWorkspacePollMs
        property int barMediumPollMs: store.barMediumPollMs
        property int barSlowPollMs: store.barSlowPollMs
        property int quickSidebarPollMs: store.quickSidebarPollMs
        property bool dashboardEnabled: store.dashboardEnabled
        property int dashboardRefreshMs: store.dashboardRefreshMs
        property int dashboardFastPollMs: store.dashboardFastPollMs
        property int dashboardMediumPollMs: store.dashboardMediumPollMs
        property int dashboardSlowPollMs: store.dashboardSlowPollMs
        property bool showShellTitle: store.showShellTitle
        property bool workspaceShowAllScreens: store.workspaceShowAllScreens
        property bool workspaceActiveScreenBackground: store.workspaceActiveScreenBackground
        property bool workspaceHighlightCurrent: store.workspaceHighlightCurrent
        property bool workspaceShowWindowIcons: store.workspaceShowWindowIcons
        property bool workspaceShowLayoutOnHover: store.workspaceShowLayoutOnHover
        property bool workspaceSegmentVisible: store.workspaceSegmentVisible
        property int workspaceVisibleCount: Math.max(1, Number(store.workspaceVisibleCount) || 8)
        property int workspaceMaxIcons: Math.max(0, Number(store.workspaceMaxIcons) || 1)
        property string uiTextStyle: (store.uiTextStyle === "uppercase") ? "uppercase" : "standard"
        property bool controlCenterEnableHotkey: store.controlCenterEnableHotkey
        property string controlCenterHotkey: store.controlCenterHotkey
        property bool dashboardEnableHotkey: store.dashboardEnableHotkey
        property string dashboardHotkey: store.dashboardHotkey
        property bool sidebarEnableHotkey: store.sidebarEnableHotkey
        property string sidebarHotkey: store.sidebarHotkey
        property bool hyprlandManagedEnabled: store.hyprlandManagedEnabled
        property bool hyprlandShowInfoMessage: store.hyprlandShowInfoMessage
        property bool hyprlandDisableSplash: store.hyprlandDisableSplash
        property var hyprlandMonitors: []
        property var hyprlandDecoration: ({})
        property var hyprlandBinds: []
        property var hyprlandWorkspaceRules: []
        property var quickSettingsTiles: root.defaultQuickSettingsTiles()

        function formatUiText(s) {
            if (s === undefined || s === null)
                return "";
            const st = String(s);
            // Use config's own uiTextStyle (root.store is not reliably in scope here).
            if (String(config.uiTextStyle) === "uppercase")
                return st.toLocaleUpperCase();
            return st;
        }

        onBarOrientationChanged: { store.barOrientation = barOrientation; root.queueStoreSave(); }
        onThemeModeChanged: { store.themeMode = themeMode; root.queueStoreSave(); }
        onAccentColorChanged: { store.accentColor = accentColor; root.queueStoreSave(); }
        onBorderColorChanged: { store.borderColor = borderColor; root.queueStoreSave(); }
        onBackgroundColorChanged: { store.backgroundColor = backgroundColor; root.queueStoreSave(); }
        onWorkspaceColorChanged: { store.workspaceColor = workspaceColor; root.queueStoreSave(); }
        onTextColorChanged: { store.textColor = textColor; root.queueStoreSave(); }
        onBarAccentColorChanged: { store.barAccentColor = String(barAccentColor); root.queueStoreSave(); }
        onBarBackgroundColorChanged: { store.barBackgroundColor = String(barBackgroundColor); root.queueStoreSave(); }
        onBarTextColorChanged: { store.barTextColor = String(barTextColor); root.queueStoreSave(); }
        onBarRoundingChanged: { store.barRounding = barRounding; root.queueStoreSave(); }
        onWorkspaceAccentColorChanged: { store.workspaceAccentColor = workspaceAccentColor; root.queueStoreSave(); }
        onWorkspaceBackgroundColorChanged: { store.workspaceBackgroundColor = String(workspaceBackgroundColor); root.queueStoreSave(); }
        onWorkspaceActiveTextColorChanged: { store.workspaceActiveTextColor = String(workspaceActiveTextColor); root.queueStoreSave(); }
        onWorkspaceActiveGroupBackgroundColorChanged: { store.workspaceActiveGroupBackgroundColor = String(workspaceActiveGroupBackgroundColor); root.queueStoreSave(); }
        onWorkspaceActiveGroupBorderColorChanged: { store.workspaceActiveGroupBorderColor = String(workspaceActiveGroupBorderColor); root.queueStoreSave(); }
        onWorkspaceHighlightColorChanged: { store.workspaceHighlightColor = String(workspaceHighlightColor); root.queueStoreSave(); }
        onWorkspaceRoundingChanged: { store.workspaceRounding = workspaceRounding; root.queueStoreSave(); }
        onVolumeColorChanged: { store.volumeColor = volumeColor; root.queueStoreSave(); }
        onQuickSidebarColorChanged: { store.quickSidebarColor = quickSidebarColor; root.queueStoreSave(); }
        onSidebarBackgroundColorChanged: { store.sidebarBackgroundColor = String(sidebarBackgroundColor); root.queueStoreSave(); }
        onSidebarTextColorChanged: { store.sidebarTextColor = String(sidebarTextColor); root.queueStoreSave(); }
        onSidebarRoundingChanged: { store.sidebarRounding = sidebarRounding; root.queueStoreSave(); }
        onDashboardColorChanged: { store.dashboardColor = dashboardColor; root.queueStoreSave(); }
        onDashboardBackgroundColorChanged: { store.dashboardBackgroundColor = String(dashboardBackgroundColor); root.queueStoreSave(); }
        onDashboardTextColorChanged: { store.dashboardTextColor = String(dashboardTextColor); root.queueStoreSave(); }
        onDashboardWeatherAccentColorChanged: { store.dashboardWeatherAccentColor = String(dashboardWeatherAccentColor); root.queueStoreSave(); }
        onDashboardWeatherTextColorChanged: { store.dashboardWeatherTextColor = String(dashboardWeatherTextColor); root.queueStoreSave(); }
        onDashboardWeatherIconColorChanged: { store.dashboardWeatherIconColor = String(dashboardWeatherIconColor); root.queueStoreSave(); }
        onDashboardWeatherIconBackgroundColorChanged: { store.dashboardWeatherIconBackgroundColor = String(dashboardWeatherIconBackgroundColor); root.queueStoreSave(); }
        onDashboardSystemAccentColorChanged: { store.dashboardSystemAccentColor = String(dashboardSystemAccentColor); root.queueStoreSave(); }
        onDashboardClockHourColorChanged: { store.dashboardClockHourColor = String(dashboardClockHourColor); root.queueStoreSave(); }
        onDashboardClockMinuteColorChanged: { store.dashboardClockMinuteColor = String(dashboardClockMinuteColor); root.queueStoreSave(); }
        onDashboardClockSecondColorChanged: { store.dashboardClockSecondColor = String(dashboardClockSecondColor); root.queueStoreSave(); }
        onDashboardClockSecondsTimerColorChanged: { store.dashboardClockSecondsTimerColor = String(dashboardClockSecondsTimerColor); root.queueStoreSave(); }
        onDashboardCalendarWeekendColorChanged: { store.dashboardCalendarWeekendColor = String(dashboardCalendarWeekendColor); root.queueStoreSave(); }
        onDashboardCalendarActiveColorChanged: { store.dashboardCalendarActiveColor = String(dashboardCalendarActiveColor); root.queueStoreSave(); }
        onDashboardCalendarCurrentDayColorChanged: { store.dashboardCalendarCurrentDayColor = String(dashboardCalendarCurrentDayColor); root.queueStoreSave(); }
        onDashboardUsageBarBackgroundColorChanged: { store.dashboardUsageBarBackgroundColor = String(dashboardUsageBarBackgroundColor); root.queueStoreSave(); }
        onDashboardWifiDownColorChanged: { store.dashboardWifiDownColor = String(dashboardWifiDownColor); root.queueStoreSave(); }
        onDashboardWifiUpColorChanged: { store.dashboardWifiUpColor = String(dashboardWifiUpColor); root.queueStoreSave(); }
        onDashboardBatteryPerformanceColorChanged: { store.dashboardBatteryPerformanceColor = String(dashboardBatteryPerformanceColor); root.queueStoreSave(); }
        onDashboardRamUsageColorChanged: { store.dashboardRamUsageColor = String(dashboardRamUsageColor); root.queueStoreSave(); }
        onDashboardDiskUsageColorChanged: { store.dashboardDiskUsageColor = String(dashboardDiskUsageColor); root.queueStoreSave(); }
        onDashboardCpuColorChanged: { store.dashboardCpuColor = String(dashboardCpuColor); root.queueStoreSave(); }
        onDashboardGpuColorChanged: { store.dashboardGpuColor = String(dashboardGpuColor); root.queueStoreSave(); }
        onDashboardCpuBarColorChanged: { store.dashboardCpuBarColor = String(dashboardCpuBarColor); root.queueStoreSave(); }
        onDashboardRamBarColorChanged: { store.dashboardRamBarColor = String(dashboardRamBarColor); root.queueStoreSave(); }
        onDashboardDiskBarColorChanged: { store.dashboardDiskBarColor = String(dashboardDiskBarColor); root.queueStoreSave(); }
        onDashboardMediaControlsColorChanged: { store.dashboardMediaControlsColor = String(dashboardMediaControlsColor); root.queueStoreSave(); }
        onDashboardMediaDurationBarColorChanged: { store.dashboardMediaDurationBarColor = String(dashboardMediaDurationBarColor); root.queueStoreSave(); }
        onDashboardPerformanceCpuBackgroundFillColorChanged: { store.dashboardPerformanceCpuBackgroundFillColor = String(dashboardPerformanceCpuBackgroundFillColor); root.queueStoreSave(); }
        onDashboardPerformanceCpuTempBarColorChanged: { store.dashboardPerformanceCpuTempBarColor = String(dashboardPerformanceCpuTempBarColor); root.queueStoreSave(); }
        onDashboardPerformanceGpuBackgroundFillColorChanged: { store.dashboardPerformanceGpuBackgroundFillColor = String(dashboardPerformanceGpuBackgroundFillColor); root.queueStoreSave(); }
        onDashboardPerformanceGpuTempBarColorChanged: { store.dashboardPerformanceGpuTempBarColor = String(dashboardPerformanceGpuTempBarColor); root.queueStoreSave(); }
        onDashboardPerformanceMemoryBarFillColorChanged: { store.dashboardPerformanceMemoryBarFillColor = String(dashboardPerformanceMemoryBarFillColor); root.queueStoreSave(); }
        onDashboardPerformanceDiskBarFillColorChanged: { store.dashboardPerformanceDiskBarFillColor = String(dashboardPerformanceDiskBarFillColor); root.queueStoreSave(); }
        onDashboardPerformanceBatteryFillColorChanged: { store.dashboardPerformanceBatteryFillColor = String(dashboardPerformanceBatteryFillColor); root.queueStoreSave(); }
        onDashboardUpdatesPackageBarFillColorChanged: { store.dashboardUpdatesPackageBarFillColor = String(dashboardUpdatesPackageBarFillColor); root.queueStoreSave(); }
        onDashboardUpdatesSecurityBarFillColorChanged: { store.dashboardUpdatesSecurityBarFillColor = String(dashboardUpdatesSecurityBarFillColor); root.queueStoreSave(); }
        onDashboardUpdatesAURBarFillColorChanged: { store.dashboardUpdatesAURBarFillColor = String(dashboardUpdatesAURBarFillColor); root.queueStoreSave(); }
        onDashboardUpdatesKernelBarFillColorChanged: { store.dashboardUpdatesKernelBarFillColor = String(dashboardUpdatesKernelBarFillColor); root.queueStoreSave(); }
        onDashboardUpdatesSystemRadialFillColorChanged: { store.dashboardUpdatesSystemRadialFillColor = String(dashboardUpdatesSystemRadialFillColor); root.queueStoreSave(); }
        onDashboardUpdatesPackageRadialFillColorChanged: { store.dashboardUpdatesPackageRadialFillColor = String(dashboardUpdatesPackageRadialFillColor); root.queueStoreSave(); }
        onDashboardUpdatesSecurityRadialFillColorChanged: { store.dashboardUpdatesSecurityRadialFillColor = String(dashboardUpdatesSecurityRadialFillColor); root.queueStoreSave(); }
        onDashboardUpdatesAURRadialFillColorChanged: { store.dashboardUpdatesAURRadialFillColor = String(dashboardUpdatesAURRadialFillColor); root.queueStoreSave(); }
        onDashboardUpdatesKernelRadialFillColorChanged: { store.dashboardUpdatesKernelRadialFillColor = String(dashboardUpdatesKernelRadialFillColor); root.queueStoreSave(); }
        onDashboardRoundingChanged: { store.dashboardRounding = dashboardRounding; root.queueStoreSave(); }
        onOverlayAccentColorChanged: { store.overlayAccentColor = overlayAccentColor; root.queueStoreSave(); }
        onOverlayBackgroundColorChanged: { store.overlayBackgroundColor = String(overlayBackgroundColor); root.queueStoreSave(); }
        onOverlayTextColorChanged: { store.overlayTextColor = String(overlayTextColor); root.queueStoreSave(); }
        onOverlayDateColorChanged: { store.overlayDateColor = String(overlayDateColor); root.queueStoreSave(); }
        onOverlayDateFormatChanged: { store.overlayDateFormat = String(overlayDateFormat); root.queueStoreSave(); }
        onOverlayTimeFormatChanged: { store.overlayTimeFormat = String(overlayTimeFormat); root.queueStoreSave(); }
        onOverlayDateTimeFormatChanged: { store.overlayDateTimeFormat = String(overlayDateTimeFormat); root.queueStoreSave(); }
        onButtonTextColorChanged: { store.buttonTextColor = String(buttonTextColor); root.queueStoreSave(); }
        onButtonBorderColorChanged: { store.buttonBorderColor = String(buttonBorderColor); root.queueStoreSave(); }
        onButtonBackgroundColorChanged: { store.buttonBackgroundColor = String(buttonBackgroundColor); root.queueStoreSave(); }
        onButtonActiveTextColorChanged: { store.buttonActiveTextColor = String(buttonActiveTextColor); root.queueStoreSave(); }
        onButtonActiveBorderColorChanged: { store.buttonActiveBorderColor = String(buttonActiveBorderColor); root.queueStoreSave(); }
        onButtonActiveBackgroundColorChanged: { store.buttonActiveBackgroundColor = String(buttonActiveBackgroundColor); root.queueStoreSave(); }
        onOverlayBatteryBarColorCriticalChanged: { store.overlayBatteryBarColorCritical = String(overlayBatteryBarColorCritical); root.queueStoreSave(); }
        onOverlayBatteryBarColorLowChanged: { store.overlayBatteryBarColorLow = String(overlayBatteryBarColorLow); root.queueStoreSave(); }
        onOverlayBatteryBarColorMediumChanged: { store.overlayBatteryBarColorMedium = String(overlayBatteryBarColorMedium); root.queueStoreSave(); }
        onOverlayBatteryBarColorHighChanged: { store.overlayBatteryBarColorHigh = String(overlayBatteryBarColorHigh); root.queueStoreSave(); }
        onOverlayBatteryBarColorFullChanged: { store.overlayBatteryBarColorFull = String(overlayBatteryBarColorFull); root.queueStoreSave(); }
        onOverlayRoundingChanged: { store.overlayRounding = overlayRounding; root.queueStoreSave(); }
        onVisualizationBackgroundColorChanged: { store.visualizationBackgroundColor = String(visualizationBackgroundColor); root.queueStoreSave(); }
        onVisualizationTextColorChanged: { store.visualizationTextColor = String(visualizationTextColor); root.queueStoreSave(); }
        onVisualizationBorderColorChanged: { store.visualizationBorderColor = String(visualizationBorderColor); root.queueStoreSave(); }
        onWorkspaceVisualizationBackgroundColorChanged: { store.workspaceVisualizationBackgroundColor = String(workspaceVisualizationBackgroundColor); root.queueStoreSave(); }
        onVisualizationRoundingChanged: { store.visualizationRounding = visualizationRounding; root.queueStoreSave(); }
        onSettingsAccentColorChanged: { store.settingsAccentColor = String(settingsAccentColor); root.queueStoreSave(); }
        onSettingsBackgroundColorChanged: { store.settingsBackgroundColor = String(settingsBackgroundColor); root.queueStoreSave(); }
        onSettingsTextColorChanged: { store.settingsTextColor = String(settingsTextColor); root.queueStoreSave(); }
        onQuickSettingsNotificationTextColorChanged: { store.quickSettingsNotificationTextColor = String(quickSettingsNotificationTextColor); root.queueStoreSave(); }
        onQuickSettingsNotificationBorderColorChanged: { store.quickSettingsNotificationBorderColor = String(quickSettingsNotificationBorderColor); root.queueStoreSave(); }
        onQuickSettingsNotificationBackgroundColorChanged: { store.quickSettingsNotificationBackgroundColor = String(quickSettingsNotificationBackgroundColor); root.queueStoreSave(); }
        onQuickSettingsNotificationPaddingChanged: { store.quickSettingsNotificationPadding = quickSettingsNotificationPadding; root.queueStoreSave(); }
        onQuickSettingsActiveSettingTextColorChanged: { store.quickSettingsActiveSettingTextColor = String(quickSettingsActiveSettingTextColor); root.queueStoreSave(); }
        onQuickSettingsActiveSettingBorderColorChanged: { store.quickSettingsActiveSettingBorderColor = String(quickSettingsActiveSettingBorderColor); root.queueStoreSave(); }
        onQuickSettingsActiveSettingBackgroundColorChanged: { store.quickSettingsActiveSettingBackgroundColor = String(quickSettingsActiveSettingBackgroundColor); root.queueStoreSave(); }
        onQuickSettingsSettingTextColorChanged: { store.quickSettingsSettingTextColor = String(quickSettingsSettingTextColor); root.queueStoreSave(); }
        onQuickSettingsSettingBorderColorChanged: { store.quickSettingsSettingBorderColor = String(quickSettingsSettingBorderColor); root.queueStoreSave(); }
        onQuickSettingsSettingBackgroundColorChanged: { store.quickSettingsSettingBackgroundColor = String(quickSettingsSettingBackgroundColor); root.queueStoreSave(); }
        onQuickSettingsButtonHoverEffectColorChanged: { store.quickSettingsButtonHoverEffectColor = String(quickSettingsButtonHoverEffectColor); root.queueStoreSave(); }
        onQuickSettingsButtonActiveColorChanged: { store.quickSettingsButtonActiveColor = String(quickSettingsButtonActiveColor); root.queueStoreSave(); }
        onQuickSettingsButtonInactiveColorChanged: { store.quickSettingsButtonInactiveColor = String(quickSettingsButtonInactiveColor); root.queueStoreSave(); }
        onSettingsRoundingChanged: { store.settingsRounding = settingsRounding; root.queueStoreSave(); }
        onThemeLibraryChanged: { store.themeLibrary = root._deepCopy(themeLibrary || []); }
        onActiveThemeIdChanged: { store.activeThemeId = activeThemeId; root.queueStoreSave(); }
        onRoundingChanged: { store.rounding = rounding; root.queueStoreSave(); }
        onBorderWidthChanged: { store.borderWidth = borderWidth; root.queueStoreSave(); }
        onButtonBorderWidthChanged: { store.buttonBorderWidth = buttonBorderWidth; root.queueStoreSave(); }
        onOverlayBorderWidthChanged: { store.overlayBorderWidth = overlayBorderWidth; root.queueStoreSave(); }
        onPanelOpacityChanged: { store.panelOpacity = panelOpacity; root.queueStoreSave(); }
        onOverlayDimOpacityChanged: { store.overlayDimOpacity = overlayDimOpacity; root.queueStoreSave(); }
        onFontFamilyChanged: { store.fontFamily = fontFamily; root.queueStoreSave(); }
        onFontPixelSizeChanged: { store.fontPixelSize = fontPixelSize; root.queueStoreSave(); }
        onSidebarEnabledChanged: { store.sidebarEnabled = sidebarEnabled; root.queueStoreSave(); }
        onBarOverlayVisibilityChanged: { store.barOverlayVisibility = root._deepCopy(barOverlayVisibility || root.defaultBarOverlayVisibility()); root.queueStoreSave(); }
        onDashboardTabVisibilityChanged: { store.dashboardTabVisibility = root._deepCopy(dashboardTabVisibility || root.defaultDashboardTabVisibility()); root.queueStoreSave(); }
        onSidebarEdgeHoldMsChanged: { store.sidebarEdgeHoldMs = sidebarEdgeHoldMs; root.queueStoreSave(); }
        onSidebarEdgeThresholdPxChanged: { store.sidebarEdgeThresholdPx = sidebarEdgeThresholdPx; root.queueStoreSave(); }
        onHoverReleaseMsChanged: { store.hoverReleaseMs = hoverReleaseMs; root.queueStoreSave(); }
        onSidebarSliderHeightChanged: { store.sidebarSliderHeight = sidebarSliderHeight; root.queueStoreSave(); }
        onBarWorkspacePollMsChanged: { store.barWorkspacePollMs = barWorkspacePollMs; root.queueStoreSave(); }
        onBarMediumPollMsChanged: { store.barMediumPollMs = barMediumPollMs; root.queueStoreSave(); }
        onBarSlowPollMsChanged: { store.barSlowPollMs = barSlowPollMs; root.queueStoreSave(); }
        onQuickSidebarPollMsChanged: { store.quickSidebarPollMs = quickSidebarPollMs; root.queueStoreSave(); }
        onDashboardEnabledChanged: { store.dashboardEnabled = dashboardEnabled; root.queueStoreSave(); }
        onDashboardRefreshMsChanged: { store.dashboardRefreshMs = dashboardRefreshMs; root.queueStoreSave(); }
        onDashboardFastPollMsChanged: { store.dashboardFastPollMs = dashboardFastPollMs; root.queueStoreSave(); }
        onDashboardMediumPollMsChanged: { store.dashboardMediumPollMs = dashboardMediumPollMs; root.queueStoreSave(); }
        onDashboardSlowPollMsChanged: { store.dashboardSlowPollMs = dashboardSlowPollMs; root.queueStoreSave(); }
        onShowShellTitleChanged: { store.showShellTitle = showShellTitle; root.queueStoreSave(); }
        onWorkspaceShowAllScreensChanged: { store.workspaceShowAllScreens = workspaceShowAllScreens; root.queueStoreSave(); }
        onWorkspaceActiveScreenBackgroundChanged: { store.workspaceActiveScreenBackground = workspaceActiveScreenBackground; root.queueStoreSave(); }
        onWorkspaceHighlightCurrentChanged: { store.workspaceHighlightCurrent = workspaceHighlightCurrent; root.queueStoreSave(); }
        onWorkspaceShowWindowIconsChanged: { store.workspaceShowWindowIcons = workspaceShowWindowIcons; root.queueStoreSave(); }
        onWorkspaceShowLayoutOnHoverChanged: { store.workspaceShowLayoutOnHover = workspaceShowLayoutOnHover; root.queueStoreSave(); }
        onWorkspaceSegmentVisibleChanged: { store.workspaceSegmentVisible = workspaceSegmentVisible; root.queueStoreSave(); }
        onWorkspaceVisibleCountChanged: { store.workspaceVisibleCount = Math.max(1, workspaceVisibleCount); root.queueStoreSave(); }
        onWorkspaceMaxIconsChanged: { store.workspaceMaxIcons = Math.max(0, workspaceMaxIcons); root.queueStoreSave(); }
        onUiTextStyleChanged: { store.uiTextStyle = (uiTextStyle === "uppercase" ? "uppercase" : "standard"); root.queueStoreSave(); }
        onControlCenterEnableHotkeyChanged: { store.controlCenterEnableHotkey = controlCenterEnableHotkey; root.queueStoreSave(); root.queueHyprlandSync(); }
        onControlCenterHotkeyChanged: { store.controlCenterHotkey = controlCenterHotkey; root.queueStoreSave(); root.queueHyprlandSync(); }
        onDashboardEnableHotkeyChanged: { store.dashboardEnableHotkey = dashboardEnableHotkey; root.queueStoreSave(); root.queueHyprlandSync(); }
        onDashboardHotkeyChanged: { store.dashboardHotkey = dashboardHotkey; root.queueStoreSave(); root.queueHyprlandSync(); }
        onSidebarEnableHotkeyChanged: { store.sidebarEnableHotkey = sidebarEnableHotkey; root.queueStoreSave(); root.queueHyprlandSync(); }
        onSidebarHotkeyChanged: { store.sidebarHotkey = sidebarHotkey; root.queueStoreSave(); root.queueHyprlandSync(); }
        onHyprlandManagedEnabledChanged: { store.hyprlandManagedEnabled = hyprlandManagedEnabled; root.queueStoreSave(); root.queueHyprlandSync(); }
        onHyprlandShowInfoMessageChanged: { store.hyprlandShowInfoMessage = hyprlandShowInfoMessage; root.queueStoreSave(); }
        onHyprlandDisableSplashChanged: { store.hyprlandDisableSplash = hyprlandDisableSplash; root.queueStoreSave(); root.queueHyprlandSync(); }
        onHyprlandMonitorsChanged: { store.hyprlandMonitors = root._deepCopy(hyprlandMonitors || []); root.queueStoreSave(); root.queueHyprlandSync(); }
        onHyprlandDecorationChanged: { store.hyprlandDecoration = root._deepCopy(hyprlandDecoration || {}); root.queueStoreSave(); root.queueHyprlandSync(); }
        onHyprlandBindsChanged: { store.hyprlandBinds = root._deepCopy(hyprlandBinds || []); root.queueStoreSave(); root.queueHyprlandSync(); }
        onHyprlandWorkspaceRulesChanged: { store.hyprlandWorkspaceRules = root._deepCopy(hyprlandWorkspaceRules || []); root.queueStoreSave(); root.queueHyprlandSync(); }
        onQuickSettingsTilesChanged: { store.quickSettingsTiles = root._deepCopy(quickSettingsTiles || []); root.queueStoreSave(); }

        Component.onCompleted: {
            if (store.barOrientation !== "top" && store.barOrientation !== "left") {
                store.barOrientation = "top";
            }
            if (!Array.isArray(store.themeLibrary) || store.themeLibrary.length < 1)
                store.themeLibrary = root.defaultThemeLibrary();
            if (!store.activeThemeId && store.themeLibrary.length > 0)
                store.activeThemeId = store.themeLibrary[0].id;
            themeLibrary = root._deepCopy(store.themeLibrary || []);
            hyprlandMonitors = root._deepCopy(store.hyprlandMonitors || []);
            hyprlandDecoration = root._deepCopy(store.hyprlandDecoration || {});
            hyprlandBinds = root._deepCopy(store.hyprlandBinds || []);
            hyprlandWorkspaceRules = root._deepCopy(store.hyprlandWorkspaceRules || []);
            quickSettingsTiles = root._deepCopy(store.quickSettingsTiles || root.defaultQuickSettingsTiles());
            barOverlayVisibility = root._deepCopy(store.barOverlayVisibility || root.defaultBarOverlayVisibility());
            dashboardTabVisibility = root._deepCopy(store.dashboardTabVisibility || root.defaultDashboardTabVisibility());
        }
    }

    // Real QObject property on ShellRoot so Variants delegates can use parent.parent.shellTheme
    // (delegate `root` is not ShellRoot; child id `config` is not a property of ShellRoot from JS.)
    readonly property QtObject shellTheme: config

    Shortcut {
        sequence: config.controlCenterHotkey
        enabled: config.controlCenterEnableHotkey && root.detectedWindowManagerKey !== "hyprland"
        onActivated: root.toggleControlCenter()
    }

    Shortcut {
        sequence: config.dashboardHotkey
        enabled: config.dashboardEnableHotkey && root.detectedWindowManagerKey !== "hyprland"
        onActivated: root.toggleDashboard()
    }

    Shortcut {
        sequence: config.sidebarHotkey
        enabled: config.sidebarEnableHotkey && root.detectedWindowManagerKey !== "hyprland"
        onActivated: root.toggleRightSidebar()
    }

    Loader {
        active: root.detectedWindowManagerKey === "hyprland"
        sourceComponent: Component {
            GlobalShortcut {
                name: "control-center"
                description: "Toggle the Quickshell control center."
                onPressed: root.toggleControlCenter()
            }
        }
    }

    Loader {
        active: root.detectedWindowManagerKey === "hyprland"
        sourceComponent: Component {
            GlobalShortcut {
                name: "dashboard"
                description: "Toggle the Quickshell dashboard."
                onPressed: root.toggleDashboard()
            }
        }
    }

    Loader {
        active: root.detectedWindowManagerKey === "hyprland"
        sourceComponent: Component {
            GlobalShortcut {
                name: "quick-sidebar"
                description: "Toggle the Quickshell quick sidebar."
                onPressed: root.toggleRightSidebar()
            }
        }
    }

    property var notificationHistory: []

    NotificationServer {
        id: notifServer
        keepOnReload: true
        onNotification: function(n) {
            root.pushSystemNotification(
                String(n.summary || ""),
                String(n.body || ""),
                Number(n.urgency || 1),
                String(n.appName || "")
            );
        }
    }

    Bar.BarRoot {
        shell: root
        config: config
    }

    // Holds ShellRoot for Variants delegates (Quickshell Scope has no `parent`; `root` in delegates is not ShellRoot).
    Item {
        id: perScreenShellHost
        property var shellHost: root
        width: 0
        height: 0

        Variants {
            model: Quickshell.screens
            Scope {
                property var modelData: null

                PanelWindow {
                    visible: perScreenShellHost.shellHost.shellTheme.dashboardEnabled
                    screen: modelData
                    // Overlay + ignore other panels' exclusive zones so this anchors at y=0, not below the bar reserve.
                    WlrLayershell.layer: WlrLayer.Overlay
                    WlrLayershell.exclusionMode: ExclusionMode.Ignore
                    anchors {
                        top: true
                        left: true
                        right: true
                    }
                    margins {
                        top: 0
                        left: 0
                        right: 0
                        bottom: 0
                    }
                    implicitHeight: 14
                    exclusiveZone: 0
                    color: "transparent"

                    Item {
                        width: 420
                        height: 14
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: {
                                perScreenShellHost.shellHost.stopDashboardHoverTimer();
                                perScreenShellHost.shellHost.dashboardAnchorScreen = modelData;
                                perScreenShellHost.shellHost.dashboardTriggerHovered = true;
                            }
                            onExited: {
                                perScreenShellHost.shellHost.startDashboardHoverTimer();
                            }
                            onClicked: perScreenShellHost.shellHost.toggleDashboard()
                        }
                    }
                }
            }
        }

        Variants {
            model: Quickshell.screens
            Scope {
                property var modelData: null

                Sidebar.RightSidebar {
                    shell: perScreenShellHost.shellHost
                    shellConfig: perScreenShellHost.shellHost.shellTheme
                    visible: perScreenShellHost.shellHost.shellTheme.sidebarEnabled && !!modelData
                    anchorScreen: modelData
                }
            }
        }
    }

    ControlCenter.ControlCenter {
        shell: root
        config: config
    }

    Dashboard.ThemeSelectorScreen {
        shell: root
        config: config
        availableThemes: config.themeLibrary || []
        uiFontFamily: config.fontFamily
        uiFontSize: config.fontPixelSize
    }

    Dashboard.WallpaperPickerScreen {
        shell: root
        config: config
    }

    Sidebar.QuickSettings {
        id: quickSettingsOverlay
        shell: root
        config: config
        notifications: root.notificationHistory
        visible: true
    }

    Sidebar.NotificationOverlay {
        config: config
        notifications: root.notificationHistory
        suppressPopup: quickSettingsOverlay.overlayOpen && quickSettingsOverlay.notifExpanded
        quickSettingsOpen: root.quickSettingsOpen
        quickSettingsHeight: quickSettingsOverlay.panelHeightEstimate
        quickSettingsTriggerHeight: quickSettingsOverlay.triggerH
        overlayWidth: Math.max(280, quickSettingsOverlay.menuW)
    }

    Dashboard.Dashboard {
        shell: root
        config: config
    }
}
