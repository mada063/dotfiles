import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// wttr.in: temp | condition emoji (%c) | text (%C) from Dashboard.weatherBriefProc — aligned with Overview avatar/OS RowLayout.
Rectangle {
    id: root

    required property QtObject dashboard

    WeatherAsciiArt {
        id: weatherAscii
    }

    readonly property string tempRaw: {
        const t = String(dashboard.weatherTemp || "").trim();
        return t && t !== "-" ? t : "";
    }
    readonly property string summaryRaw: {
        const s = String(dashboard.weatherSummary || "").trim();
        return s && s !== "-" ? s : "";
    }
    /** 0 = live wttr mapping; 1…N cycle previewArts in WeatherAsciiArt. */
    property int asciiPreviewStep: 0
    readonly property string displayWeatherAsciiLive: summaryRaw.length
        ? weatherAscii.textForSummary(summaryRaw)
        : "     …\n     …"
    readonly property string displayWeatherAscii: root.asciiPreviewStep === 0
        ? root.displayWeatherAsciiLive
        : weatherAscii.previewArtAt(root.asciiPreviewStep - 1)

    readonly property color weatherAccent: root.dashboard.config.dashboardWeatherAccentColor
    readonly property color weatherIconColor: root.dashboard.config.dashboardWeatherIconColor
    readonly property color weatherIconBgColor: root.dashboard.config.dashboardWeatherIconBackgroundColor
    readonly property color weatherText: root.dashboard.config.dashboardWeatherTextColor

    color: Qt.rgba(weatherAccent.r, weatherAccent.g, weatherAccent.b, 0.06)
    border.color: weatherAccent
    border.width: dashboard.config.overlayBorderWidth
    radius: root.dashboard.dashboardSurfaceRounding

    Connections {
        target: root.dashboard
        function onVisibleChanged() {
            if (!root.dashboard.visible)
                root.asciiPreviewStep = 0;
        }
    }

    RowLayout {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 14

        Rectangle {
            id: asciiBubble
            Layout.alignment: Qt.AlignVCenter
            width: 84
            height: 84
            radius: width / 2
            color: Qt.rgba(weatherIconBgColor.r, weatherIconBgColor.g, weatherIconBgColor.b, 0.65)
            border.width: root.dashboard.config.buttonBorderWidth
            border.color: weatherIconColor
            clip: true

            Label {
                anchors.centerIn: parent
                width: parent.width - 18
                height: parent.height - 18
                clip: true
                text: root.displayWeatherAscii
                wrapMode: Text.NoWrap
                elide: Text.ElideNone
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                lineHeightMode: Text.ProportionalHeight
                lineHeight: 0.92
                font.pixelSize: Math.max(3, Math.min(2, Math.floor((asciiBubble.width - 18) / 10)))
                font.family: "monospace"
                color: weatherIconColor
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const n = weatherAscii.previewArtCount + 1;
                    root.asciiPreviewStep = (root.asciiPreviewStep + 1) % n;
                }
            }
        }

        ColumnLayout {
            // Match avatar/OS card: fill width, no per-item vertical alignment (RowLayout centers row as a unit).
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: 6

            Label {
                Layout.fillWidth: true
                text: root.tempRaw.length ? root.tempRaw + "°" : "–"
                color: weatherAccent
                font.bold: true
                font.pixelSize: root.dashboard.uiFontSize + 20
                font.family: root.dashboard.uiFontFamily
            }
            Label {
                Layout.fillWidth: true
                text: root.summaryRaw.length ? root.summaryRaw : "Loading weather…"
                color: weatherText
                wrapMode: Text.WordWrap
                font.family: root.dashboard.uiFontFamily
                font.pixelSize: root.dashboard.uiFontSize
            }
        }
    }
}
