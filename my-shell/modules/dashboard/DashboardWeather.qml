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
    readonly property string conditionGlyph: {
        const s = summaryRaw.toLowerCase();
        if (s.includes("snow") || s.includes("sleet") || s.includes("ice"))
            return "❄";
        if (s.includes("thunder") || s.includes("storm"))
            return "⚡";
        if (s.includes("rain") || s.includes("drizzle") || s.includes("shower"))
            return "🌧";
        if (s.includes("fog") || s.includes("mist") || s.includes("haze"))
            return "🌫";
        if (s.includes("cloud") || s.includes("overcast"))
            return "☁";
        if (s.includes("clear") || s.includes("sun"))
            return "☀";
        return "◌";
    }

    color: Qt.rgba(dashboard.dashboardAccent.r, dashboard.dashboardAccent.g, dashboard.dashboardAccent.b, 0.06)
    border.color: dashboard.dashboardAccent
    border.width: dashboard.config.overlayBorderWidth
    radius: dashboard.config.rounding

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Label {
                text: root.conditionGlyph
                font.pixelSize: Math.max(52, root.dashboard.uiFontSize + 40)
                color: root.dashboard.dashboardAccent
                Layout.alignment: Qt.AlignTop
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

        Item {
            Layout.fillHeight: true
        }
    }
}
