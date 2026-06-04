import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    required property QtObject config
    /// When false, timers stay off (use a single shared hub; bars bind to its properties).
    property bool pollingEnabled: true
    /// Heavy hyprctl + icon resolution; skip when the bar only needs workspace occupancy counts.
    property bool workspaceClientsPollingEnabled: true
    property bool includeLocks: false
    /// Top bar clock via `date`; left bar uses in-QML clock and should set this false.
    property bool clockPollingEnabled: true
    property string dateCommand: "date '+%a %d %b %H:%M'"
    width: 0
    height: 0

    readonly property int mediumPollMs: root.config.barMediumPollMs
    readonly property int slowPollMs: root.config.barSlowPollMs
    readonly property int workspacePollMs: root.config.barWorkspacePollMs

    property string dateText: "--"
    property int batteryPercent: 0
    property bool capsLockOn: false
    property bool numLockOn: false
    property string wifiDetailText: "-"
    property string btDetailText: "-"
    property int volumePercent: 0
    property bool volumeMuted: false
    property int brightnessPercent: 50
    property bool networkEnabled: true
    property string networkDisplayText: "OFFLINE"
    property string networkTypeText: "Offline"
    property string wifiDeviceName: ""
    property bool wifiConnected: false
    property bool btEnabled: false
    property bool btDiscoverable: false
    property var audioOutputs: []
    property var audioInputs: []
    property string batteryTimeText: "-"
    property string batteryStatusText: "-"
    property string pendingStatusMenuRefresh: ""
    property string wifiConnectSsid: ""
    property string wifiConnectPassword: ""
    property string wifiConnectError: ""
    property bool wifiConnecting: false
    property string btDeviceTarget: ""
    property var wifiNetworks: []
    property var btDevices: []
    property var activeWorkspaceIds: [1]
    property var occupiedWorkspaceIds: []
    property int focusedWorkspaceId: 1
    property var workspaceInfos: []
    property var workspaceMonitors: []
    property var workspaceClients: []

    function _shellQuoteSingle(value) {
        return String(value).replace(/'/g, "'\"'\"'");
    }

    function _wifiIsSecure(security) {
        const value = String(security || "").trim().toLowerCase();
        return value.length > 0 && value !== "open" && value !== "--" && value !== "none";
    }

    /// Turn NetworkManager / nmcli stderr into short, plain-language text.
    function humanizeWifiConnectError(rawText) {
        const raw = String(rawText || "").trim();
        const lower = raw.toLowerCase();
        const T = function (s) {
            return root.config.formatUiText(s);
        };
        if (!lower)
            return T("Could not connect. Please try again.");

        if ((lower.includes("secrets were required") || lower.includes("secrets required")) && lower.includes("not provided"))
            return T("This network needs a password. Enter it above, then tap Connect.");

        if (lower.includes("no secrets were provided"))
            return T("This network needs a password. Enter it above, then tap Connect.");

        if ((lower.includes("802-11-wireless-security") || lower.includes(".psk") || lower.includes(" psk"))
            && (lower.includes("invalid") || lower.includes("propery") || lower.includes("property")))
            return T("The password was not accepted. Check that it matches this network and try again.");

        if (lower.includes("invalid key") || lower.includes("wrong psk") || lower.includes("pre-shared key"))
            return T("The password was not accepted. Check that it matches this network and try again.");

        if (lower.includes("authentication failed") || lower.includes("not authorized"))
            return T("Sign-in failed. The password may be wrong, or the network may use a different security type.");

        if (lower.includes("no network with ssid") || lower.includes("network not found"))
            return T("That network was not found. Tap Rescan, then try again.");

        if (lower.includes("device or resource busy"))
            return T("The Wi‑Fi adapter is busy. Wait a moment and try again.");

        return T("Could not connect. If the network is password-protected, check the password and try again.");
    }

    function _syncOccupiedFromWorkspaceInfos() {
        if (root.workspaceClientsPollingEnabled)
            return;
        const infos = root.workspaceInfos || [];
        const ids = [];
        for (let i = 0; i < infos.length; i++) {
            const info = infos[i] || {};
            if ((Number(info.windows) || 0) > 0)
                ids.push(Number(info.id) || 0);
        }
        ids.sort((a, b) => a - b);
        root.occupiedWorkspaceIds = ids;
    }

    function refreshStatusMenuData(activeMenu) {
        const menu = String(activeMenu || "");
        if (menu === "wifi") {
            wifiProc.exec({ command: wifiProc.command });
            wifiDetailProc.exec({ command: wifiDetailProc.command });
            wifiScanProc.exec({ command: wifiScanProc.command });
        } else if (menu === "bt") {
            btProc.exec({ command: btProc.command });
            btDetailProc.exec({ command: btDetailProc.command });
            btScanProc.exec({ command: btScanProc.command });
        } else if (menu === "battery") {
            batteryProc.exec({ command: batteryProc.command });
            batteryDetailProc.exec({ command: batteryDetailProc.command });
        } else if (menu === "audio") {
            audioProc.exec({ command: audioProc.command });
            audioDetailProc.exec({ command: audioDetailProc.command });
            audioOutputsProc.exec({ command: audioOutputsProc.command });
            audioInputsProc.exec({ command: audioInputsProc.command });
        } else if (menu === "brightness") {
            brightnessProc.exec({ command: brightnessProc.command });
        }
    }

    function scheduleStatusRefresh(activeMenu) {
        root.pendingStatusMenuRefresh = String(activeMenu || "");
        statusMenuRefreshTimer.restart();
    }

    function refreshAudioData() {
        audioProc.exec({ command: audioProc.command });
        audioDetailProc.exec({ command: audioDetailProc.command });
    }

    function refreshBrightnessData() {
        brightnessProc.exec({ command: brightnessProc.command });
    }

    function handleStatusMenuOpened(name) {
        statusMenuRefreshTimer.stop();
        if (name === "wifi") {
            wifiDetailProc.running = true;
            wifiScanProc.running = true;
        } else if (name === "bt") {
            btDetailProc.running = true;
            btScanProc.running = true;
        } else if (name === "battery") {
            batteryDetailProc.running = true;
        } else if (name === "audio") {
            audioDetailProc.running = true;
            audioOutputsProc.running = true;
            audioInputsProc.running = true;
        } else if (name === "brightness") {
            brightnessProc.running = true;
        }
    }

    Process { id: wsListProc
        command: ["bash", "-lc", "if command -v hyprctl >/dev/null 2>&1; then hyprctl workspaces -j; else echo '[]'; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(String(text).trim() || "[]");
                    const infoMap = {};
                    if (Array.isArray(parsed)) {
                        for (let i = 0; i < parsed.length; i++) {
                            const workspace = parsed[i] || {};
                            const workspaceId = Number(workspace.id) || 0;
                            if (workspaceId < 1)
                                continue;
                            infoMap[workspaceId] = {
                                id: workspaceId,
                                name: String(workspace.name || "").trim(),
                                monitorName: String(workspace.monitor || "").trim(),
                                monitorId: Number(workspace.monitorID) || 0,
                                hasFullscreen: Boolean(workspace.hasfullscreen),
                                windows: Number(workspace.windows) || 0
                            };
                        }
                    }
                    let infos = [];
                    for (const workspaceKey in infoMap)
                        infos.push(infoMap[workspaceKey]);
                    infos.sort((a, b) => a.id - b.id);
                    root.workspaceInfos = infos;
                    root.activeWorkspaceIds = infos.length > 0 ? infos.map(info => info.id) : [1];
                    root._syncOccupiedFromWorkspaceInfos();
                } catch (e) {
                    root.workspaceInfos = [];
                    root.activeWorkspaceIds = [1];
                    root._syncOccupiedFromWorkspaceInfos();
                }
            }
        }
    }

    Process { id: wsFocusedProc
        command: ["bash", "-lc", "if command -v hyprctl >/dev/null 2>&1; then hyprctl activeworkspace -j; else echo '{}'; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(String(text).trim() || "{}");
                    root.focusedWorkspaceId = Number(parsed.id) || 1;
                } catch (e) {
                    root.focusedWorkspaceId = 1;
                }
            }
        }
    }

    Process {
        id: wsClientsProc
        command: [
            "bash",
            "-lc",
            "(command -v python3 >/dev/null 2>&1 && python3 '" + root._shellQuoteSingle(Quickshell.shellDir + "/scripts/hyprland-clients-icons.py") + "') || (command -v hyprctl >/dev/null 2>&1 && hyprctl clients -j || echo '[]')"
        ]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(String(text).trim() || "[]");
                    root.workspaceClients = Array.isArray(parsed)
                        ? parsed.map(client => ({
                            workspaceId: Number(client.workspace && client.workspace.id) || 0,
                            title: String(client.title || "").trim(),
                            className: String(client.class || "").trim(),
                            initialClass: String(client.initialClass || "").trim(),
                            iconPath: String(client.iconPath || "").trim(),
                            address: String(client.address || "").trim(),
                            floating: Boolean(client.floating),
                            fullscreen: Boolean(client.fullscreen),
                            monitor: Number(client.monitor) || 0,
                            x: Array.isArray(client.at) ? (Number(client.at[0]) || 0) : 0,
                            y: Array.isArray(client.at) ? (Number(client.at[1]) || 0) : 0,
                            width: Array.isArray(client.size) ? Math.max(1, Number(client.size[0]) || 0) : 1,
                            height: Array.isArray(client.size) ? Math.max(1, Number(client.size[1]) || 0) : 1
                        })).filter(client => client.workspaceId > 0)
                        : [];
                    const occupied = {};
                    for (let i = 0; i < root.workspaceClients.length; i++) {
                        const wsId = Number(root.workspaceClients[i].workspaceId) || 0;
                        if (wsId > 0)
                            occupied[wsId] = true;
                    }
                    let occupiedIds = [];
                    for (const wsKey in occupied)
                        occupiedIds.push(Number(wsKey));
                    occupiedIds.sort((a, b) => a - b);
                    root.occupiedWorkspaceIds = occupiedIds;
                } catch (e) {
                    root.workspaceClients = [];
                    root.occupiedWorkspaceIds = [];
                }
            }
        }
    }

    Process { id: wsMonitorsProc
        command: ["bash", "-lc", "if command -v hyprctl >/dev/null 2>&1; then hyprctl monitors -j; else echo '[]'; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(String(text).trim() || "[]");
                    root.workspaceMonitors = Array.isArray(parsed)
                        ? parsed.map(monitor => ({
                            id: Number(monitor.id) || 0,
                            name: String(monitor.name || "").trim(),
                            x: Number(monitor.x) || 0,
                            y: Number(monitor.y) || 0,
                            width: Math.max(1, Number(monitor.width) || 0),
                            height: Math.max(1, Number(monitor.height) || 0),
                            scale: Math.max(0.25, Number(monitor.scale) || 1),
                            activeWorkspaceId: Number(monitor.activeWorkspace && monitor.activeWorkspace.id) || 0
                        }))
                        : [];
                } catch (e) {
                    root.workspaceMonitors = [];
                }
            }
        }
    }

    Process { id: dateProc
        command: ["bash", "-lc", root.dateCommand]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.dateText = String(text).trim()
        }
    }

    Process { id: wifiProc
        command: ["bash", "-lc", "if command -v nmcli >/dev/null 2>&1; then radio=$(nmcli radio wifi | head -n1); wifiDev=$(nmcli -t -f DEVICE,TYPE device status | awk -F: '$2==\"wifi\"{print $1; exit}'); active=$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status | awk -F: '$3==\"connected\"{print $2\"|\"$4; exit}'); if [ -n \"$active\" ]; then echo \"${radio}|${wifiDev}|${active}\"; else echo \"${radio}|${wifiDev}|offline|off\"; fi; else echo 'disabled||offline|off'; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const parts = String(text).trim().split("|");
                const radio = String(parts[0] || "disabled").trim();
                const connType = String(parts[2] || "offline").trim();
                root.networkEnabled = radio === "enabled";
                root.wifiDeviceName = String(parts[1] || "").trim();
                root.wifiConnected = connType === "wifi";
                root.networkDisplayText = connType === "ethernet" ? "CABLED" : connType === "wifi" ? "WIFI" : "OFFLINE";
                root.networkTypeText = connType === "ethernet" ? "Wired" : connType === "wifi" ? "WiFi" : "Offline";
            }
        }
    }

    Process { id: btProc
        command: ["bash", "-lc", "if command -v bluetoothctl >/dev/null 2>&1; then p=$(bluetoothctl show | awk -F': ' '/Powered:/ {print $2}'); d=$(bluetoothctl show | awk -F': ' '/Discoverable:/ {print $2}'); echo \"${p:-no}|${d:-no}\"; else echo 'no|no'; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const parts = String(text).trim().split("|");
                root.btEnabled = String(parts[0] || "no") === "yes";
                root.btDiscoverable = String(parts[1] || "no") === "yes";
            }
        }
    }

    Process { id: batteryProc
        command: ["bash", "-lc", "if command -v acpi >/dev/null 2>&1; then line=$(acpi -b | awk 'NR==1{print}'); if [ -n \"$line\" ]; then pct=$(printf '%s' \"$line\" | awk -F', ' '{gsub(/%/,\"\",$2); print $2}'); st=$(printf '%s' \"$line\" | awk -F': ' '{print $2}' | awk -F', ' '{print $1}'); printf '%s|%s\\n' \"${pct:-0}\" \"${st:-Unknown}\"; else printf '0|Unknown\\n'; fi; else bat=$(ls /sys/class/power_supply 2>/dev/null | awk '/^BAT/{print; exit}'); if [ -n \"$bat\" ] && [ -r \"/sys/class/power_supply/$bat/capacity\" ]; then pct=$(cat \"/sys/class/power_supply/$bat/capacity\"); st=Unknown; [ -r \"/sys/class/power_supply/$bat/status\" ] && st=$(cat \"/sys/class/power_supply/$bat/status\"); printf '%s|%s\\n' \"${pct:-0}\" \"$st\"; else printf '0|Unknown\\n'; fi; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const raw = String(text).trim();
                const parts = raw.split("|");
                const p = Number(String(parts[0] || "0").trim()) || 0;
                root.batteryPercent = p;
                root.batteryStatusText = String(parts[1] || "Unknown").trim() || "Unknown";
            }
        }
    }

    Process { id: brightnessProc
        command: ["bash", "-lc", "if command -v brightnessctl >/dev/null 2>&1; then brightnessctl -m | awk -F, '{gsub(/%/,\"\",$4); print $4}'; else echo '50'; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const raw = Number(String(text).trim());
                if (!Number.isFinite(raw))
                    return;
                root.brightnessPercent = Math.max(1, Math.min(100, Math.round(raw)));
            }
        }
    }

    Process { id: audioProc
        command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then v=$(pactl get-sink-volume @DEFAULT_SINK@ | awk 'NR==1{last=\"\";for(i=1;i<=NF;i++)if($i ~ /%/){v=$i;gsub(/%/,\"\",v);last=v}if(last!=\"\")print last}'); m=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}'); echo \"${v:-0} ${m:-no}\"; else echo '0 no'; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const parts = String(text).trim().split(/\s+/);
                const parsed = Number(parts[0]);
                if (!Number.isFinite(parsed))
                    return;
                root.volumePercent = Math.max(0, Math.min(150, Math.round(parsed)));
                root.volumeMuted = String(parts[1] || "no") === "yes";
            }
        }
    }

    Process { id: wifiScanProc
        command: ["bash", "-lc", "if command -v nmcli >/dev/null 2>&1; then nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list | sed '/^--/d' | head -n 60; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const lines = String(text).trim().split("\n");
                const bySsid = {};
                for (const line of lines) {
                    if (!line)
                        continue;
                    const parts = line.split(":");
                    const active = (parts[0] || "").trim() === "*";
                    const ssid = (parts[1] || "").trim();
                    const signal = Number((parts[2] || "0").trim()) || 0;
                    const security = (parts[3] || "open").trim() || "open";
                    if (!ssid)
                        continue;
                    const next = {
                        ssid: ssid,
                        signal: signal,
                        security: security,
                        active: active,
                        secured: root._wifiIsSecure(security)
                    };
                    if (!bySsid[ssid] || active || signal > bySsid[ssid].signal)
                        bySsid[ssid] = next;
                }
                const parsed = Object.values(bySsid).sort((a, b) => Number(b.active) - Number(a.active) || b.signal - a.signal);
                root.wifiNetworks = parsed;
                if (!root.wifiConnectSsid && parsed.length > 0)
                    root.wifiConnectSsid = parsed[0].ssid;
            }
        }
    }

    Process { id: btScanProc
        command: ["bash", "-lc", "if command -v bluetoothctl >/dev/null 2>&1; then echo '__DEVICES__'; bluetoothctl devices; echo '__CONNECTED__'; bluetoothctl devices Connected; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const lines = String(text).trim().split("\n");
                const parsed = [];
                const connectedSet = {};
                let inConnected = false;
                for (const line of lines) {
                    if (line === "__DEVICES__") {
                        inConnected = false;
                        continue;
                    }
                    if (line === "__CONNECTED__") {
                        inConnected = true;
                        continue;
                    }
                    if (!line.startsWith("Device "))
                        continue;
                    const raw = line.slice(7);
                    const idx = raw.indexOf(" ");
                    if (idx < 0)
                        continue;
                    const mac = raw.slice(0, idx).trim();
                    const name = raw.slice(idx + 1).trim() || mac;
                    if (inConnected) {
                        connectedSet[mac] = true;
                        continue;
                    }
                    parsed.push({ mac: mac, name: name, connected: false });
                }
                for (let i = 0; i < parsed.length; i++)
                    parsed[i].connected = Boolean(connectedSet[parsed[i].mac]);
                root.btDevices = parsed;
                if (!root.btDeviceTarget && parsed.length > 0)
                    root.btDeviceTarget = parsed[0].mac;
            }
        }
    }

    Process { id: wifiDetailProc
        command: ["bash", "-lc", "if command -v nmcli >/dev/null 2>&1; then nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status | awk -F: '$3==\"connected\"{printf \"Connection: %s\\nDevice: %s\", $4, $1; found=1; exit} END{if(!found) print \"No active connection\"}'; else echo 'nmcli not available'; fi"]
        stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.wifiDetailText = String(text).trim() || "-" }
    }

    Process { id: btDetailProc
        command: ["bash", "-lc", "if command -v bluetoothctl >/dev/null 2>&1; then c=$(bluetoothctl devices Connected | cut -d' ' -f3- | paste -sd ', ' -); if [ -n \"$c\" ]; then echo \"Connected: $c\"; else echo 'No connected devices'; fi; else echo 'bluetoothctl not available'; fi"]
        stdout: StdioCollector { waitForEnd: true; onStreamFinished: root.btDetailText = String(text).trim() || "-" }
    }

    Process { id: batteryDetailProc
        command: ["bash", "-lc", "bat=$(ls /sys/class/power_supply 2>/dev/null | awk '/^BAT/{print; exit}'); status='Unknown'; pct='0'; time='unknown'; if command -v acpi >/dev/null 2>&1; then line=$(acpi -b | awk 'NR==1{print}'); if [ -n \"$line\" ]; then status=$(printf '%s' \"$line\" | awk -F': ' '{print $2}' | awk -F', ' '{print $1}'); pct=$(printf '%s' \"$line\" | awk -F', ' '{gsub(/%/,\"\",$2); print $2}'); raw=$(printf '%s' \"$line\" | awk -F', ' '{print $3}'); if [ -n \"$raw\" ] && [ \"$raw\" != 'rate information unavailable' ]; then time=$(awk -v t=\"$raw\" 'BEGIN{gsub(/^[ \\t]+|[ \\t]+$/, \"\", t); gsub(/ remaining| until charged| until full/, \"\", t); split(t,a,\":\"); if (a[1] != \"\") printf \"%dh %dm\", a[1]+0, a[2]+0; else printf \"unknown\"}'); fi; fi; fi; if [ \"$time\" = 'unknown' ] && [ -n \"$bat\" ]; then base=\"/sys/class/power_supply/$bat\"; [ -r \"$base/status\" ] && status=$(cat \"$base/status\"); [ -r \"$base/capacity\" ] && pct=$(cat \"$base/capacity\"); now=''; full=''; rate=''; [ -r \"$base/energy_now\" ] && now=$(cat \"$base/energy_now\"); [ -r \"$base/charge_now\" ] && [ -z \"$now\" ] && now=$(cat \"$base/charge_now\"); [ -r \"$base/energy_full\" ] && full=$(cat \"$base/energy_full\"); [ -r \"$base/charge_full\" ] && [ -z \"$full\" ] && full=$(cat \"$base/charge_full\"); [ -r \"$base/power_now\" ] && rate=$(cat \"$base/power_now\"); [ -r \"$base/current_now\" ] && [ -z \"$rate\" ] && rate=$(cat \"$base/current_now\"); if [ -n \"$now\" ] && [ -n \"$rate\" ] && [ \"$rate\" != '0' ]; then if [ \"$status\" = 'Charging' ] && [ -n \"$full\" ]; then rem=$(awk -v f=\"$full\" -v n=\"$now\" 'BEGIN{printf \"%f\", (f-n>0)?f-n:0}'); else rem=\"$now\"; fi; time=$(awk -v rem=\"$rem\" -v rate=\"$rate\" 'BEGIN{h=rem/rate; if (h>0) printf \"%dh %dm\", int(h), int((h-int(h))*60+0.5); else printf \"unknown\"}'); fi; fi; printf '%s|%s|%s\\n' \"$status\" \"$pct\" \"$time\""]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const parts = String(text).trim().split("|");
                root.batteryStatusText = String(parts[0] || "Unknown").trim() || "Unknown";
                root.batteryTimeText = String(parts[2] || "unknown").trim() || "unknown";
                const pct = Number(String(parts[1] || "").trim());
                if (Number.isFinite(pct))
                    root.batteryPercent = pct;
            }
        }
    }

    Process { id: audioDetailProc
        command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then v=$(pactl get-sink-volume @DEFAULT_SINK@ | awk 'NR==1{last=\"\";for(i=1;i<=NF;i++)if($i ~ /%/){v=$i;gsub(/%/,\"\",v);last=v}if(last!=\"\")print last}'); m=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}'); echo \"Volume: ${v:-0}%\\nMuted: ${m:-no}\"; else echo 'Audio info unavailable'; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const t = String(text).trim();
                const m = t.match(/Volume:\s*([0-9]+(?:\.[0-9]+)?)/);
                if (m)
                    root.volumePercent = Math.max(0, Math.min(150, Math.round(Number(m[1]))));
            }
        }
    }

    Process { id: audioOutputsProc
        command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then def=$(pactl get-default-sink 2>/dev/null); printf '%s\\n' \"$def\"; pactl -f json list sinks 2>/dev/null; else printf '\\n[]'; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const value = String(text);
                const idx = value.indexOf("\n");
                const def = idx >= 0 ? value.slice(0, idx).trim() : "";
                const payload = idx >= 0 ? value.slice(idx + 1).trim() : "[]";
                try {
                    const items = JSON.parse(payload);
                    root.audioOutputs = items.map(item => ({
                        name: item.name || "",
                        description: item.description || item.name || "Output",
                        default: (item.name || "") === def
                    }));
                } catch (e) {
                    root.audioOutputs = [];
                }
            }
        }
    }

    Process { id: audioInputsProc
        command: ["bash", "-lc", "if command -v pactl >/dev/null 2>&1; then def=$(pactl get-default-source 2>/dev/null); printf '%s\\n' \"$def\"; pactl -f json list sources 2>/dev/null; else printf '\\n[]'; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const value = String(text);
                const idx = value.indexOf("\n");
                const def = idx >= 0 ? value.slice(0, idx).trim() : "";
                const payload = idx >= 0 ? value.slice(idx + 1).trim() : "[]";
                try {
                    const items = JSON.parse(payload);
                    root.audioInputs = items.filter(item => !String(item.name || "").includes(".monitor")).map(item => ({
                        name: item.name || "",
                        description: item.description || item.name || "Input",
                        default: (item.name || "") === def
                    }));
                } catch (e) {
                    root.audioInputs = [];
                }
            }
        }
    }

    Process { id: locksProc
        command: ["bash", "-lc", "caps=$(cat /sys/class/leds/*::capslock/brightness 2>/dev/null | head -n1); num=$(cat /sys/class/leds/*::numlock/brightness 2>/dev/null | head -n1); if [ -n \"$caps\" ] || [ -n \"$num\" ]; then echo \"${caps:-0} ${num:-0}\"; elif command -v xset >/dev/null 2>&1; then xset q | awk '/Caps Lock:/ {caps=$4} /Num Lock:/ {num=$8} END {print (caps==\"on\"?1:0)\" \"(num==\"on\"?1:0)}'; else echo \"0 0\"; fi"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const parts = String(text).trim().split(/\s+/);
                root.capsLockOn = Number(parts[0] || "0") > 0;
                root.numLockOn = Number(parts[1] || "0") > 0;
            }
        }
    }

    Timer {
        interval: root.mediumPollMs
        running: root.pollingEnabled && root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (root.clockPollingEnabled)
                dateProc.exec({ command: dateProc.command });
            audioProc.exec({ command: audioProc.command });
            batteryProc.exec({ command: batteryProc.command });
            if (root.includeLocks)
                locksProc.exec({ command: locksProc.command });
        }
    }

    Timer {
        interval: root.slowPollMs
        running: root.pollingEnabled && root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            wifiProc.exec({ command: wifiProc.command });
            btProc.exec({ command: btProc.command });
            brightnessProc.exec({ command: brightnessProc.command });
        }
    }

    Timer {
        interval: root.workspacePollMs
        running: root.pollingEnabled && root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            wsListProc.exec({ command: wsListProc.command });
            wsFocusedProc.exec({ command: wsFocusedProc.command });
            if (root.workspaceClientsPollingEnabled)
                wsClientsProc.exec({ command: wsClientsProc.command });
            wsMonitorsProc.exec({ command: wsMonitorsProc.command });
        }
    }

    Timer {
        id: statusMenuRefreshTimer
        interval: 280
        repeat: false
        onTriggered: root.refreshStatusMenuData(root.pendingStatusMenuRefresh)
    }
}
