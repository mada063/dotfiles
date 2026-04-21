import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property QtObject config
    required property var notifications
    property bool suppressPopup: false
    property bool quickSettingsOpen: false
    property int quickSettingsHeight: 0
    property int quickSettingsTriggerHeight: 48
    property int overlayWidth: 400
    property bool popupVisible: false
    property int shownCount: 0
    property int _toastSeq: 0
    readonly property int baseBottomGap: Math.max(10, quickSettingsTriggerHeight + 8)
    readonly property string uiFontFamily: root.config.fontFamily
    readonly property int uiFontSize: root.config.fontPixelSize

    anchors {
        right: true
        bottom: true
    }
    margins {
        right: 8
        bottom: root.quickSettingsOpen
            ? (Math.max(0, root.quickSettingsHeight) + 8)
            : root.baseBottomGap
    }
    exclusiveZone: 0
    color: "transparent"
    visible: (root.popupVisible || popupContent.opacity > 0.01) && !root.suppressPopup && root.notifications.length > 0
    implicitWidth: root.overlayWidth
    implicitHeight: popupContent.implicitHeight + 8
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    ListModel {
        id: toastModel
    }

    function _urgencyDurationMs(urgency) {
        const u = Number(urgency);
        if (u >= 2) // critical
            return 9000;
        if (u <= 0) // low
            return 3500;
        return 5500; // normal
    }

    function _urgencyIcon(urgency) {
        const u = Number(urgency);
        if (u >= 2)
            return "!!";
        if (u <= 0)
            return "i";
        return "!";
    }

    function _urgencyColor(urgency) {
        const u = Number(urgency);
        if (u >= 2)
            return Qt.rgba(1.0, 0.35, 0.35, 1.0);
        if (u <= 0)
            return root.config.mutedTextColor;
        return root.config.overlayAccentColor;
    }

    function _pushToast(entry) {
        _toastSeq += 1;
        toastModel.insert(0, {
            idNum: _toastSeq,
            appName: String(entry.appName || ""),
            summary: String(entry.summary || ""),
            body: String(entry.body || ""),
            urgency: Number(entry.urgency || 1),
            appIcon: String(entry.appIcon || ""),
            lifeMs: _urgencyDurationMs(entry.urgency || 1),
            fading: false
        });
        while (toastModel.count > 6)
            toastModel.remove(toastModel.count - 1);
    }

    function _setToastFading(idNum, fading) {
        for (let i = 0; i < toastModel.count; i++) {
            const t = toastModel.get(i);
            if (Number(t.idNum) === Number(idNum)) {
                toastModel.setProperty(i, "fading", !!fading);
                return;
            }
        }
    }

    function _removeToast(idNum) {
        for (let i = 0; i < toastModel.count; i++) {
            if (Number(toastModel.get(i).idNum) === Number(idNum)) {
                toastModel.remove(i);
                break;
            }
        }
        popupVisible = toastModel.count > 0;
    }

    onNotificationsChanged: {
        const count = notifications.length;
        if (!root.suppressPopup && count > shownCount) {
            const newCount = Math.max(0, count - shownCount);
            for (let i = 0; i < newCount; i++) {
                const n = notifications[i];
                if (n)
                    _pushToast(n);
            }
            popupVisible = toastModel.count > 0;
        }
        shownCount = count;
    }

    onSuppressPopupChanged: {
        if (suppressPopup) {
            popupVisible = false;
            toastModel.clear();
        }
    }

    Rectangle {
        id: popupContent
        width: root.overlayWidth
        implicitHeight: popupColumn.implicitHeight + 14
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        color: root.config.overlayBackgroundColor
        
        radius: root.config.overlayRounding
        opacity: root.popupVisible ? root.config.panelOpacity : 0
        y: root.popupVisible ? 0 : 24

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }

        Behavior on y {
            NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            id: popupColumn
            anchors.fill: parent
            anchors.margins: 7
            spacing: 5

            Repeater {
                model: toastModel
                delegate: Rectangle {
                    required property var model
                    readonly property int toastId: Number(model.idNum || 0)
                    Layout.fillWidth: true
                    implicitHeight: notifRow.implicitHeight + 10
                    color: Qt.rgba(root.config.overlayTextColor.r, root.config.overlayTextColor.g, root.config.overlayTextColor.b, 0.035)
                    radius: Math.max(0, root.config.overlayRounding - 4)
                    opacity: model.fading ? 0 : 1

                    Behavior on opacity {
                        NumberAnimation { duration: 140 }
                    }

                    RowLayout {
                        id: notifRow
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 8

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                Label {
                                    text: root._urgencyIcon(model.urgency)
                                    color: root._urgencyColor(model.urgency)
                                    font.family: root.uiFontFamily
                                    font.pixelSize: Math.max(10, root.uiFontSize - 1)
                                    font.bold: true
                                }
                                Label {
                                    text: String(model.appName || model.summary || "")
                                    color: root._urgencyColor(model.urgency)
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    font.bold: true
                                    font.family: root.uiFontFamily
                                    font.pixelSize: root.uiFontSize
                                }
                            }
                            Label {
                                text: String(model.body || "")
                                visible: text.length > 0
                                color: root.config.overlayTextColor
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                font.family: root.uiFontFamily
                                font.pixelSize: Math.max(10, root.uiFontSize - 1)
                            }
                        }
                    }

                    Timer {
                        id: toastLife
                        interval: Math.max(1200, Number(model.lifeMs || 4500))
                        repeat: false
                        running: true
                        onTriggered: {
                            root._setToastFading(parent.toastId, true);
                            removeDelay.start();
                        }
                    }

                    Timer {
                        id: removeDelay
                        interval: 150
                        repeat: false
                        onTriggered: root._removeToast(parent.toastId)
                    }
                }
            }
        }
    }
}
