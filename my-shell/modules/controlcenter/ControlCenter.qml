import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "settings"

PanelWindow {
    id: root

    required property QtObject shell
    required property QtObject config

    readonly property bool shown: root.shell.controlCenterVisible
    readonly property string uiFontFamily: root.config.fontFamily
    readonly property int uiFontSize: root.config.fontPixelSize

    property int currentSectionIndex: 0
    property int displayedSectionIndex: 0
    property int previousSectionIndex: 0
    property int slideDirection: 1
    property bool switching: false

    readonly property var settingsSections: [
        { title: "Wifi" },
        { title: "Bluetooth" },
        { title: "Audio" },
        { title: "Appearance" },
        { title: "Taskbar" },
        { title: "Notifications" },
        { title: "Dashboard" },
        { title: "Hyprland" }
    ]

    readonly property var sectionComponents: [
        wifiSectionComponent,
        bluetoothSectionComponent,
        audioSectionComponent,
        appearanceSectionComponent,
        taskbarSectionComponent,
        notificationsSectionComponent,
        dashboardSectionComponent,
        hyprlandSectionComponent
    ]

    visible: root.shown || overlayDimmer.opacity > 0.01 || settingsContainer.opacity > 0.01
    focusable: root.shown
    WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    function _T(s) {
        return root.config.formatUiText(s);
    }

    function switchTo(index) {
        const safeIndex = Math.max(0, Math.min(root.settingsSections.length - 1, index));
        if (safeIndex === root.displayedSectionIndex || root.switching) {
            root.currentSectionIndex = safeIndex;
            return;
        }
        root.previousSectionIndex = root.displayedSectionIndex;
        root.currentSectionIndex = safeIndex;
        root.slideDirection = root.currentSectionIndex > root.previousSectionIndex ? 1 : -1;
        root.switching = true;
        outgoingLoader.sourceComponent = root.sectionComponents[root.previousSectionIndex];
        incomingLoader.sourceComponent = root.sectionComponents[root.currentSectionIndex];
        incomingLoader.x = root.slideDirection * contentViewport.width;
        incomingLoader.opacity = 0.85;
        outgoingLoader.x = 0;
        outgoingLoader.opacity = 1;
        tabSwitchAnim.restart();
    }

    onShownChanged: {
        if (shown) {
            root.currentSectionIndex = root.displayedSectionIndex;
            incomingLoader.sourceComponent = root.sectionComponents[root.displayedSectionIndex];
        }
    }

    Rectangle {
        id: overlayDimmer
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, root.config.overlayDimOpacity)
        opacity: root.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        MouseArea {
            anchors.fill: parent
            onClicked: root.shell.controlCenterVisible = false
        }
    }

    Item {
        id: settingsContainer
        width: Math.min(root.width - 64, 1240)
        height: Math.min(root.height - 72, 840)
        x: root.shown ? (root.width - width) / 2 : root.width + 40
        y: root.shown ? (root.height - height) / 2 : root.height + 40
        scale: root.shown ? 1 : 0.95
        opacity: root.shown ? root.config.panelOpacity : 0
        z: 2

        // Animate stable container only to avoid content jumps.
        Behavior on x { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Rectangle {
            id: panel
            anchors.fill: parent
            radius: root.config.overlayRounding
            color: root.config.panelColor
            border.color: root.config.accentColor
            border.width: root.config.borderWidth
            clip: true

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    Layout.preferredWidth: 228
                    Layout.fillHeight: true
                    color: Qt.rgba(root.config.overlayBackgroundColor.r, root.config.overlayBackgroundColor.g, root.config.overlayBackgroundColor.b, 0.32)
                    border.color: "transparent"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        Label {
                            text: root._T("Settings")
                            color: root.config.accentColor
                            font.family: root.uiFontFamily
                            font.pixelSize: root.uiFontSize + 2
                            font.bold: true
                        }

                        ListView {
                            id: sidebarList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            model: root.settingsSections
                            clip: true
                            spacing: 6

                            delegate: Rectangle {
                                required property var modelData
                                required property int index

                                width: sidebarList.width
                                height: 36
                                radius: Math.max(0, root.config.overlayRounding - 2)
                                color: index === root.currentSectionIndex
                                    ? Qt.rgba(root.config.accentColor.r, root.config.accentColor.g, root.config.accentColor.b, 0.16)
                                    : "transparent"
                                border.width: 1
                                border.color: index === root.currentSectionIndex
                                    ? root.config.accentColor
                                    : Qt.rgba(root.config.borderColor.r, root.config.borderColor.g, root.config.borderColor.b, 0.35)

                                Label {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    text: root._T(String(modelData.title || ""))
                                    color: index === root.currentSectionIndex ? root.config.accentColor : root.config.textColor
                                    font.family: root.uiFontFamily
                                    font.pixelSize: root.uiFontSize
                                    font.bold: index === root.currentSectionIndex
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.switchTo(index)
                                }
                            }
                        }

                        Button {
                            text: root._T("Close")
                            onClicked: root.shell.controlCenterVisible = false
                        }
                    }
                }

                Rectangle {
                    Layout.fillHeight: true
                    width: 1
                    color: Qt.rgba(root.config.accentColor.r, root.config.accentColor.g, root.config.accentColor.b, 0.2)
                }

                Flickable {
                    id: contentViewport
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 18
                    clip: true
                    contentWidth: width
                    contentHeight: Math.max(height, pageStack.implicitHeight)
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick

                    Item {
                        id: pageStack
                        width: contentViewport.width
                        implicitHeight: Math.max(
                            outgoingLoader.item ? outgoingLoader.item.implicitHeight : 0,
                            incomingLoader.item ? incomingLoader.item.implicitHeight : 0
                        )

                        Loader {
                            id: outgoingLoader
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            sourceComponent: undefined
                        }

                        Loader {
                            id: incomingLoader
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            sourceComponent: wifiSectionComponent
                        }
                    }
                }
            }
        }
    }

    ParallelAnimation {
        id: tabSwitchAnim
        running: false

        NumberAnimation {
            target: outgoingLoader
            property: "x"
            to: -root.slideDirection * contentViewport.width * 0.35
            duration: 240
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: outgoingLoader
            property: "opacity"
            to: 0
            duration: 220
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: incomingLoader
            property: "x"
            to: 0
            duration: 260
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: incomingLoader
            property: "opacity"
            to: 1
            duration: 260
            easing.type: Easing.OutCubic
        }

        onFinished: {
            root.displayedSectionIndex = root.currentSectionIndex;
            outgoingLoader.sourceComponent = undefined;
            outgoingLoader.x = 0;
            outgoingLoader.opacity = 1;
            incomingLoader.x = 0;
            incomingLoader.opacity = 1;
            root.switching = false;
        }
    }

    Component { id: wifiSectionComponent; WifiSettingsPage { control: root } }
    Component { id: bluetoothSectionComponent; BluetoothSettingsPage { control: root } }
    Component { id: audioSectionComponent; AudioSettingsPage { control: root } }
    Component { id: appearanceSectionComponent; AppearanceSettingsPage { control: root } }
    Component { id: taskbarSectionComponent; TaskbarSettingsPage { control: root } }
    Component { id: notificationsSectionComponent; NotificationsSettingsPage { control: root } }
    Component { id: dashboardSectionComponent; DashboardSettingsPage { control: root } }
    Component { id: hyprlandSectionComponent; HyprlandSettingsPage { control: root } }
}
