import QtQuick
import Quickshell

import "." as Bar
import "./state" as BarState

Scope {
    id: root

    required property QtObject shell
    required property QtObject config

    readonly property bool workspaceClientsPollingEnabled: !!(
        root.config.workspaceShowWindowIcons || root.config.workspaceShowLayoutOnHover
    )

    function _barDateCommand() {
        const dateFmt = String(root.config.overlayDateFormat || "%a %d %b").trim();
        const timeFmt = String(root.config.overlayTimeFormat || "%H:%M").trim();
        const mode = String(root.config.overlayDateTimeFormat || "date-time").trim().toLowerCase();
        if (mode === "date")
            return "date '+" + dateFmt + "'";
        if (mode === "time")
            return "date '+" + timeFmt + "'";
        if (mode === "iso")
            return "date '+%F %T'";
        return "date '+" + dateFmt + " " + timeFmt + "'";
    }

    BarState.BarSensorState {
        id: sharedSensors
        config: root.config
        pollingEnabled: true
        visible: true
        includeLocks: true
        workspaceClientsPollingEnabled: root.workspaceClientsPollingEnabled
        clockPollingEnabled: root.config.barOrientation === "top"
        dateCommand: root._barDateCommand()
    }

    Component {
        id: topBarComponent
        Bar.TopBar {
            required property var screen
            shell: root.shell
            config: root.config
            sensors: sharedSensors
            screen: screen
        }
    }

    Component {
        id: sideBarComponent
        Bar.SideBar {
            required property var screen
            shell: root.shell
            config: root.config
            sensors: sharedSensors
            screen: screen
        }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            property var modelData: null

            Loader {
                active: true
                sourceComponent: root.config.barOrientation === "top" ? topBarComponent : sideBarComponent
                property var screen: modelData
                onItemChanged: {
                    if (item)
                        item.screen = screen;
                }
            }
        }
    }
}
