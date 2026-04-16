import QtQuick
import QtQuick.Controls

Column {
    id: root

    required property QtObject host

    readonly property bool _hug: host.statusMenuHugWidth === true

    spacing: 6
    width: _hug ? implicitWidth : host.statusMenuContentWidth

    Label { text: "Remaining: " + host.batteryPercent + "%"; color: host.config.textColor }
    Label { visible: host.batteryTimeText.length > 0 && host.batteryTimeText !== "unknown"; text: "Remaining time: " + host.batteryTimeText; color: host.config.textColor }
    Label { text: "Status: " + host.batteryStatusText; color: host.config.mutedTextColor }
}
