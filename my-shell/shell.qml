import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import "modules/bar" as Bar
import "modules/controlcenter" as ControlCenter
import "modules/dashboard" as Dashboard
import "modules/sidebar" as Sidebar

ShellRoot {
    id: root

    property bool controlCenterVisible: false
    property bool themeWindowVisible: false
    property bool dashboardVisible: false
    property bool dashboardTriggerHovered: false
    property bool dashboardOverlayHovered: false
    property bool rightSidebarVisible: false
    property bool rightSidebarTriggerHovered: false
    property bool rightSidebarOverlayHovered: false

    function toggleControlCenter() {
        controlCenterVisible = !controlCenterVisible;
    }

    function toggleThemeWindow() {
        themeWindowVisible = !themeWindowVisible;
    }

    function toggleDashboard() {
        dashboardVisible = !dashboardVisible;
    }

    function toggleRightSidebar() {
        rightSidebarVisible = !rightSidebarVisible;
    }

    Timer {
        id: dashboardHoverRelease
        interval: config.hoverReleaseMs
        repeat: false
        onTriggered: root.dashboardTriggerHovered = false
    }

    function _deepCopy(value) {
        return JSON.parse(JSON.stringify(value));
    }

    function defaultThemeLibrary() {
        return [
            {
                id: "amber-night",
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
                id: "forest",
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
                id: "ocean",
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
                id: "plum",
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
                id: "paper-light",
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
        ];
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

    function normalizeTheme(theme, fallbackId) {
        const source = theme || {};
        return {
            id: String(source.id || fallbackId || ("theme-" + Date.now())),
            name: String(source.name || "Custom Theme"),
            themeMode: String(source.themeMode || "dark"),
            accentColor: String(source.accentColor || "#ff8c32"),
            borderColor: String(source.borderColor || source.accentColor || "#ff8c32"),
            backgroundColor: String(source.backgroundColor || "#0f0f12"),
            textColor: String(source.textColor || "#e5e7eb"),
            workspaceAccentColor: String(source.workspaceAccentColor || source.accentColor || "#ff8c32"),
            workspaceColor: String(source.workspaceColor || "#111827"),
            volumeColor: String(source.volumeColor || source.accentColor || "#ff8c32"),
            quickSidebarColor: String(source.quickSidebarColor || source.accentColor || "#ff8c32"),
            dashboardColor: String(source.dashboardColor || source.accentColor || "#ff8c32"),
            overlayAccentColor: String(source.overlayAccentColor || source.accentColor || "#ff8c32"),
            panelColor: String(source.panelColor || ""),
            mutedTextColor: String(source.mutedTextColor || ""),
            wallpaperPath: String(source.wallpaperPath || ""),
            rounding: _themeNum(source, "rounding", 8),
            borderWidth: _themeNum(source, "borderWidth", 1),
            buttonBorderWidth: _themeNum(source, "buttonBorderWidth", 1),
            overlayBorderWidth: _themeNum(source, "overlayBorderWidth", 1),
            panelOpacity: _themeNum(source, "panelOpacity", 0.96),
            overlayDimOpacity: _themeNum(source, "overlayDimOpacity", 0.4)
        };
    }

    function applyThemeObject(theme) {
        const next = normalizeTheme(theme);
        config.themeMode = next.themeMode;
        config.accentColor = next.accentColor;
        config.borderColor = next.borderColor;
        config.backgroundColor = next.backgroundColor;
        config.textColor = next.textColor;
        config.workspaceAccentColor = next.workspaceAccentColor;
        config.workspaceColor = next.workspaceColor;
        config.volumeColor = next.volumeColor;
        config.quickSidebarColor = next.quickSidebarColor;
        config.dashboardColor = next.dashboardColor;
        config.overlayAccentColor = next.overlayAccentColor;
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
            accentColor: String(config.accentColor),
            borderColor: String(config.borderColor),
            backgroundColor: String(config.backgroundColor),
            textColor: String(config.textColor),
            workspaceAccentColor: String(config.workspaceAccentColor),
            workspaceColor: String(config.workspaceColor),
            volumeColor: String(config.volumeColor),
            quickSidebarColor: String(config.quickSidebarColor),
            dashboardColor: String(config.dashboardColor),
            overlayAccentColor: String(config.overlayAccentColor),
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
        property string workspaceAccentColor: "#ff8c32"
        property string volumeColor: "#ff8c32"
        property string quickSidebarColor: "#ff8c32"
        property string dashboardColor: "#41aefc"
        property string overlayAccentColor: "#ff8c32"
        property string panelColor: ""
        property string mutedTextColor: ""
        property string wallpaperPath: ""
        property var themeLibrary: root.defaultThemeLibrary()
        property string activeThemeId: "amber-night"
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
            workspaceAccentColor: store.workspaceAccentColor,
            volumeColor: store.volumeColor,
            quickSidebarColor: store.quickSidebarColor,
            dashboardColor: store.dashboardColor,
            overlayAccentColor: store.overlayAccentColor,
            panelColor: store.panelColor,
            mutedTextColor: store.mutedTextColor,
            wallpaperPath: store.wallpaperPath,
            themeLibrary: store.themeLibrary,
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
                if (cfg.workspaceAccentColor !== undefined)
                    store.workspaceAccentColor = cfg.workspaceAccentColor;
                if (cfg.volumeColor !== undefined)
                    store.volumeColor = cfg.volumeColor;
                if (cfg.quickSidebarColor !== undefined)
                    store.quickSidebarColor = cfg.quickSidebarColor;
                if (cfg.dashboardColor !== undefined)
                    store.dashboardColor = cfg.dashboardColor;
                if (cfg.overlayAccentColor !== undefined)
                    store.overlayAccentColor = cfg.overlayAccentColor;
                if (cfg.panelColor !== undefined)
                    store.panelColor = String(cfg.panelColor);
                if (cfg.mutedTextColor !== undefined)
                    store.mutedTextColor = String(cfg.mutedTextColor);
                if (cfg.wallpaperPath !== undefined)
                    store.wallpaperPath = String(cfg.wallpaperPath);
                if (cfg.themeLibrary !== undefined && Array.isArray(cfg.themeLibrary) && cfg.themeLibrary.length > 0)
                    store.themeLibrary = cfg.themeLibrary.map((theme, index) => root.normalizeTheme(theme, "theme-" + index));
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
                config.themeLibrary = root._deepCopy(store.themeLibrary || []);
                config.hyprlandMonitors = root._deepCopy(store.hyprlandMonitors || []);
                config.hyprlandDecoration = root._deepCopy(store.hyprlandDecoration || {});
                config.hyprlandBinds = root._deepCopy(store.hyprlandBinds || []);
                config.hyprlandWorkspaceRules = root._deepCopy(store.hyprlandWorkspaceRules || []);
            } catch (e) {
                console.warn("settings.json parse failed:", e);
            }
        }

        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                root.saveStore();
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
        property color workspaceAccentColor: store.workspaceAccentColor
        property color volumeColor: store.volumeColor
        property color quickSidebarColor: store.quickSidebarColor
        property color dashboardColor: store.dashboardColor
        property color overlayAccentColor: store.overlayAccentColor
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
        onWorkspaceAccentColorChanged: { store.workspaceAccentColor = workspaceAccentColor; root.queueStoreSave(); }
        onVolumeColorChanged: { store.volumeColor = volumeColor; root.queueStoreSave(); }
        onQuickSidebarColorChanged: { store.quickSidebarColor = quickSidebarColor; root.queueStoreSave(); }
        onDashboardColorChanged: { store.dashboardColor = dashboardColor; root.queueStoreSave(); }
        onOverlayAccentColorChanged: { store.overlayAccentColor = overlayAccentColor; root.queueStoreSave(); }
        onThemeLibraryChanged: { store.themeLibrary = root._deepCopy(themeLibrary || []); root.queueStoreSave(); }
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
        onControlCenterEnableHotkeyChanged: { store.controlCenterEnableHotkey = controlCenterEnableHotkey; root.queueStoreSave(); }
        onControlCenterHotkeyChanged: { store.controlCenterHotkey = controlCenterHotkey; root.queueStoreSave(); }
        onDashboardEnableHotkeyChanged: { store.dashboardEnableHotkey = dashboardEnableHotkey; root.queueStoreSave(); }
        onDashboardHotkeyChanged: { store.dashboardHotkey = dashboardHotkey; root.queueStoreSave(); }
        onSidebarEnableHotkeyChanged: { store.sidebarEnableHotkey = sidebarEnableHotkey; root.queueStoreSave(); }
        onSidebarHotkeyChanged: { store.sidebarHotkey = sidebarHotkey; root.queueStoreSave(); }
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
            if (!store.activeThemeId)
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
        enabled: config.controlCenterEnableHotkey
        onActivated: root.toggleControlCenter()
    }

    Shortcut {
        sequence: config.dashboardHotkey
        enabled: config.dashboardEnableHotkey
        onActivated: root.toggleDashboard()
    }

    Shortcut {
        sequence: config.sidebarHotkey
        enabled: config.sidebarEnableHotkey
        onActivated: root.toggleRightSidebar()
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

    ControlCenter.ThemeWindow {
        shell: root
        config: config
        visible: root.themeWindowVisible
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
