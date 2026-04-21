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
    property var imageList: []
    property string searchDir: StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0] || (StandardPaths.standardLocations(StandardPaths.HomeLocation)[0] + "/Pictures")

    visible: root.shown || overlayDimmer.opacity > 0.01 || pickerPanel.opacity > 0.01
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
        Behavior on opacity { NumberAnimation { duration: 120 } }
        MouseArea {
            anchors.fill: parent
            onClicked: root.shell.wallpaperPickerVisible = false
        }
    }

    Rectangle {
        id: pickerPanel
        property real offsetY: root.shown ? 0 : -24
        width: Math.min(parent.width - 48, 680)
        height: Math.min(parent.height - 48, 220)
        anchors.centerIn: parent
        anchors.verticalCenterOffset: offsetY
        color: root.config.settingsBackgroundColor
        border.color: root.config.settingsAccentColor
        border.width: root.config.overlayBorderWidth
        radius: root.config.settingsRounding
        z: 1
        opacity: root.shown ? root.config.panelOpacity : 0
        Behavior on offsetY { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 120 } }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                Label {
                    text: "Wallpaper"
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
                    text: "No images found in " + root.searchDir
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
                                width: 120
                                height: thumbScrollView.height

                                Rectangle {
                                    anchors.fill: parent
                                    color: "transparent"
                                    border.width: isCurrent ? Math.max(2, root.config.buttonBorderWidth + 1) : Math.max(1, root.config.buttonBorderWidth)
                                    border.color: isCurrent ? root.config.settingsAccentColor : root.config.mutedTextColor
                                    radius: root.config.settingsRounding
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        anchors.margins: isCurrent ? 3 : 2
                                        source: "file://" + modelData
                                        fillMode: Image.PreserveAspectCrop
                                        smooth: true
                                        asynchronous: true
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
                                            text: "Active"
                                            color: "#ffffff"
                                            font.family: root.config.fontFamily
                                            font.pixelSize: root.config.fontPixelSize - 1
                                            font.bold: true
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
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
