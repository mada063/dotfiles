import QtQuick
import Quickshell

import "." as Bar

Scope {
    id: root

    required property QtObject shell
    required property QtObject config

    Bar.TopBar {
        shell: root.shell
        config: root.config
        visible: root.config.barOrientation === "top"
    }

    Bar.SideBar {
        shell: root.shell
        config: root.config
        visible: root.config.barOrientation === "left"
    }
}
