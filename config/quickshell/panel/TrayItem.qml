import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.core

Item {
    id: root

    required property var trayItem

    readonly property string iconKey: trayItem ? (trayItem.icon || "") : ""
    property var iconSources: []
    property int iconSourceIndex: 0

    function rebuildIconSources() {
        root.iconSources = Icons.trayIconSources(root.trayItem);
        root.iconSourceIndex = 0;
    }

    function openContextMenu() {
        if (root.trayItem && root.trayItem.hasMenu) {
            trayMenu.open();
        }
    }

    function handleClick(button) {
        if (button === Qt.LeftButton) {
            if (!root.trayItem.onlyMenu) {
                root.trayItem.activate();
            } else if (root.trayItem.hasMenu) {
                root.openContextMenu();
            }
        } else if (button === Qt.MiddleButton) {
            root.trayItem.secondaryActivate();
        }
    }

    Component.onCompleted: root.rebuildIconSources()
    onIconKeyChanged: root.rebuildIconSources()

    Layout.preferredWidth: Theme.trayItemSize
    Layout.preferredHeight: Theme.trayItemSize

    Rectangle {
        anchors.fill: parent
        radius: Theme.smallRadius
        color: trayMouse.containsMouse ? Theme.surfaceHover : Theme.transparent
    }

    QsMenuAnchor {
        id: trayMenu

        menu: root.trayItem ? root.trayItem.menu : null
        anchor.item: root
    }

    IconImage {
        id: trayIcon

        anchors.centerIn: parent
        width: Theme.trayIconSize
        height: Theme.trayIconSize
        source: root.iconSources.length > root.iconSourceIndex ? root.iconSources[root.iconSourceIndex] : ""
        implicitSize: Theme.trayIconSize
        asynchronous: true
        mipmap: true
        visible: status === Image.Ready

        onStatusChanged: {
            if (status === Image.Error && root.iconSourceIndex < root.iconSources.length - 1) {
                root.iconSourceIndex += 1;
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: !trayIcon.visible
        text: {
            const title = root.trayItem.tooltipTitle || root.trayItem.title || root.trayItem.id || "?";
            return title.length > 0 ? title.charAt(0).toUpperCase() : "?";
        }
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.tinyFontSize
        font.bold: true
        textFormat: Text.PlainText
    }

    MouseArea {
        id: trayMouse

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onPressed: mouse => {
            if (mouse.button === Qt.RightButton) {
                root.openContextMenu();
                mouse.accepted = true;
            }
        }

        onClicked: mouse => {
            if (mouse.button !== Qt.RightButton) {
                root.handleClick(mouse.button);
            }
        }
    }
}
