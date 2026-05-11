import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    required property QtObject shell
    required property QtObject config

    readonly property bool shown: root.shell.wallpaperPickerVisible
    readonly property var _anchorScreen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    readonly property real _shellW: Math.max(root.width, _anchorScreen ? _anchorScreen.width : 1920)
    readonly property real _shellH: Math.max(root.height, _anchorScreen ? _anchorScreen.height : 1080)
    property var imageList: []
    property string searchDir: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0] || (StandardPaths.standardLocations(StandardPaths.HomeLocation)[0] + "/Pictures")

    visible: root.shown || overlayDimmer.opacity > 0.01 || dialogContainer.opacity > 0.01
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
    color: "#00000000"

    onShownChanged: {
        if (shown) {
            scanProc.exec({ command: scanProc.command });
        }
    }

    Process {
        id: scanProc
        command: ["bash", "-lc",
            "custom='" + root.searchDir.replace(/'/g, "'\"'\"'") + "'; " +
            "dirs=(); " +
            "[ -n \"$custom\" ] && [ -d \"$custom\" ] && dirs+=(\"$custom\"); " +
            "[ -d \"$HOME/Pictures\" ] && dirs+=(\"$HOME/Pictures\"); " +
            "[ -d \"/home/user/Pictures\" ] && dirs+=(\"/home/user/Pictures\"); " +
            "if [ ${#dirs[@]} -eq 0 ]; then echo; exit 0; fi; " +
            "for d in \"${dirs[@]}\"; do find \"$d\" -maxdepth 6 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) 2>/dev/null; done | awk '!seen[$0]++' | sort | head -200"
        ]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const paths = String(text).trim().split("\n").filter(p => p.length > 0);
                root.imageList = paths;
            }
        }
    }

    Rectangle {
        id: overlayDimmer
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, root.config.overlayDimOpacity)
        opacity: root.shown ? 1 : 0
        Behavior on opacity {
            enabled: root.config.uiAnimationsEnabled
            NumberAnimation { duration: root.config.overlaySlideDurationMs; easing.type: Easing.OutCubic }
        }
        MouseArea {
            anchors.fill: parent
            onClicked: root.shell.wallpaperPickerVisible = false
        }
    }

    Item {
        id: dialogContainer
        width: Math.min(Math.max(0, _shellW - 48), 680)
        height: Math.min(Math.max(0, _shellH - 48), 220)
        x: root.shown ? (_shellW - width) / 2 : _shellW + 40
        y: root.shown ? (_shellH - height) / 2 : _shellH + 40
        scale: root.shown ? 1 : 0.95
        opacity: root.shown ? root.config.panelOpacity : 0
        z: 1

        Behavior on x {
            enabled: root.config.uiAnimationsEnabled
            NumberAnimation { duration: root.config.overlaySlideDurationMs; easing.type: Easing.OutCubic }
        }
        Behavior on y {
            enabled: root.config.uiAnimationsEnabled
            NumberAnimation { duration: root.config.overlaySlideDurationMs; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            enabled: root.config.uiAnimationsEnabled
            NumberAnimation { duration: root.config.overlaySlideDurationMs; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            enabled: root.config.uiAnimationsEnabled
            NumberAnimation { duration: root.config.overlaySlideDurationMs; easing.type: Easing.OutCubic }
        }

        Rectangle {
            id: pickerPanel
            anchors.fill: parent
            color: root.config.settingsBackgroundColor
            border.color: root.config.settingsAccentColor
            border.width: root.config.overlayBorderWidth
            radius: root.config.settingsRounding

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                Label {
                    text: root.config.formatUiText("Wallpaper")
                    color: root.config.settingsTextColor
                    font.family: root.config.fontFamily
                    font.pixelSize: root.config.fontPixelSize + 6
                    font.bold: true
                }
                Item { Layout.fillWidth: true }
                Label {
                    text: root.searchDir
                    color: root.config.mutedTextColor
                    font.family: root.config.fontFamily
                    font.pixelSize: root.config.fontPixelSize - 1
                    elide: Text.ElideLeft
                    Layout.maximumWidth: 240
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Label {
                    anchors.centerIn: parent
                    visible: root.imageList.length === 0
                    text: root.config.formatUiText("No images found in") + " " + root.searchDir
                    color: root.config.mutedTextColor
                    font.family: root.config.fontFamily
                    font.pixelSize: root.config.fontPixelSize
                }

                ScrollView {
                    id: thumbScrollView
                    anchors.fill: parent
                    visible: root.imageList.length > 0
                    clip: true
                    ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                    ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                    Row {
                        spacing: 8
                        height: thumbScrollView.height

                        Repeater {
                            model: root.imageList
                            delegate: Item {
                                required property string modelData
                                readonly property bool isCurrent: String(root.config.wallpaperPath) === modelData
                                property bool tileHovered: wallHover.containsMouse
                                readonly property int thumbDecodeWidth: Math.max(96, Math.round(width * 2))
                                readonly property int thumbDecodeHeight: Math.max(96, Math.round(height * 2))
                                width: 120
                                height: thumbScrollView.height
                                scale: tileHovered ? 1.04 : 1
                                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                                Rectangle {
                                    anchors.fill: parent
                                    color: "transparent"
                                    border.width: isCurrent ? Math.max(2, root.config.buttonBorderWidth + 1) : Math.max(1, root.config.buttonBorderWidth)
                                    border.color: isCurrent ? root.config.settingsAccentColor : (tileHovered ? root.config.settingsAccentColor : root.config.mutedTextColor)
                                    radius: root.config.settingsRounding
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: isCurrent ? 3 : 2
                                        source: "file://" + modelData
                                        sourceSize.width: thumbDecodeWidth
                                        sourceSize.height: thumbDecodeHeight
                                        fillMode: Image.PreserveAspectCrop
                                        smooth: true
                                        asynchronous: true
                                        cache: true
                                        mipmap: true
                                        layer.enabled: true
                                    }

                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: 28
                                        color: Qt.rgba(0, 0, 0, 0.55)
                                        visible: isCurrent

                                        Label {
                                            anchors.centerIn: parent
                                            text: root.config.formatUiText("Active")
                                            color: "#ffffff"
                                            font.family: root.config.fontFamily
                                            font.pixelSize: root.config.fontPixelSize - 1
                                            font.bold: true
                                        }
                                    }
                                }

                                MouseArea {
                                    id: wallHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        root.shell.setWallpaper(modelData);
                                        root.shell.wallpaperPickerVisible = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        }
    }
}
