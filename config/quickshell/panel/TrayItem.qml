import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.core

Item {
    id: root

    required property SystemTrayItem trayItem

    readonly property string iconKey: trayItem ? (trayItem.icon || "") : ""
    property var iconSources: []
    property int iconSourceIndex: 0

    Accessible.role: Accessible.Button
    Accessible.name: {
        if (!root.trayItem)
            return qsTr("Tray item");
        return root.trayItem.tooltipTitle || root.trayItem.title || root.trayItem.id || qsTr("Tray item");
    }
    Accessible.onPressAction: root.handleClick(Qt.LeftButton)
    activeFocusOnTab: true

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

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.handleClick(Qt.LeftButton);
            event.accepted = true;
        } else if (event.key === Qt.Key_Menu || (event.key === Qt.Key_F10 && event.modifiers & Qt.ShiftModifier)) {
            root.openContextMenu();
            event.accepted = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.smallRadius
        color: trayHover.hovered ? Theme.surfaceHover : Theme.transparent
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

    HoverHandler {
        id: trayHover

        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onTapped: function(eventPoint, button) {
            root.handleClick(button);
        }
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: root.openContextMenu()
    }
}
