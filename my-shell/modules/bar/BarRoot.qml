import QtQuick
import Quickshell

import "." as Bar

Scope {
    id: root

    required property QtObject shell
    required property QtObject config

    Variants {
        model: Quickshell.screens

        Scope {
            property var modelData: null

            Bar.TopBar {
                shell: root.shell
                config: root.config
                screen: modelData
                visible: root.config.barOrientation === "top"
            }

            Bar.SideBar {
                shell: root.shell
                config: root.config
                screen: modelData
                visible: root.config.barOrientation === "left"
            }
        }
    }
}
