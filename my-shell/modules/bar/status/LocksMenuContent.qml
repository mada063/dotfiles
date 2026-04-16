import QtQuick
import QtQuick.Controls

Column {
    id: root

    required property QtObject host

    readonly property bool _hug: host.statusMenuHugWidth === true

    spacing: 6
    width: _hug ? implicitWidth : Math.max(116, host.statusMenuContentWidth)

    Label { text: "CAPS " + (host.capsLockOn ? "On" : "Off"); color: host.config.textColor }
    Label { text: "NUM " + (host.numLockOn ? "On" : "Off"); color: host.config.textColor }
}
