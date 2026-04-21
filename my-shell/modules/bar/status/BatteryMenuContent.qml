import QtQuick
import QtQuick.Controls

Column {
    id: root

    required property QtObject host

    readonly property bool _hug: host.statusMenuHugWidth === true

    spacing: 6
    width: _hug ? host.sideMenuHugContentWidth : host.statusMenuContentWidth

    Label { width: parent.width; text: "Remaining: " + host.batteryPercent + "%"; color: host.config.textColor; wrapMode: Text.WordWrap }
    Label { width: parent.width; visible: host.batteryTimeText.length > 0 && host.batteryTimeText !== "unknown"; text: "Remaining time: " + host.batteryTimeText; color: host.config.textColor; wrapMode: Text.WordWrap }
    Label { width: parent.width; text: "Status: " + host.batteryStatusText; color: host.config.mutedTextColor; wrapMode: Text.WordWrap }
}
