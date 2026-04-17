import QtQuick
import QtCore
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
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
    property bool quickSettingsVisible: false
    property bool dashboardTriggerHovered: false
    property bool dashboardOverlayHovered: false
    property bool rightSidebarVisible: false
    property bool rightSidebarTriggerHovered: false
    property bool rightSidebarOverlayHovered: false
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
    }

    function toggleControlCenter() {
        if (!controlCenterVisible) {
            closeDashboardOverlays();
            themeSelectorVisible = false;
            quickSettingsVisible = false;
        }
        controlCenterVisible = !controlCenterVisible;
    }

    function openControlCenter() {
        closeDashboardOverlays();
        themeSelectorVisible = false;
        quickSettingsVisible = false;
        controlCenterVisible = true;
    }

    function openThemeSelector() {
        closeDashboardOverlays();
        controlCenterVisible = false;
        quickSettingsVisible = false;
        themeSelectorVisible = true;
    }

    function toggleDashboard() {
        dashboardVisible = !dashboardVisible;
    }

    function toggleRightSidebar() {
        rightSidebarVisible = !rightSidebarVisible;
    }

    Component.onCompleted: {
        windowManagerDetectProc.exec({ command: windowManagerDetectProc.command });
    }

    Timer {
        id: dashboardHoverRelease
        interval: config.hoverReleaseMs
        repeat: false
        onTriggered: root.dashboardTriggerHovered = false
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
            rounding: component.rounding !== undefined ? _themeNum(component, "rounding", -1) : -1
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
            workspaceRounding: _componentRounding(components, "workspace", general.rounding),
            dashboardColor: _componentColor(components, "dashboard", "accentColor", general.accentColor),
            dashboardBackgroundColor: _componentColor(components, "dashboard", "backgroundColor", general.panelColor || general.backgroundColor),
            dashboardTextColor: _componentColor(components, "dashboard", "textColor", general.textColor),
            dashboardRounding: _componentRounding(components, "dashboard", general.rounding),
            quickSidebarColor: _componentColor(components, "sidebar", "accentColor", general.accentColor),
            sidebarBackgroundColor: _componentColor(components, "sidebar", "backgroundColor", general.panelColor || general.backgroundColor),
            sidebarTextColor: _componentColor(components, "sidebar", "textColor", general.textColor),
            sidebarRounding: _componentRounding(components, "sidebar", general.rounding),
            overlayAccentColor: _componentColor(components, "overlay", "accentColor", general.accentColor),
            overlayBackgroundColor: _componentColor(components, "overlay", "backgroundColor", general.panelColor || general.backgroundColor),
            overlayTextColor: _componentColor(components, "overlay", "textColor", general.textColor),
            overlayRounding: _componentRounding(components, "overlay", general.rounding),
            volumeColor: _componentColor(components, "visualization", "accentColor", general.accentColor),
            visualizationBackgroundColor: _componentColor(components, "visualization", "backgroundColor", general.panelColor || general.backgroundColor),
            visualizationTextColor: _componentColor(components, "visualization", "textColor", general.textColor),
            visualizationRounding: _componentRounding(components, "visualization", general.rounding),
            settingsAccentColor: _componentColor(components, "settings", "accentColor", general.accentColor),
            settingsBackgroundColor: _componentColor(components, "settings", "backgroundColor", general.panelColor || general.backgroundColor),
            settingsTextColor: _componentColor(components, "settings", "textColor", general.textColor),
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
        config.workspaceRounding = next.workspaceRounding;
        config.volumeColor = next.volumeColor;
        config.quickSidebarColor = next.quickSidebarColor;
        config.sidebarBackgroundColor = next.sidebarBackgroundColor;
        config.sidebarTextColor = next.sidebarTextColor;
        config.sidebarRounding = next.sidebarRounding;
        config.dashboardColor = next.dashboardColor;
        config.dashboardBackgroundColor = next.dashboardBackgroundColor;
        config.dashboardTextColor = next.dashboardTextColor;
        config.dashboardRounding = next.dashboardRounding;
        config.overlayAccentColor = next.overlayAccentColor;
        config.overlayBackgroundColor = next.overlayBackgroundColor;
        config.overlayTextColor = next.overlayTextColor;
        config.overlayRounding = next.overlayRounding;
        config.visualizationBackgroundColor = next.visualizationBackgroundColor;
        config.visualizationTextColor = next.visualizationTextColor;
        config.visualizationRounding = next.visualizationRounding;
        config.settingsAccentColor = next.settingsAccentColor;
        config.settingsBackgroundColor = next.settingsBackgroundColor;
        config.settingsTextColor = next.settingsTextColor;
        config.settingsRounding = next.settingsRounding;
        store.panelColor = String(next.panelColor || "");
        store.mutedTextColor = String(next.mutedTextColor || "");
        store.wallpaperPath = String(next.wallpaperPath || "");
        config.rounding = Math.round(next.rounding);
        config.borderWidth = Math.round(next.borderWidth);
        config.buttonBorderWidth = Math.round(next.buttonBorderWidth);
        config.overlayBorderWidth = Math.round(next.overlayBorderWidth);
        config.panelOpacity = Math.max(0.55, Math.min(1, next.panelOpacity));
        config.overlayDimOpacity = Math.max(0, Math.min(0.9, next.overlayDimOpacity));
        root.applyWallpaper(next.wallpaperPath);
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
                    rounding: store.workspaceRounding
                },
                dashboard: {
                    accentColor: String(store.dashboardColor || ""),
                    backgroundColor: String(store.dashboardBackgroundColor || ""),
                    textColor: String(store.dashboardTextColor || ""),
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
        property int workspaceRounding: 8
        property string volumeColor: "#ff8c32"
        property string quickSidebarColor: "#ff8c32"
        property string sidebarBackgroundColor: ""
        property string sidebarTextColor: ""
        property int sidebarRounding: 8
        property string dashboardColor: "#41aefc"
        property string dashboardBackgroundColor: ""
        property string dashboardTextColor: ""
        property int dashboardRounding: 8
        property string overlayAccentColor: "#ff8c32"
        property string overlayBackgroundColor: ""
        property string overlayTextColor: ""
        property int overlayRounding: 8
        property string visualizationBackgroundColor: ""
        property string visualizationTextColor: ""
        property int visualizationRounding: 8
        property string settingsAccentColor: "#ff8c32"
        property string settingsBackgroundColor: ""
        property string settingsTextColor: ""
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
        property bool controlCenterEnableHotkey: true
        property string controlCenterHotkey: "Ctrl+Alt+C"
        property bool dashboardEnableHotkey: true
        property string dashboardHotkey: "Ctrl+Alt+D"
        property bool sidebarEnableHotkey: true
        property string sidebarHotkey: "Ctrl+Alt+B"
        property bool hyprlandManagedEnabled: true
        property var hyprlandMonitors: root.defaultHyprlandMonitors()
        property var hyprlandDecoration: root.defaultHyprlandDecoration()
        property var hyprlandBinds: root.defaultHyprlandBinds()
        property var hyprlandWorkspaceRules: root.defaultHyprlandWorkspaceRules()
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
            workspaceRounding: store.workspaceRounding,
            volumeColor: store.volumeColor,
            quickSidebarColor: store.quickSidebarColor,
            sidebarBackgroundColor: store.sidebarBackgroundColor,
            sidebarTextColor: store.sidebarTextColor,
            sidebarRounding: store.sidebarRounding,
            dashboardColor: store.dashboardColor,
            dashboardBackgroundColor: store.dashboardBackgroundColor,
            dashboardTextColor: store.dashboardTextColor,
            dashboardRounding: store.dashboardRounding,
            overlayAccentColor: store.overlayAccentColor,
            overlayBackgroundColor: store.overlayBackgroundColor,
            overlayTextColor: store.overlayTextColor,
            overlayRounding: store.overlayRounding,
            visualizationBackgroundColor: store.visualizationBackgroundColor,
            visualizationTextColor: store.visualizationTextColor,
            visualizationRounding: store.visualizationRounding,
            settingsAccentColor: store.settingsAccentColor,
            settingsBackgroundColor: store.settingsBackgroundColor,
            settingsTextColor: store.settingsTextColor,
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
            controlCenterEnableHotkey: store.controlCenterEnableHotkey,
            controlCenterHotkey: store.controlCenterHotkey,
            dashboardEnableHotkey: store.dashboardEnableHotkey,
            dashboardHotkey: store.dashboardHotkey,
            sidebarEnableHotkey: store.sidebarEnableHotkey,
            sidebarHotkey: store.sidebarHotkey,
            hyprlandManagedEnabled: store.hyprlandManagedEnabled,
            hyprlandMonitors: store.hyprlandMonitors,
            hyprlandDecoration: store.hyprlandDecoration,
            hyprlandBinds: store.hyprlandBinds,
            hyprlandWorkspaceRules: store.hyprlandWorkspaceRules
        };
        settingsFile.setText(JSON.stringify(payload, null, 2));
    }

    function queueStoreSave() {
        saveTimer.restart();
    }

    Timer {
        id: saveTimer
        interval: 120
        repeat: false
        onTriggered: root.saveStore()
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
                if (cfg.dashboardRounding !== undefined)
                    store.dashboardRounding = cfg.dashboardRounding;
                if (cfg.overlayAccentColor !== undefined)
                    store.overlayAccentColor = cfg.overlayAccentColor;
                if (cfg.overlayBackgroundColor !== undefined)
                    store.overlayBackgroundColor = String(cfg.overlayBackgroundColor);
                if (cfg.overlayTextColor !== undefined)
                    store.overlayTextColor = String(cfg.overlayTextColor);
                if (cfg.overlayRounding !== undefined)
                    store.overlayRounding = cfg.overlayRounding;
                if (cfg.visualizationBackgroundColor !== undefined)
                    store.visualizationBackgroundColor = String(cfg.visualizationBackgroundColor);
                if (cfg.visualizationTextColor !== undefined)
                    store.visualizationTextColor = String(cfg.visualizationTextColor);
                if (cfg.visualizationRounding !== undefined)
                    store.visualizationRounding = cfg.visualizationRounding;
                if (cfg.settingsAccentColor !== undefined)
                    store.settingsAccentColor = String(cfg.settingsAccentColor);
                if (cfg.settingsBackgroundColor !== undefined)
                    store.settingsBackgroundColor = String(cfg.settingsBackgroundColor);
                if (cfg.settingsTextColor !== undefined)
                    store.settingsTextColor = String(cfg.settingsTextColor);
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
                if (cfg.hyprlandMonitors !== undefined && Array.isArray(cfg.hyprlandMonitors) && cfg.hyprlandMonitors.length > 0)
                    store.hyprlandMonitors = cfg.hyprlandMonitors;
                if (cfg.hyprlandDecoration !== undefined)
                    store.hyprlandDecoration = cfg.hyprlandDecoration;
                if (cfg.hyprlandBinds !== undefined && Array.isArray(cfg.hyprlandBinds) && cfg.hyprlandBinds.length > 0)
                    store.hyprlandBinds = cfg.hyprlandBinds;
                if (cfg.hyprlandWorkspaceRules !== undefined && Array.isArray(cfg.hyprlandWorkspaceRules) && cfg.hyprlandWorkspaceRules.length > 0)
                    store.hyprlandWorkspaceRules = cfg.hyprlandWorkspaceRules;
                config.hyprlandMonitors = root._deepCopy(store.hyprlandMonitors || []);
                config.hyprlandDecoration = root._deepCopy(store.hyprlandDecoration || {});
                config.hyprlandBinds = root._deepCopy(store.hyprlandBinds || []);
                config.hyprlandWorkspaceRules = root._deepCopy(store.hyprlandWorkspaceRules || []);
            } catch (e) {
                console.warn("settings.json parse failed:", e);
            }
            themeLibraryProc.exec({ command: themeLibraryProc.command });
        }

        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                root.saveStore();
            themeLibraryProc.exec({ command: themeLibraryProc.command });
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
        property int workspaceRounding: store.workspaceRounding
        property color volumeColor: store.volumeColor
        property color quickSidebarColor: store.quickSidebarColor
        property color sidebarBackgroundColor: store.sidebarBackgroundColor.length > 0 ? store.sidebarBackgroundColor : panelColor
        property color sidebarTextColor: store.sidebarTextColor.length > 0 ? store.sidebarTextColor : textColor
        property int sidebarRounding: store.sidebarRounding
        property color dashboardColor: store.dashboardColor
        property color dashboardBackgroundColor: store.dashboardBackgroundColor.length > 0 ? store.dashboardBackgroundColor : panelColor
        property color dashboardTextColor: store.dashboardTextColor.length > 0 ? store.dashboardTextColor : textColor
        property int dashboardRounding: store.dashboardRounding
        property color overlayAccentColor: store.overlayAccentColor
        property color overlayBackgroundColor: store.overlayBackgroundColor.length > 0 ? store.overlayBackgroundColor : panelColor
        property color overlayTextColor: store.overlayTextColor.length > 0 ? store.overlayTextColor : textColor
        property int overlayRounding: store.overlayRounding
        property color visualizationBackgroundColor: store.visualizationBackgroundColor.length > 0 ? store.visualizationBackgroundColor : panelColor
        property color visualizationTextColor: store.visualizationTextColor.length > 0 ? store.visualizationTextColor : textColor
        property int visualizationRounding: store.visualizationRounding
        property color settingsAccentColor: store.settingsAccentColor.length > 0 ? store.settingsAccentColor : accentColor
        property color settingsBackgroundColor: store.settingsBackgroundColor.length > 0 ? store.settingsBackgroundColor : panelColor
        property color settingsTextColor: store.settingsTextColor.length > 0 ? store.settingsTextColor : textColor
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
        property bool controlCenterEnableHotkey: store.controlCenterEnableHotkey
        property string controlCenterHotkey: store.controlCenterHotkey
        property bool dashboardEnableHotkey: store.dashboardEnableHotkey
        property string dashboardHotkey: store.dashboardHotkey
        property bool sidebarEnableHotkey: store.sidebarEnableHotkey
        property string sidebarHotkey: store.sidebarHotkey
        property bool hyprlandManagedEnabled: store.hyprlandManagedEnabled
        property var hyprlandMonitors: []
        property var hyprlandDecoration: ({})
        property var hyprlandBinds: []
        property var hyprlandWorkspaceRules: []

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
        onWorkspaceRoundingChanged: { store.workspaceRounding = workspaceRounding; root.queueStoreSave(); }
        onVolumeColorChanged: { store.volumeColor = volumeColor; root.queueStoreSave(); }
        onQuickSidebarColorChanged: { store.quickSidebarColor = quickSidebarColor; root.queueStoreSave(); }
        onSidebarBackgroundColorChanged: { store.sidebarBackgroundColor = String(sidebarBackgroundColor); root.queueStoreSave(); }
        onSidebarTextColorChanged: { store.sidebarTextColor = String(sidebarTextColor); root.queueStoreSave(); }
        onSidebarRoundingChanged: { store.sidebarRounding = sidebarRounding; root.queueStoreSave(); }
        onDashboardColorChanged: { store.dashboardColor = dashboardColor; root.queueStoreSave(); }
        onDashboardBackgroundColorChanged: { store.dashboardBackgroundColor = String(dashboardBackgroundColor); root.queueStoreSave(); }
        onDashboardTextColorChanged: { store.dashboardTextColor = String(dashboardTextColor); root.queueStoreSave(); }
        onDashboardRoundingChanged: { store.dashboardRounding = dashboardRounding; root.queueStoreSave(); }
        onOverlayAccentColorChanged: { store.overlayAccentColor = overlayAccentColor; root.queueStoreSave(); }
        onOverlayBackgroundColorChanged: { store.overlayBackgroundColor = String(overlayBackgroundColor); root.queueStoreSave(); }
        onOverlayTextColorChanged: { store.overlayTextColor = String(overlayTextColor); root.queueStoreSave(); }
        onOverlayRoundingChanged: { store.overlayRounding = overlayRounding; root.queueStoreSave(); }
        onVisualizationBackgroundColorChanged: { store.visualizationBackgroundColor = String(visualizationBackgroundColor); root.queueStoreSave(); }
        onVisualizationTextColorChanged: { store.visualizationTextColor = String(visualizationTextColor); root.queueStoreSave(); }
        onVisualizationRoundingChanged: { store.visualizationRounding = visualizationRounding; root.queueStoreSave(); }
        onSettingsAccentColorChanged: { store.settingsAccentColor = String(settingsAccentColor); root.queueStoreSave(); }
        onSettingsBackgroundColorChanged: { store.settingsBackgroundColor = String(settingsBackgroundColor); root.queueStoreSave(); }
        onSettingsTextColorChanged: { store.settingsTextColor = String(settingsTextColor); root.queueStoreSave(); }
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
        onControlCenterEnableHotkeyChanged: { store.controlCenterEnableHotkey = controlCenterEnableHotkey; root.queueStoreSave(); root.queueHyprlandSync(); }
        onControlCenterHotkeyChanged: { store.controlCenterHotkey = controlCenterHotkey; root.queueStoreSave(); root.queueHyprlandSync(); }
        onDashboardEnableHotkeyChanged: { store.dashboardEnableHotkey = dashboardEnableHotkey; root.queueStoreSave(); root.queueHyprlandSync(); }
        onDashboardHotkeyChanged: { store.dashboardHotkey = dashboardHotkey; root.queueStoreSave(); root.queueHyprlandSync(); }
        onSidebarEnableHotkeyChanged: { store.sidebarEnableHotkey = sidebarEnableHotkey; root.queueStoreSave(); root.queueHyprlandSync(); }
        onSidebarHotkeyChanged: { store.sidebarHotkey = sidebarHotkey; root.queueStoreSave(); root.queueHyprlandSync(); }
        onHyprlandManagedEnabledChanged: { store.hyprlandManagedEnabled = hyprlandManagedEnabled; root.queueStoreSave(); root.queueHyprlandSync(); }
        onHyprlandMonitorsChanged: { store.hyprlandMonitors = root._deepCopy(hyprlandMonitors || []); root.queueStoreSave(); root.queueHyprlandSync(); }
        onHyprlandDecorationChanged: { store.hyprlandDecoration = root._deepCopy(hyprlandDecoration || {}); root.queueStoreSave(); root.queueHyprlandSync(); }
        onHyprlandBindsChanged: { store.hyprlandBinds = root._deepCopy(hyprlandBinds || []); root.queueStoreSave(); root.queueHyprlandSync(); }
        onHyprlandWorkspaceRulesChanged: { store.hyprlandWorkspaceRules = root._deepCopy(hyprlandWorkspaceRules || []); root.queueStoreSave(); root.queueHyprlandSync(); }

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
        }
    }

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

    Bar.BarRoot {
        shell: root
        config: config
    }

    PanelWindow {
        visible: config.dashboardEnabled
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
                    dashboardHoverRelease.stop();
                    root.dashboardTriggerHovered = true;
                }
                onExited: {
                    dashboardHoverRelease.restart();
                }
                onClicked: root.toggleDashboard()
            }
        }
    }

    ControlCenter.ControlCenter {
        shell: root
        config: config
        visible: root.controlCenterVisible
    }

    Dashboard.ThemeSelectorScreen {
        shell: root
        config: config
        availableThemes: config.themeLibrary || []
        uiFontFamily: config.fontFamily
        uiFontSize: config.fontPixelSize
        visible: root.themeSelectorVisible
    }

    Sidebar.QuickSettings {
        shell: root
        config: config
        visible: true
    }

    Dashboard.Dashboard {
        shell: root
        config: config
        visible: (root.dashboardVisible || root.dashboardTriggerHovered || root.dashboardOverlayHovered) && config.dashboardEnabled
    }

    Sidebar.RightSidebar {
        shell: root
        config: config
        visible: config.sidebarEnabled
    }
}
