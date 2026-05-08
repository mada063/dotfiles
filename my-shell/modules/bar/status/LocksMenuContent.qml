import QtQuick
import QtQuick.Controls

Column {
    id: root

    required property QtObject host

    readonly property bool _hug: host.statusMenuHugWidth === true

    spacing: 6
    width: _hug ? implicitWidth : Math.max(116, host.statusMenuContentWidth)

    Label { text: host.config.formatUiText("CAPS") + " " + (host.capsLockOn ? host.config.formatUiText("On") : host.config.formatUiText("Off")); color: host.config.textColor }
    Label { text: host.config.formatUiText("NUM") + " " + (host.numLockOn ? host.config.formatUiText("On") : host.config.formatUiText("Off")); color: host.config.textColor }
}
