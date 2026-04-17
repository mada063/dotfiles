import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    required property QtObject shell
    required property QtObject config

    // Same as dashboard edge trigger: draw above the top bar so y=0 is the screen top.
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: 0
        left: root.config.barOrientation === "left" ? 88 : 0
        right: 0
    }

    color: "transparent"
    readonly property int panelWidth: root.width > 0 ? Math.min(root.width - 40, Math.max(860, Math.round(root.width * 0.74))) : 920
    readonly property int basePanelHeight: Math.max(560, Math.min(760, Math.round(root.panelWidth * 0.64)))
    readonly property int overviewPanelHeight: Math.max(420, Math.min(760, overviewTab.implicitHeight + dashboardTabs.implicitHeight + 40))
    readonly property int panelHeight: dashboardTabs.currentIndex === 0 ? overviewPanelHeight : basePanelHeight
    implicitHeight: root.visible ? root.panelHeight : 0
    exclusiveZone: 0

    property string avatarText: "QS"
    property string weatherTemp: "-"
    property string weatherSummary: "-"
    property string osInfo: "-"
    property string wmInfo: "WM: " + root.shell.detectedWindowManagerName
    property string uptimeInfo: "-"
    property string mediaInfo: "-"
    property string mediaState: "-"
    property string timeHour: "--"
    property string timeMinute: "--"
    property string timeSecond: "--"
    property string monthLabel: "-"
    property var weekdayLabels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    property var calendarCells: []
    property int cpuUsage: 0
    property string cpuName: "CPU"
    property int cpuTemp: 0
    property int gpuUsage: 0
    property string gpuName: "No GPU"
    property int gpuTemp: 0
    property int ramPercent: 0
    property string ramUsedText: "-"
    property string ramTotalText: "-"
    property int diskPercent: 0
    property string diskUsedText: "-"
    property string diskTotalText: "-"
    property string netIface: "-"
    property real netDownRate: 0
    property real netUpRate: 0
    property string netDownText: "0 B/s"
    property string netUpText: "0 B/s"
    property string netTotalText: "0 B"
    property var netDownHistory: []
    property var netUpHistory: []
    property double prevRxBytes: -1
    property double prevTxBytes: -1
    property double prevNetTimestamp: 0
    property int batteryPercent: 0
    property string batteryStatus: "-"
    property bool hasGpu: root.gpuName !== "No GPU" || root.gpuUsage > 0 || root.gpuTemp > 0
    // Hide GPU widgets unless we are confident this is a discrete card (iGPU/APU/unknown PCI strings default to integrated).
    readonly property bool gpuLooksIntegrated: {
        const n = String(root.gpuName || "").toLowerCase();
        if (!n || n === "no gpu")
            return true;
        if (n.includes("nvidia"))
            return false;
        if (n.includes("intel") && n.includes("arc"))
            return false;
        if (n.includes("intel"))
            return true;
        const amdDiscrete = /\brx\s*[0-9]{3,5}\b|\bradeon\s*pro\b|\bfirepro\b|\bw[67][0-9]{3}\b/;
        const isAmdVendor = n.includes("amd") || n.includes("ati ") || n.includes("/ati]") || n.includes("advanced micro devices");
        if (isAmdVendor && amdDiscrete.test(n))
            return false;
        if (isAmdVendor)
            return true;
        const ig = ["iris", "uhd", "hd graphics", "llvmpipe", "microsoft", "vmware", "virtio", "qxl", "mali", "panfrost", "aspeed", "matrox", "zink", "red hat", "bochs", "cirrus"];
        for (let i = 0; i < ig.length; i++) {
            if (n.includes(ig[i]))
                return true;
        }
        return true;
    }
    readonly property bool hasDiscreteGpu: root.hasGpu && !root.gpuLooksIntegrated
    readonly property int fastPollMs: Math.max(300, root.config.dashboardFastPollMs)
    readonly property int mediumPollMs: Math.max(1000, root.config.dashboardMediumPollMs)
    readonly property int slowPollMs: Math.max(3000, root.config.dashboardSlowPollMs)
    readonly property string uiFontFamily: root.config.fontFamily
    readonly property int uiFontSize: root.config.fontPixelSize
    readonly property color dashboardAccent: root.config.dashboardColor
    readonly property color dashboardTextColor: root.config.dashboardTextColor
    readonly property color dashboardBackgroundColor: root.config.dashboardBackgroundColor
    readonly property int dashboardSurfaceRounding: root.config.dashboardRounding
    Behavior on cpuUsage { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on gpuUsage { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on ramPercent { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on diskPercent { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on batteryPercent { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on cpuTemp { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Behavior on gpuTemp { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    function _applyFontRecursive(node) {
        if (!node)
            return;
        try {
            if (node.font !== undefined) {
                node.font.family = root.uiFontFamily;
                if (node.qsKeepPixelSize !== true)
                    node.font.pixelSize = root.uiFontSize;
            }
        } catch (e) {}
        const kids = node.children || [];
        for (let i = 0; i < kids.length; i++)
            _applyFontRecursive(kids[i]);
        if (node.contentItem)
            _applyFontRecursive(node.contentItem);
    }

    function _formatBytes(bytes) {
        const value = Math.max(0, Number(bytes) || 0);
        const units = ["B", "KB", "MB", "GB", "TB"];
        let size = value;
        let idx = 0;
        while (size >= 1024 && idx < units.length - 1) {
            size /= 1024;
            idx++;
        }
        return (size >= 10 || idx === 0 ? size.toFixed(0) : size.toFixed(1)) + " " + units[idx];
    }

    function _formatRate(bytesPerSec) {
        return _formatBytes(bytesPerSec) + "/s";
    }

    function _pushHistory(list, value) {
        const next = list.slice();
        next.push(Math.max(0, Number(value) || 0));
        while (next.length > 32)
            next.shift();
        return next;
    }

    function _updateClock() {
        const now = new Date();
        timeHour = String(now.getHours()).padStart(2, "0");
        timeMinute = String(now.getMinutes()).padStart(2, "0");
        timeSecond = String(now.getSeconds()).padStart(2, "0");
        if (now.getMonth() !== calendarMonth || now.getFullYear() !== calendarYear) {
            calendarMonth = now.getMonth();
            calendarYear = now.getFullYear();
            _rebuildCalendar();
        }
    }

    property int calendarMonth: -1
    property int calendarYear: -1

    function _rebuildCalendar() {
        const months = [
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        ];
        const now = new Date();
        const year = now.getFullYear();
        const month = now.getMonth();
        const firstDay = new Date(year, month, 1);
        const startOffset = (firstDay.getDay() + 6) % 7;
        const daysInMonth = new Date(year, month + 1, 0).getDate();
        const daysInPrevMonth = new Date(year, month, 0).getDate();
        let cells = [];

        for (let i = 0; i < 42; i++) {
            let dayNumber = 0;
            let inMonth = true;
            if (i < startOffset) {
                dayNumber = daysInPrevMonth - startOffset + i + 1;
                inMonth = false;
            } else if (i >= startOffset + daysInMonth) {
                dayNumber = i - startOffset - daysInMonth + 1;
                inMonth = false;
            } else {
                dayNumber = i - startOffset + 1;
            }
            const weekday = i % 7;
            cells.push({
                day: dayNumber,
                inMonth: inMonth,
                weekend: weekday >= 5,
                today: inMonth && dayNumber === now.getDate()
            });
        }

        monthLabel = months[month] + " " + year;
        calendarCells = cells;
    }

    onUiFontFamilyChanged: _applyFontRecursive(root)
    onUiFontSizeChanged: _applyFontRecursive(root)
    Component.onCompleted: {
        _updateClock();
        _rebuildCalendar();
        _applyFontRecursive(root);
    }

    function closeDashboard() {
        root.shell.dashboardVisible = false;
        root.shell.dashboardOverlayHovered = false;
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.visible
        onClicked: root.closeDashboard()
    }

    Rectangle {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.panelWidth
        height: root.panelHeight
        color: root.dashboardBackgroundColor
        opacity: root.config.panelOpacity
        border.color: root.dashboardAccent
        border.width: root.config.overlayBorderWidth
        radius: root.dashboardSurfaceRounding
        clip: true
        layer.enabled: true

        transform: Translate {
            y: root.visible ? 0 : -root.panelHeight
            Behavior on y {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.bottomMargin: 12
            anchors.topMargin: 0
            spacing: 8

            TabBar {
                id: dashboardTabs
                Layout.fillWidth: true
                currentIndex: 0
                spacing: 8
                onCurrentIndexChanged: {
                    if (currentIndex === 1 && performanceTab.networkCanvas && root.netDownHistory.length > 1)
                        performanceTab.networkCanvas.requestPaint();
                }
                background: Rectangle {
                    color: "transparent"
                    border.width: root.config.buttonBorderWidth
                    border.color: root.dashboardAccent
                    radius: Math.max(0, root.dashboardSurfaceRounding - 2)
                }
                TabButton {
                    id: dashboardTabButton
                    text: "Dashboard"
                    implicitHeight: 30
                    implicitWidth: 128
                    background: Rectangle {
                        radius: Math.max(0, root.config.rounding - 2)
                        color: dashboardTabButton.checked ? Qt.rgba(root.dashboardAccent.r, root.dashboardAccent.g, root.dashboardAccent.b, 0.18) : "transparent"
                        border.width: root.config.buttonBorderWidth
                        border.color: dashboardTabButton.checked ? root.dashboardAccent : root.config.overlayAccentColor
                    }
                    contentItem: Text {
                        text: dashboardTabButton.text
                        color: dashboardTabButton.checked ? root.dashboardAccent : root.dashboardTextColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: root.uiFontFamily
                        font.pixelSize: root.uiFontSize
                        font.bold: dashboardTabButton.checked
                    }
                }
                TabButton {
                    id: performanceTabButton
                    text: "Performance"
                    implicitHeight: 30
                    implicitWidth: 128
                    background: Rectangle {
                        radius: Math.max(0, root.config.rounding - 2)
                        color: performanceTabButton.checked ? Qt.rgba(root.dashboardAccent.r, root.dashboardAccent.g, root.dashboardAccent.b, 0.18) : "transparent"
                        border.width: root.config.buttonBorderWidth
                        border.color: performanceTabButton.checked ? root.dashboardAccent : root.config.overlayAccentColor
                    }
                    contentItem: Text {
                        text: performanceTabButton.text
                        color: performanceTabButton.checked ? root.dashboardAccent : root.dashboardTextColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: root.uiFontFamily
                        font.pixelSize: root.uiFontSize
                        font.bold: performanceTabButton.checked
                    }
                }
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: dashboardTabs.currentIndex

                DashboardOverview {
                    id: overviewTab
                    dashboard: root
                    mediaPrevProc: mediaPrev
                    mediaToggleProc: mediaToggle
                    mediaNextProc: mediaNext
                }

                DashboardPerformance {
                    id: performanceTab
                    dashboard: root
                }
            }
        }

        HoverHandler {
            onHoveredChanged: {
                if (hovered) {
                    overlayReleaseTimer.stop();
                    root.shell.dashboardOverlayHovered = true;
                } else {
                    overlayReleaseTimer.start();
                }
            }
        }
    }

    Process {
        id: weatherTempProc
        command: ["bash", "-lc", "if command -v curl >/dev/null 2>&1; then curl -fsS 'https://wttr.in/?format=%t' 2>/dev/null; else echo '-'; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const value = String(text).trim().replace(/°[CF]/gi, "").replace(/^\+/, "");
                if (value)
                    root.weatherTemp = value;
            }
        }
    }

    Process {
        id: weatherSummaryProc
        command: ["bash", "-lc", "if command -v curl >/dev/null 2>&1; then curl -fsS 'https://wttr.in/?format=%C' 2>/dev/null; else echo '-'; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.weatherSummary = String(text).trim() || "-"
        }
    }

    Process {
        id: avatarProc
        command: ["bash", "-lc", "printf '%s' \"${USER:-QS}\" | cut -c1-2 | tr '[:lower:]' '[:upper:]'"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.avatarText = String(text).trim() || "QS"
        }
    }

    Process {
        id: osProc
        command: ["bash", "-lc", "if [ -r /etc/os-release ]; then . /etc/os-release; echo \"$PRETTY_NAME\"; else uname -sr; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.osInfo = String(text).trim() || "-"
        }
    }

    Process {
        id: uptimeProc
        command: ["bash", "-lc", "uptime -p 2>/dev/null | sed 's/^up /Uptime: /'"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.uptimeInfo = String(text).trim() || "-"
        }
    }

    Process {
        id: cpuUsageProc
        command: ["bash", "-lc", "read _ a b c idle rest < /proc/stat; total1=$((a+b+c+idle)); idle1=$idle; sleep 0.2; read _ a b c idle rest < /proc/stat; total2=$((a+b+c+idle)); idle2=$idle; diff=$((total2-total1)); idiff=$((idle2-idle1)); if [ \"$diff\" -gt 0 ]; then echo $(( (100*(diff-idiff))/diff )); else echo 0; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const value = String(text).trim();
                if (!value)
                    return;
                const parsed = Number(value);
                if (Number.isFinite(parsed))
                    root.cpuUsage = Math.max(0, Math.min(100, parsed));
            }
        }
    }

    Process {
        id: cpuInfoProc
        command: ["bash", "-lc", "name=$(awk -F: '/model name/ {gsub(/^[ \\t]+/,\"\",$2); print $2; exit}' /proc/cpuinfo); temp=$(if command -v sensors >/dev/null 2>&1; then sensors | awk '/Package id 0:|Tctl:|temp1:/ {gsub(/[+°C]/,\"\",$2); print int($2); exit}'; elif [ -r /sys/class/thermal/thermal_zone0/temp ]; then awk '{print int($1/1000)}' /sys/class/thermal/thermal_zone0/temp; else echo 0; fi); echo \"${name:-CPU}|${temp:-0}\""]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const value = String(text).trim();
                if (!value)
                    return;
                const parts = value.split("|");
                if (parts[0])
                    root.cpuName = parts[0];
                const parsedTemp = Number(parts[1]);
                if (Number.isFinite(parsedTemp))
                    root.cpuTemp = Math.max(0, Math.min(100, parsedTemp));
            }
        }
    }

    Process {
        id: gpuUsageProc
        command: ["bash", "-lc", "if command -v nvidia-smi >/dev/null 2>&1; then nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -n1; elif [ -r /sys/class/drm/card0/device/gpu_busy_percent ]; then cat /sys/class/drm/card0/device/gpu_busy_percent; else echo 0; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const value = String(text).trim();
                if (!value)
                    return;
                const parsed = Number(value);
                if (Number.isFinite(parsed))
                    root.gpuUsage = Math.max(0, Math.min(100, parsed));
            }
        }
    }

    Process {
        id: gpuInfoProc
        command: ["bash", "-lc", "if command -v nvidia-smi >/dev/null 2>&1; then nvidia-smi --query-gpu=name,temperature.gpu --format=csv,noheader,nounits | head -n1 | awk -F', ' '{print $1\"|\"$2}'; else name=$(if command -v lspci >/dev/null 2>&1; then lspci | awk '/VGA compatible controller|3D controller|Display controller/ {sub(/.*: /, \"\"); print; exit}'; else echo 'No GPU'; fi); temp=$(for f in /sys/class/drm/card?/device/hwmon/hwmon*/temp1_input; do if [ -r \"$f\" ]; then awk '{print int($1/1000)}' \"$f\"; break; fi; done); echo \"${name:-No GPU}|${temp:-0}\"; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const value = String(text).trim();
                if (!value)
                    return;
                const parts = value.split("|");
                if (parts[0])
                    root.gpuName = parts[0];
                const parsedTemp = Number(parts[1]);
                if (Number.isFinite(parsedTemp))
                    root.gpuTemp = Math.max(0, Math.min(100, parsedTemp));
            }
        }
    }

    Process {
        id: ramProc
        command: ["bash", "-lc", "awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {u=t-a; if (t>0) printf \"%d|%.1f GiB|%.1f GiB\", (u*100)/t, u/1048576, t/1048576; else print \"0|-|-\"}' /proc/meminfo"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const value = String(text).trim();
                if (!value)
                    return;
                const parts = value.split("|");
                const parsedPercent = Number(parts[0]);
                if (Number.isFinite(parsedPercent))
                    root.ramPercent = Math.max(0, Math.min(100, parsedPercent));
                if (parts[1])
                    root.ramUsedText = parts[1];
                if (parts[2])
                    root.ramTotalText = parts[2];
            }
        }
    }

    Process {
        id: diskProc
        command: ["bash", "-lc", "df -B1 / | awk 'NR==2{printf \"%d|%.1f GiB|%.1f GiB\", int(($3/$2)*100), $3/1073741824, $2/1073741824}'"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const value = String(text).trim();
                if (!value)
                    return;
                const parts = value.split("|");
                const parsedPercent = Number(parts[0]);
                if (Number.isFinite(parsedPercent))
                    root.diskPercent = Math.max(0, Math.min(100, parsedPercent));
                if (parts[1])
                    root.diskUsedText = parts[1];
                if (parts[2])
                    root.diskTotalText = parts[2];
            }
        }
    }

    Process {
        id: mediaProc
        command: ["bash", "-lc", "if command -v playerctl >/dev/null 2>&1; then echo \"$(playerctl status 2>/dev/null || echo Stopped)|$(playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null || echo '-')\"; else echo 'Stopped|-'; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const value = String(text).trim();
                const idx = value.indexOf("|");
                if (idx > -1) {
                    root.mediaState = value.slice(0, idx) || "Stopped";
                    root.mediaInfo = value.slice(idx + 1) || "-";
                } else {
                    root.mediaState = "Stopped";
                    root.mediaInfo = value || "-";
                }
            }
        }
    }

    Process {
        id: netProc
        command: ["bash", "-lc", "iface=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}'); if [ -n \"$iface\" ] && [ -r \"/sys/class/net/$iface/statistics/rx_bytes\" ]; then rx=$(cat \"/sys/class/net/$iface/statistics/rx_bytes\"); tx=$(cat \"/sys/class/net/$iface/statistics/tx_bytes\"); echo \"$iface|$rx|$tx\"; else echo '-|0|0'; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const parts = String(text).trim().split("|");
                const iface = parts[0] || "-";
                const rx = Number(parts[1] || "0") || 0;
                const tx = Number(parts[2] || "0") || 0;
                const nowMs = Date.now();

                root.netIface = iface;
                root.netTotalText = root._formatBytes(rx + tx);

                if (root.prevNetTimestamp > 0) {
                    const elapsed = Math.max(0.2, (nowMs - root.prevNetTimestamp) / 1000);
                    const downRate = Math.max(0, (rx - root.prevRxBytes) / elapsed);
                    const upRate = Math.max(0, (tx - root.prevTxBytes) / elapsed);
                    root.netDownRate = downRate;
                    root.netUpRate = upRate;
                    root.netDownText = root._formatRate(downRate);
                    root.netUpText = root._formatRate(upRate);
                    root.netDownHistory = root._pushHistory(root.netDownHistory, downRate);
                    root.netUpHistory = root._pushHistory(root.netUpHistory, upRate);
                    if (root.visible && dashboardTabs.currentIndex === 1 && performanceTab.networkCanvas)
                        performanceTab.networkCanvas.requestPaint();
                }

                root.prevRxBytes = rx;
                root.prevTxBytes = tx;
                root.prevNetTimestamp = nowMs;
            }
        }
    }

    Process {
        id: batteryProc
        command: ["bash", "-lc", "if command -v acpi >/dev/null 2>&1; then acpi -b | head -n1 | awk -F', ' '{gsub(/%/,\"\",$2); print $1\"|\"$2}'; else bat=$(ls /sys/class/power_supply 2>/dev/null | awk '/^BAT/{print; exit}'); if [ -n \"$bat\" ] && [ -r \"/sys/class/power_supply/$bat/status\" ]; then echo \"$(cat /sys/class/power_supply/$bat/status)|$(cat /sys/class/power_supply/$bat/capacity)\"; else echo '-|0'; fi; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const value = String(text).trim();
                if (!value)
                    return;
                const parts = value.split("|");
                const statusRaw = parts[0] || "-";
                const idx = statusRaw.indexOf(": ");
                root.batteryStatus = idx > -1 ? statusRaw.slice(idx + 2) : statusRaw;
                const parsedPercent = Number(parts[1]);
                if (Number.isFinite(parsedPercent))
                    root.batteryPercent = Math.max(0, Math.min(100, parsedPercent));
            }
        }
    }

    Process { id: mediaPrev; command: ["bash", "-lc", "if command -v playerctl >/dev/null 2>&1; then playerctl previous; fi"] }
    Process { id: mediaToggle; command: ["bash", "-lc", "if command -v playerctl >/dev/null 2>&1; then playerctl play-pause; fi"] }
    Process { id: mediaNext; command: ["bash", "-lc", "if command -v playerctl >/dev/null 2>&1; then playerctl next; fi"] }

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: root._updateClock()
    }

    Timer {
        interval: root.fastPollMs
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!cpuUsageProc.running)
                cpuUsageProc.exec({ command: cpuUsageProc.command });
            if (!gpuUsageProc.running)
                gpuUsageProc.exec({ command: gpuUsageProc.command });
            if (!ramProc.running)
                ramProc.exec({ command: ramProc.command });
            if (!mediaProc.running)
                mediaProc.exec({ command: mediaProc.command });
        }
    }

    Timer {
        interval: root.fastPollMs
        running: root.visible && dashboardTabs.currentIndex === 1
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!netProc.running)
                netProc.exec({ command: netProc.command });
        }
    }

    Timer {
        interval: root.mediumPollMs
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!diskProc.running)
                diskProc.exec({ command: diskProc.command });
            if (!batteryProc.running)
                batteryProc.exec({ command: batteryProc.command });
        }
    }

    Timer {
        interval: root.slowPollMs
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!weatherTempProc.running)
                weatherTempProc.exec({ command: weatherTempProc.command });
            if (!weatherSummaryProc.running)
                weatherSummaryProc.exec({ command: weatherSummaryProc.command });
            if (!avatarProc.running)
                avatarProc.exec({ command: avatarProc.command });
            if (!osProc.running)
                osProc.exec({ command: osProc.command });
            if (!uptimeProc.running)
                uptimeProc.exec({ command: uptimeProc.command });
            if (!cpuInfoProc.running)
                cpuInfoProc.exec({ command: cpuInfoProc.command });
            if (!gpuInfoProc.running)
                gpuInfoProc.exec({ command: gpuInfoProc.command });
        }
    }

    Timer {
        id: overlayReleaseTimer
        interval: root.config.hoverReleaseMs
        repeat: false
        onTriggered: {
            root.shell.dashboardOverlayHovered = false;
            if (!root.shell.dashboardTriggerHovered)
                root.shell.dashboardVisible = false;
        }
    }
}
