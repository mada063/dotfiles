import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import "."

Item {
    id: root

    required property QtObject dashboard
    property string packageManager: "-"
    property string systemUpdateCount: "-"
    property string aurUpdateCount: "-"
    property string flatpakUpdateCount: "-"
    property string updateSummary: "Checking…"
    property string lastChecked: "-"
    property string updateCommandHint: "-"
    property string aurCommandHint: "-"
    property bool checkingUpdates: false
    property bool aurHelperDetected: false
    property bool flatpakAvailable: false
    // ms timestamp of last successful check (0 = never)
    property real updatesLastFetchMs: 0
    readonly property real updatesRefreshStaleMs: 10 * 60 * 1000
    property string systemPackageList: "—"
    property string aurPackageList: "—"
    property string flatpakPackageList: "—"
    property string systemPackageTotal: "-"
    property string aurPackageTotal: "-"
    property string flatpakPackageTotal: "-"

    readonly property int _pacmanCount: _parseInt(systemUpdateCount, -1)
    readonly property int _aurCount: _parseInt(aurUpdateCount, -1)
    readonly property int _flatCount: _parseInt(flatpakUpdateCount, -1)
    readonly property int _barMax: 30
    readonly property int _sysSegPct: _pacmanCount >= 0 ? Math.min(100, Math.floor(100 * Math.min(1, _pacmanCount / _barMax))) : 0
    readonly property int _aurSegPct: _aurCount >= 0 ? Math.min(100, Math.floor(100 * Math.min(1, _aurCount / _barMax))) : 0
    readonly property int _flatSegPct: _flatCount >= 0 ? Math.min(100, Math.floor(100 * Math.min(1, _flatCount / _barMax))) : 0
    readonly property int _sysTotalCount: _parseInt(systemPackageTotal, -1)
    readonly property int _aurTotalCount: _parseInt(aurPackageTotal, -1)
    readonly property int _flatTotalCount: _parseInt(flatpakPackageTotal, -1)
    readonly property int _totalBarMax: 2500
    readonly property int _sysTotalPct: _sysTotalCount >= 0 ? Math.min(100, Math.floor(100 * Math.min(1, _sysTotalCount / _totalBarMax))) : 0
    readonly property int _aurTotalPct: _aurTotalCount >= 0 ? Math.min(100, Math.floor(100 * Math.min(1, _aurTotalCount / _totalBarMax))) : 0
    readonly property int _updatesTotal: Math.max(0, _pacmanCount) + Math.max(0, _aurCount)
    readonly property int _installedTotal: Math.max(0, _sysTotalCount) + Math.max(0, _aurTotalCount)
    readonly property real _sysUpdateShare: _updatesTotal > 0 ? Math.max(0, _pacmanCount) / _updatesTotal : 0
    readonly property real _aurUpdateShare: _updatesTotal > 0 ? Math.max(0, _aurCount) / _updatesTotal : 0
    readonly property real _updateLoadShare: _installedTotal > 0 ? Math.min(1, _updatesTotal / _installedTotal) : 0
    readonly property int _updateLoadPct: Math.round(_updateLoadShare * 100)
    readonly property int _sysSharePct: Math.round(_sysUpdateShare * 100)
    readonly property int _aurSharePct: Math.round(_aurUpdateShare * 100)
    readonly property int _sourceTotal: Math.max(0, _sysTotalCount) + Math.max(0, _aurTotalCount) + Math.max(0, _flatTotalCount)
    readonly property int _pacmanSourcePct: _sourceTotal > 0 ? Math.round((Math.max(0, _sysTotalCount) * 100) / _sourceTotal) : 0
    readonly property int _aurSourcePct: _sourceTotal > 0 ? Math.round((Math.max(0, _aurTotalCount) * 100) / _sourceTotal) : 0
    readonly property int _otherSourcePct: _sourceTotal > 0 ? Math.round((Math.max(0, _flatTotalCount) * 100) / _sourceTotal) : 0

    function refreshUpdates() {
        if (updatesProc.running)
            return;
        checkingUpdates = true;
        updatesProc.exec({ command: updatesProc.command });
    }

    function maybeRefreshIfStale() {
        if (updatesProc.running)
            return;
        if (root.updatesLastFetchMs <= 0) {
            root.refreshUpdates();
            return;
        }
        if (Date.now() - root.updatesLastFetchMs < root.updatesRefreshStaleMs)
            return;
        root.refreshUpdates();
    }

    function _parseInt(value, fallback) {
        const n = Number(value);
        return Number.isFinite(n) ? Math.max(0, Math.floor(n)) : fallback;
    }

    function _runInTerminalSingle(combined) {
        if (actionProc.running)
            return;
        const c = String(combined || "").trim();
        if (!c.length)
            return;
        const inner = "RUNCMD=" + JSON.stringify(c) + "; " +
            "printf '\\nThe following will run (sudo will prompt as needed):\\n  %s\\n\\n' \"$RUNCMD\"; " +
            "read -n1 -rsp 'Press any key to continue...\\n' || true; " +
            "eval \"$RUNCMD\"; echo; read -n1 -rsp 'Press any key to close...\\n' || true";
        const arg = JSON.stringify(inner);
        actionProc.exec({ command: ["bash", "-lc",
            "if command -v xdg-terminal-exec >/dev/null 2>&1; then xdg-terminal-exec bash -lc " + arg + "; " +
            "elif command -v kitty >/dev/null 2>&1; then kitty bash -lc " + arg + "; " +
            "elif command -v alacritty >/dev/null 2>&1; then alacritty -e bash -lc " + arg + "; " +
            "elif command -v foot >/dev/null 2>&1; then foot bash -lc " + arg + "; " +
            "elif command -v wezterm >/dev/null 2>&1; then wezterm start -- bash -lc " + arg + "; " +
            "elif command -v gnome-terminal >/dev/null 2>&1; then gnome-terminal -- bash -lc " + arg + "; " +
            "elif command -v konsole >/dev/null 2>&1; then konsole -e bash -lc " + arg + "; " +
            "elif command -v xterm >/dev/null 2>&1; then xterm -e bash -lc " + arg + "; fi"
        ] });
    }

    function runSystemUpdateInTerminal() {
        const cmd = String(root.updateCommandHint || "").trim();
        if (!cmd || cmd === "-")
            return;
        root._runInTerminalSingle(cmd);
    }

    function runAurUpdateInTerminal() {
        const cmd = String(root.aurCommandHint || "").trim();
        if (!cmd || cmd === "-")
            return;
        root._runInTerminalSingle(cmd);
    }

    function runFlatpakUpdateInTerminal() {
        root._runInTerminalSingle("flatpak update");
    }

    Process {
        id: updatesProc
        command: ["bash", "-lc", "lsys=; laur=; lflat=; totsys='-'; totaur='-'; totflat='-'; pm='none'; sys='-'; aur='-'; flat='-'; cmd='-'; aurcmd='-'; aurok=0; if command -v pacman >/dev/null 2>&1; then pm='pacman'; cmd='sudo pacman -Syu'; totsys=$(pacman -Qq 2>/dev/null | wc -l); if command -v checkupdates >/dev/null 2>&1; then sys=$(checkupdates 2>/dev/null | wc -l); lsys=$(checkupdates 2>/dev/null | awk '{print $1}' | head -n 50 | paste -sd, -); else sys=$(pacman -Qu 2>/dev/null | wc -l); lsys=$(pacman -Quq 2>/dev/null | head -n 50 | paste -sd, -); fi; if command -v yay >/dev/null 2>&1; then aurok=1; aurcmd='yay -Sua'; aur=$(yay -Qua 2>/dev/null | wc -l); laur=$(yay -Qua 2>/dev/null | awk '{print $1}' | head -n 50 | paste -sd, -); totaur=$(yay -Qm 2>/dev/null | wc -l); elif command -v paru >/dev/null 2>&1; then aurok=1; aurcmd='paru -Sua'; aur=$(paru -Qua 2>/dev/null | wc -l); laur=$(paru -Qua 2>/dev/null | awk '{print $1}' | head -n 50 | paste -sd, -); totaur=$(paru -Qm 2>/dev/null | wc -l); else totaur=0; fi; elif command -v apt >/dev/null 2>&1; then pm='apt'; cmd='sudo apt update && sudo apt upgrade'; sys=$(apt list --upgradable 2>/dev/null | awk 'NR>1' | wc -l); lsys=$(apt list --upgradable 2>/dev/null | awk 'NR>1' | cut -d/ -f1 | head -n 50 | paste -sd, -); totsys=$(dpkg-query -W -f='${binary:Package}\\n' 2>/dev/null | wc -l); totaur=0; elif command -v dnf >/dev/null 2>&1; then pm='dnf'; cmd='sudo dnf upgrade --refresh'; sys=$(dnf check-update -q 2>/dev/null | awk 'NF && $1 !~ /^Last/ {c++} END {print c+0}'); lsys=$(dnf check-update -q 2>/dev/null | awk 'NF && $1 !~ /^Last/ {print $1}' | head -n 50 | paste -sd, -); totsys=$(rpm -qa 2>/dev/null | wc -l); totaur=0; fi; if command -v flatpak >/dev/null 2>&1; then flat=$(flatpak remote-ls --updates 2>/dev/null | wc -l); [ -z \"$flat\" ] && flat=0; lflat=$(flatpak remote-ls --updates 2>/dev/null | head -n 50 | awk '{print $1}' | paste -sd, -); totflat=$(flatpak list 2>/dev/null | wc -l); fi; echo \"$pm|$sys|$aur|$flat|$cmd|$aurcmd|$aurok|$totsys|$totaur|$totflat\"; echo \"LIST_SYS:$lsys\"; echo \"LIST_AUR:$laur\"; echo \"LIST_FLAT:$lflat\""]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const lines = String(text).trim().split(/\r?\n/);
                const line0 = lines[0] || "";
                const parts = line0.split("|");
                const pm = String(parts[0] || "none");
                const sysRaw = String(parts[1] || "-").trim();
                const aurRaw = String(parts[2] || "-").trim();
                const flatRaw = String(parts[3] || "-").trim();
                const cmd = String(parts[4] || "-").trim();
                const aurCmd = String(parts[5] || "-").trim();
                const aurok = String(parts[6] || "0").trim() === "1";
                const totalSysRaw = String(parts[7] || "-").trim();
                const totalAurRaw = String(parts[8] || "-").trim();
                const totalFlatRaw = String(parts[9] || "-").trim();
                const sysCount = root._parseInt(sysRaw, -1);
                const aurCount = root._parseInt(aurRaw, -1);
                const flatCount = root._parseInt(flatRaw, -1);

                let lSys = "—";
                let lAur = "—";
                let lFlat = "—";
                for (let i = 1; i < lines.length; i++) {
                    const L = lines[i];
                    if (L.indexOf("LIST_SYS:") === 0) {
                        const t = L.slice(9).replace(/,/g, ", ");
                        lSys = t.length > 0 ? t : "—";
                    } else if (L.indexOf("LIST_AUR:") === 0) {
                        const t = L.slice(9).replace(/,/g, ", ");
                        lAur = t.length > 0 ? t : "—";
                    } else if (L.indexOf("LIST_FLAT:") === 0) {
                        const t = L.slice(10).replace(/,/g, ", ");
                        lFlat = t.length > 0 ? t : "—";
                    }
                }
                root.systemPackageList = lSys;
                root.aurPackageList = lAur;
                root.flatpakPackageList = lFlat;

                root.packageManager = pm === "none" ? "-" : pm;
                root.systemUpdateCount = sysCount >= 0 ? String(sysCount) : "-";
                root.aurUpdateCount = aurCount >= 0 ? String(aurCount) : "-";
                root.flatpakUpdateCount = flatCount >= 0 ? String(flatCount) : "-";
                root.systemPackageTotal = root._parseInt(totalSysRaw, -1) >= 0 ? String(root._parseInt(totalSysRaw, -1)) : "-";
                root.aurPackageTotal = root._parseInt(totalAurRaw, -1) >= 0 ? String(root._parseInt(totalAurRaw, -1)) : "-";
                root.flatpakPackageTotal = root._parseInt(totalFlatRaw, -1) >= 0 ? String(root._parseInt(totalFlatRaw, -1)) : "-";
                root.updateCommandHint = cmd.length > 0 && cmd !== "-" ? cmd : "-";
                root.aurCommandHint = aurCmd.length > 0 && aurCmd !== "-" ? aurCmd : "-";
                root.aurHelperDetected = aurok && (root.packageManager === "pacman");
                root.flatpakAvailable = flatCount >= 0;

                const total = Math.max(0, sysCount) + Math.max(0, aurCount);
                if (sysCount < 0 && aurCount < 0 && flatCount < 0)
                    root.updateSummary = "Update tools not available";
                else if (total === 0)
                    root.updateSummary = "System up to date";
                else
                    root.updateSummary = "Updates available";

                root.lastChecked = new Date().toLocaleTimeString();
                root.checkingUpdates = false;
                root.updatesLastFetchMs = Date.now();
            }
        }
    }

    Process { id: actionProc }

    Timer {
        interval: 90000
        running: root.checkingUpdates
        repeat: false
        onTriggered: root.checkingUpdates = false
    }

    // Background: periodic refresh while dashboard is open (not tied to the Updates tab).
    Timer {
        id: backgroundUpdatesTimer
        interval: Math.max(600000, root.dashboard.slowPollMs * 20)
        running: root.dashboard.visible
        repeat: true
        onTriggered: root.maybeRefreshIfStale()
    }

    // When the dashboard appears, run one deferred check; cache is reused on tab open unless stale.
    Timer {
        id: dashboardOpenKick
        interval: 400
        repeat: false
        onTriggered: root.maybeRefreshIfStale()
    }

    Connections {
        target: root.dashboard
        function onVisibleChanged() {
            if (root.dashboard.visible)
                dashboardOpenKick.restart();
        }
    }

    RowLayout {
        id: updatesMainRow
        anchors.fill: parent
        spacing: 8
        opacity: root.checkingUpdates ? 0.55 : 1
        Behavior on opacity { NumberAnimation { duration: 120 } }

        // 1 — Total installed packages (Pacman + AUR)
        Rectangle {
            id: colStats
            Layout.minimumWidth: 360
            Layout.fillHeight: true
            color: "transparent"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 0
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 10

                    UpdatesBatteryBar {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        barTitle: root.dashboard.config.formatUiText("Total Packages")
                        useSegmentSteps: false
                        fillOpacity: 0.2
                        segmentPercent: root._sysTotalPct
                        segmentColor: root.dashboard.config.dashboardUpdatesPackageBarFillColor
                        titleColor: root.dashboard.config.dashboardSystemAccentColor
                        mutedTextColor: root.dashboard.config.mutedTextColor
                        panelBorder: root.dashboard.dashboardAccent
                        borderW: root.dashboard.config.overlayBorderWidth
                        barRounding: root.dashboard.config.rounding
                        valuePixelSize: root.dashboard.uiFontSize + 18
                        bigValue: root.systemPackageTotal
                        smallLabel: root.dashboard.config.formatUiText("Pacman")
                    }

                    UpdatesBatteryBar {
                        visible: root.packageManager === "pacman"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        barTitle: root.dashboard.config.formatUiText("Total Packages")
                        useSegmentSteps: false
                        fillOpacity: 0.2
                        segmentPercent: root._aurTotalPct
                        segmentColor: root.dashboard.config.dashboardUpdatesAURBarFillColor
                        titleColor: root.dashboard.config.dashboardSystemAccentColor
                        mutedTextColor: root.dashboard.config.mutedTextColor
                        panelBorder: root.dashboard.dashboardAccent
                        borderW: root.dashboard.config.overlayBorderWidth
                        barRounding: root.dashboard.config.rounding
                        valuePixelSize: root.dashboard.uiFontSize + 18
                        bigValue: root.aurPackageTotal
                        smallLabel: root.dashboard.config.formatUiText("AUR")
                    }
                }
            }
        }

        // 2 — Updates available (Pacman + AUR)
        Rectangle {
            id: colBars
            Layout.minimumWidth: 360
            Layout.fillHeight: true
            color: "transparent"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 0
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 8
                        UpdatesBatteryBar {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            barTitle: root.dashboard.config.formatUiText("Total Updates")
                            segmentPercent: root._sysSegPct
                            segmentColor: root.dashboard.config.dashboardUpdatesSecurityBarFillColor
                            titleColor: root.dashboard.config.dashboardSystemAccentColor
                            mutedTextColor: root.dashboard.config.mutedTextColor
                            panelBorder: root.dashboard.dashboardAccent
                            borderW: root.dashboard.config.overlayBorderWidth
                            barRounding: root.dashboard.config.rounding
                            valuePixelSize: root.dashboard.uiFontSize + 18
                            bigValue: root.systemUpdateCount
                            smallLabel: root.dashboard.config.formatUiText("Pacman")
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            color: runSysArea.pressed ? Qt.rgba(root.dashboard.dashboardAccent.r, root.dashboard.dashboardAccent.g, root.dashboard.dashboardAccent.b, 0.15) : (runSysArea.containsMouse ? Qt.rgba(root.dashboard.dashboardAccent.r, root.dashboard.dashboardAccent.g, root.dashboard.dashboardAccent.b, 0.08) : "transparent")
                            border.width: root.dashboard.config.buttonBorderWidth
                            border.color: root.dashboard.config.overlayAccentColor
                            radius: Math.max(0, root.dashboard.dashboardSurfaceRounding - 3)
                            visible: root.updateCommandHint && root.updateCommandHint !== "-"
                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Label { text: "▶"; color: root.dashboard.dashboardTextColor; font.pixelSize: root.dashboard.uiFontSize + 4 }
                                Label { text: root.dashboard.config.formatUiText("Update"); color: root.dashboard.dashboardTextColor; font.pixelSize: root.dashboard.uiFontSize - 1 }
                            }
                            MouseArea { id: runSysArea; anchors.fill: parent; hoverEnabled: true; onClicked: root.runSystemUpdateInTerminal() }
                        }
                    }

                ColumnLayout {
                    visible: root.packageManager === "pacman"
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8
                    UpdatesBatteryBar {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        barTitle: root.dashboard.config.formatUiText("Total Updates")
                        segmentPercent: root._aurSegPct
                        segmentColor: root.dashboard.config.dashboardUpdatesKernelBarFillColor
                        titleColor: root.dashboard.config.dashboardSystemAccentColor
                        mutedTextColor: root.dashboard.config.mutedTextColor
                        panelBorder: root.dashboard.dashboardAccent
                        borderW: root.dashboard.config.overlayBorderWidth
                        barRounding: root.dashboard.config.rounding
                        valuePixelSize: root.dashboard.uiFontSize + 18
                        bigValue: root.aurUpdateCount
                        smallLabel: root.dashboard.config.formatUiText("AUR")
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        color: runAurArea.pressed ? Qt.rgba(root.dashboard.dashboardAccent.r, root.dashboard.dashboardAccent.g, root.dashboard.dashboardAccent.b, 0.15) : (runAurArea.containsMouse ? Qt.rgba(root.dashboard.dashboardAccent.r, root.dashboard.dashboardAccent.g, root.dashboard.dashboardAccent.b, 0.08) : "transparent")
                        border.width: root.dashboard.config.buttonBorderWidth
                        border.color: root.dashboard.config.overlayAccentColor
                        radius: Math.max(0, root.dashboard.dashboardSurfaceRounding - 3)
                        visible: root.aurCommandHint && root.aurCommandHint !== "-"
                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Label { text: "▶"; color: root.dashboard.dashboardTextColor; font.pixelSize: root.dashboard.uiFontSize + 4 }
                            Label { text: root.dashboard.config.formatUiText("Update"); color: root.dashboard.dashboardTextColor; font.pixelSize: root.dashboard.uiFontSize - 1 }
                        }
                        MouseArea { id: runAurArea; anchors.fill: parent; hoverEnabled: true; onClicked: root.runAurUpdateInTerminal() }
                    }
                }
                }
            }
        }

        // 3 — Update detail column
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            // Separate rectangle outside the "Updates available" panel
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 200
                color: "transparent"
                radius: root.dashboard.config.rounding

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 0
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Math.max(0, root.dashboard.config.rounding - 2)
                        color: "transparent"
                        border.width: root.dashboard.config.buttonBorderWidth
                        border.color: root.dashboard.config.overlayAccentColor
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 4

                            Label {
                                text: root.dashboard.config.formatUiText("Disk")
                                color: root.dashboard.config.dashboardSystemAccentColor
                                font.bold: true
                                font.pixelSize: Math.max(10, root.dashboard.uiFontSize - 1)
                                horizontalAlignment: Text.AlignLeft
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                            }
                            Canvas {
                                id: pendingRadial
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                property real pct: Math.max(0, Math.min(100, Number(root.dashboard.diskPercent) || 0))
                                onWidthChanged: requestPaint()
                                onHeightChanged: requestPaint()
                                onPctChanged: requestPaint()
                                Component.onCompleted: requestPaint()
                                onPaint: {
                                    const ctx = getContext("2d");
                                    ctx.reset();
                                    const cx = width / 2;
                                    const cy = height / 2;
                                    const r = Math.max(10, Math.min(width, height) / 2 - 5);
                                    const start = -Math.PI / 2;
                                    const end = start + (2 * Math.PI * Math.max(0, Math.min(100, pct)) / 100);
                                    ctx.lineWidth = 6;
                                    ctx.strokeStyle = Qt.rgba(root.dashboard.config.mutedTextColor.r, root.dashboard.config.mutedTextColor.g, root.dashboard.config.mutedTextColor.b, 0.25);
                                    ctx.beginPath();
                                    ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                                    ctx.stroke();
                                    ctx.strokeStyle = root.dashboard.config.dashboardUpdatesSystemRadialFillColor;
                                    ctx.beginPath();
                                    ctx.arc(cx, cy, r, start, end);
                                    ctx.stroke();
                                }
                            }
                            Label {
                                text: root.dashboard.config.formatUiText(String(Math.round(pendingRadial.pct)) + "%")
                                color: root.dashboard.config.dashboardUpdatesSystemRadialFillColor
                                font.pixelSize: Math.max(9, root.dashboard.uiFontSize - 2)
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Math.max(0, root.dashboard.config.rounding - 2)
                        color: "transparent"
                        border.width: root.dashboard.config.buttonBorderWidth
                        border.color: root.dashboard.config.overlayAccentColor
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 4

                            Label {
                                text: root.dashboard.config.formatUiText("Load")
                                color: root.dashboard.config.dashboardSystemAccentColor
                                font.bold: true
                                font.pixelSize: Math.max(10, root.dashboard.uiFontSize - 1)
                                horizontalAlignment: Text.AlignLeft
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                            }
                            Canvas {
                                id: pacmanShareRadial
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                property real pct: root._installedTotal > 0 ? root._updateLoadPct : 0
                                onWidthChanged: requestPaint()
                                onHeightChanged: requestPaint()
                                onPctChanged: requestPaint()
                                Component.onCompleted: requestPaint()
                                onPaint: {
                                    const ctx = getContext("2d");
                                    ctx.reset();
                                    const cx = width / 2;
                                    const cy = height / 2;
                                    const r = Math.max(10, Math.min(width, height) / 2 - 5);
                                    const start = -Math.PI / 2;
                                    const end = start + (2 * Math.PI * Math.max(0, Math.min(100, pct)) / 100);
                                    ctx.lineWidth = 6;
                                    ctx.strokeStyle = Qt.rgba(root.dashboard.config.mutedTextColor.r, root.dashboard.config.mutedTextColor.g, root.dashboard.config.mutedTextColor.b, 0.25);
                                    ctx.beginPath();
                                    ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                                    ctx.stroke();
                                    ctx.strokeStyle = root.dashboard.config.dashboardUpdatesPackageRadialFillColor;
                                    ctx.beginPath();
                                    ctx.arc(cx, cy, r, start, end);
                                    ctx.stroke();
                                }
                            }
                            Label {
                                text: root.dashboard.config.formatUiText(String(root._updateLoadPct) + "%")
                                color: root.dashboard.config.dashboardUpdatesPackageRadialFillColor
                                font.pixelSize: Math.max(9, root.dashboard.uiFontSize - 2)
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Math.max(0, root.dashboard.config.rounding - 2)
                        color: "transparent"
                        border.width: root.dashboard.config.buttonBorderWidth
                        border.color: root.dashboard.config.overlayAccentColor
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 4

                            Label {
                                text: root.dashboard.config.formatUiText("Sources")
                                color: root.dashboard.config.dashboardSystemAccentColor
                                font.bold: true
                                font.pixelSize: Math.max(10, root.dashboard.uiFontSize - 1)
                                horizontalAlignment: Text.AlignLeft
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                            }
                            Canvas {
                                id: flatpakRadial
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                property real pct: root._sourceTotal > 0 ? root._pacmanSourcePct : 0
                                onWidthChanged: requestPaint()
                                onHeightChanged: requestPaint()
                                onPctChanged: requestPaint()
                                Component.onCompleted: requestPaint()
                                onPaint: {
                                    const ctx = getContext("2d");
                                    ctx.reset();
                                    const cx = width / 2;
                                    const cy = height / 2;
                                    const r = Math.max(10, Math.min(width, height) / 2 - 5);
                                    const start = -Math.PI / 2;
                                    const end = start + (2 * Math.PI * Math.max(0, Math.min(100, pct)) / 100);
                                    ctx.lineWidth = 6;
                                    ctx.strokeStyle = Qt.rgba(root.dashboard.config.mutedTextColor.r, root.dashboard.config.mutedTextColor.g, root.dashboard.config.mutedTextColor.b, 0.25);
                                    ctx.beginPath();
                                    ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                                    ctx.stroke();
                                    ctx.strokeStyle = root.dashboard.config.dashboardUpdatesSecurityRadialFillColor;
                                    ctx.beginPath();
                                    ctx.arc(cx, cy, r, start, end);
                                    ctx.stroke();
                                }
                            }
                            Label {
                                text: root.dashboard.config.formatUiText(root._sourceTotal > 0
                                        ? (String(root._pacmanSourcePct) + "%" + "/" + String(root._aurSourcePct)+ "%" + "/" + String(root._otherSourcePct) + "%")
                                        : "—")
                                color: root.dashboard.config.dashboardUpdatesSecurityRadialFillColor
                                font.pixelSize: Math.max(9, root.dashboard.uiFontSize - 2)
                                horizontalAlignment: Text.AlignHCenter
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"
                border.color: root.dashboard.dashboardAccent
                border.width: root.dashboard.config.overlayBorderWidth
                radius: root.dashboard.config.rounding

                ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                Label {
                    text: root.dashboard.config.formatUiText("Updates available")
                    color: root.dashboard.dashboardTextColor
                    font.bold: true
                    font.pixelSize: root.dashboard.uiFontSize + 2
                }
                Label {
                    text: root.lastChecked
                    color: root.dashboard.config.mutedTextColor
                    font.pixelSize: Math.max(10, root.dashboard.uiFontSize - 1)
                }

                Label {
                    text: root.dashboard.config.formatUiText("Status") + ": " + root.updateSummary
                    color: root.dashboard.config.mutedTextColor
                    font.pixelSize: Math.max(9, root.dashboard.uiFontSize - 1)
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                Label {
                    text: root.dashboard.config.formatUiText("Pending total") + ": " + String(root._updatesTotal)
                    color: root.dashboard.dashboardTextColor
                    font.bold: true
                    font.pixelSize: root.dashboard.uiFontSize + 4
                }
                Label {
                    text: root.dashboard.config.formatUiText("Package managers") + ": "
                        + root.dashboard.config.formatUiText("Pacman") + " " + root.systemUpdateCount
                        + (root.aurHelperDetected ? ("   AUR " + root.aurUpdateCount) : "")
                        + (root.flatpakAvailable ? ("   Flatpak " + root.flatpakUpdateCount) : "")
                    color: root.dashboard.config.mutedTextColor
                    font.pixelSize: Math.max(9, root.dashboard.uiFontSize - 1)
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                Label {
                    text: root.dashboard.config.formatUiText("Update command") + ": " + (root.updateCommandHint && root.updateCommandHint !== "-" ? root.updateCommandHint : "—")
                    color: root.dashboard.config.mutedTextColor
                    font.pixelSize: Math.max(9, root.dashboard.uiFontSize - 1)
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                Label {
                    text: root.dashboard.config.formatUiText("AUR helper") + ": "
                        + (root.aurHelperDetected ? root.dashboard.config.formatUiText("Detected") : root.dashboard.config.formatUiText("Not detected"))
                    color: root.dashboard.config.mutedTextColor
                    font.pixelSize: Math.max(9, root.dashboard.uiFontSize - 1)
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
                Label {
                    text: root.dashboard.config.formatUiText("Top pending packages") + ": "
                        + ((root.systemPackageList && root.systemPackageList !== "—")
                            ? root.systemPackageList.split(", ").slice(0, 4).join(", ")
                            : "—")
                    color: root.dashboard.config.mutedTextColor
                    font.pixelSize: Math.max(9, root.dashboard.uiFontSize - 1)
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        id: refreshBtn
                        Layout.fillWidth: true
                        implicitHeight: 48
                        color: refreshHover.containsMouse ? Qt.rgba(root.dashboard.dashboardAccent.r, root.dashboard.dashboardAccent.g, root.dashboard.dashboardAccent.b, 0.12) : "transparent"
                        border.width: root.dashboard.config.buttonBorderWidth
                        border.color: root.checkingUpdates ? root.dashboard.dashboardAccent : root.dashboard.config.overlayAccentColor
                        radius: Math.max(0, root.dashboard.dashboardSurfaceRounding - 3)
                        scale: root.checkingUpdates ? 0.98 : 1
                        Behavior on scale { NumberAnimation { duration: 100 } }
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8
                            Label { text: root.checkingUpdates ? "…" : "↻"; color: root.dashboard.dashboardTextColor; font.pixelSize: root.dashboard.uiFontSize + 10 }
                            Label {
                                text: root.dashboard.config.formatUiText("Check for updates")
                                color: root.dashboard.dashboardTextColor
                                font.pixelSize: root.dashboard.uiFontSize
                                Layout.fillWidth: true
                            }
                        }
                        MouseArea {
                            id: refreshHover
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !root.checkingUpdates
                            onClicked: root.refreshUpdates()
                        }
                    }
                }
            }
        }
        }
    }
}
