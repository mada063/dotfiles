import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Uses wttr.in data from Dashboard (weatherTemp, weatherSummary) — custom layout, same API.
Rectangle {
    id: root

    required property QtObject dashboard

    readonly property string tempRaw: {
        const t = String(dashboard.weatherTemp || "").trim();
        return t && t !== "-" ? t : "";
    }
    readonly property string summaryRaw: {
        const s = String(dashboard.weatherSummary || "").trim();
        return s && s !== "-" ? s : "";
    }
    readonly property int conditionKind: {
        const s = summaryRaw.toLowerCase();
        if (s.includes("snow") || s.includes("sleet") || s.includes("ice"))
            return 5;
        if (s.includes("thunder") || s.includes("storm"))
            return 4;
        if (s.includes("rain") || s.includes("drizzle") || s.includes("shower"))
            return 3;
        if (s.includes("fog") || s.includes("mist") || s.includes("haze"))
            return 2;
        if (s.includes("cloud") || s.includes("overcast"))
            return 1;
        if (s.includes("clear") || s.includes("sun"))
            return 0;
        return 1;
    }
    readonly property int conditionBoxSize: Math.max(56, Math.round(root.height * 0.48))

    color: Qt.rgba(dashboard.dashboardAccent.r, dashboard.dashboardAccent.g, dashboard.dashboardAccent.b, 0.06)
    border.color: dashboard.dashboardAccent
    border.width: dashboard.config.overlayBorderWidth
    radius: dashboard.config.rounding
    onConditionKindChanged: weatherIconCanvas.requestPaint()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            Item {
                Layout.preferredWidth: root.conditionBoxSize
                Layout.preferredHeight: root.conditionBoxSize
                Layout.alignment: Qt.AlignTop

                Canvas {
                    id: weatherIconCanvas
                    anchors.fill: parent
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        const w = width;
                        const h = height;
                        const cx = w / 2;
                        const cy = h / 2;
                        const s = Math.min(w, h);
                        const accent = root.dashboard.dashboardAccent;
                        const accentCss = "rgba(" + Math.round(accent.r * 255) + "," + Math.round(accent.g * 255) + "," + Math.round(accent.b * 255) + ",1)";
                        const softCss = "rgba(" + Math.round(accent.r * 255) + "," + Math.round(accent.g * 255) + "," + Math.round(accent.b * 255) + ",0.20)";

                        ctx.fillStyle = softCss;
                        ctx.beginPath();
                        ctx.arc(cx, cy, s * 0.48, 0, Math.PI * 2);
                        ctx.fill();

                        ctx.strokeStyle = accentCss;
                        ctx.fillStyle = accentCss;
                        ctx.lineWidth = Math.max(2, s * 0.05);
                        ctx.lineCap = "round";
                        ctx.lineJoin = "round";

                        if (root.conditionKind === 0) {
                            // sun
                            const r = s * 0.20;
                            ctx.beginPath();
                            ctx.arc(cx, cy, r, 0, Math.PI * 2);
                            ctx.stroke();
                            for (let i = 0; i < 8; i++) {
                                const a = (Math.PI * 2 * i) / 8;
                                const r1 = s * 0.30;
                                const r2 = s * 0.40;
                                ctx.beginPath();
                                ctx.moveTo(cx + Math.cos(a) * r1, cy + Math.sin(a) * r1);
                                ctx.lineTo(cx + Math.cos(a) * r2, cy + Math.sin(a) * r2);
                                ctx.stroke();
                            }
                        } else if (root.conditionKind === 1) {
                            // cloud
                            ctx.beginPath();
                            ctx.arc(cx - s * 0.12, cy, s * 0.14, Math.PI * 0.9, Math.PI * 1.95);
                            ctx.arc(cx + s * 0.04, cy - s * 0.04, s * 0.18, Math.PI, Math.PI * 1.95);
                            ctx.arc(cx + s * 0.20, cy, s * 0.14, Math.PI * 1.05, Math.PI * 2.05);
                            ctx.stroke();
                        } else if (root.conditionKind === 2) {
                            // fog
                            for (let i = -1; i <= 1; i++) {
                                const y = cy + i * s * 0.12;
                                ctx.beginPath();
                                ctx.moveTo(cx - s * 0.30, y);
                                ctx.bezierCurveTo(cx - s * 0.15, y - s * 0.05, cx + s * 0.05, y + s * 0.05, cx + s * 0.28, y);
                                ctx.stroke();
                            }
                        } else if (root.conditionKind === 3) {
                            // rain
                            ctx.beginPath();
                            ctx.arc(cx - s * 0.10, cy - s * 0.06, s * 0.13, Math.PI, Math.PI * 1.95);
                            ctx.arc(cx + s * 0.06, cy - s * 0.10, s * 0.17, Math.PI, Math.PI * 1.95);
                            ctx.stroke();
                            for (let i = -1; i <= 1; i++) {
                                const x = cx + i * s * 0.12;
                                ctx.beginPath();
                                ctx.moveTo(x, cy + s * 0.10);
                                ctx.lineTo(x - s * 0.04, cy + s * 0.24);
                                ctx.stroke();
                            }
                        } else if (root.conditionKind === 4) {
                            // thunder
                            ctx.beginPath();
                            ctx.arc(cx - s * 0.10, cy - s * 0.08, s * 0.13, Math.PI, Math.PI * 1.95);
                            ctx.arc(cx + s * 0.06, cy - s * 0.12, s * 0.17, Math.PI, Math.PI * 1.95);
                            ctx.stroke();
                            ctx.beginPath();
                            ctx.moveTo(cx + s * 0.02, cy + s * 0.04);
                            ctx.lineTo(cx - s * 0.08, cy + s * 0.24);
                            ctx.lineTo(cx + s * 0.02, cy + s * 0.24);
                            ctx.lineTo(cx - s * 0.02, cy + s * 0.38);
                            ctx.stroke();
                        } else {
                            // snow
                            ctx.beginPath();
                            ctx.arc(cx - s * 0.10, cy - s * 0.08, s * 0.13, Math.PI, Math.PI * 1.95);
                            ctx.arc(cx + s * 0.06, cy - s * 0.12, s * 0.17, Math.PI, Math.PI * 1.95);
                            ctx.stroke();
                            const r = s * 0.13;
                            for (let i = 0; i < 3; i++) {
                                const a = (Math.PI * 2 * i) / 3;
                                ctx.beginPath();
                                ctx.moveTo(cx + Math.cos(a) * r * 0.4, cy + s * 0.20 + Math.sin(a) * r * 0.4);
                                ctx.lineTo(cx + Math.cos(a) * r, cy + s * 0.20 + Math.sin(a) * r);
                                ctx.stroke();
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: root.tempRaw.length ? root.tempRaw + "°" : "–"
                    color: root.dashboard.dashboardAccent
                    font.bold: true
                    font.pixelSize: root.dashboard.uiFontSize + 20
                    font.family: root.dashboard.uiFontFamily
                }
                Label {
                    text: root.summaryRaw.length ? root.summaryRaw : "Loading weather…"
                    color: root.dashboard.config.textColor
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    font.family: root.dashboard.uiFontFamily
                    font.pixelSize: root.dashboard.uiFontSize
                }
            }
        }
    }
}
