import QtQuick
import ".." as LegacyTabs

Item {
    id: root
    required property QtObject control

    // Reuse the previous Hyprland tab for full managed-config controls.
    LegacyTabs.HyprlandTab {
        id: hyprlandPane
        anchors.fill: parent
        control: root.control
    }

    implicitHeight: hyprlandPane.implicitHeight
}
