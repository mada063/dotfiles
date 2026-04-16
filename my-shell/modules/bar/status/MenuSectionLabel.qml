import QtQuick
import QtQuick.Controls

Label {
    id: root

    required property QtObject host

    color: host.config.overlayAccentColor
    font.bold: true
}
