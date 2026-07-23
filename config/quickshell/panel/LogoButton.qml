pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.core

PanelPill {
    id: root

    signal activated

    Accessible.role: Accessible.Button
    Accessible.name: qsTr("Control center")
    Accessible.onPressAction: root.activated()
    activeFocusOnTab: true

    Layout.preferredWidth: 34
    Layout.preferredHeight: Theme.pillHeight
    Layout.minimumWidth: 34
    hovered: logoHover.hovered
    active: logoHover.hovered

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.activated();
            event.accepted = true;
        }
    }

    HoverHandler {
        id: logoHover

        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: root.activated()
    }

    Item {
        anchors.centerIn: parent
        width: 20
        height: 20

        IconImage {
            id: logoImage

            anchors.fill: parent
            source: Qt.resolvedUrl("../assets/ctt_logo.png")
            implicitSize: 20
            asynchronous: true
            mipmap: true
            visible: status === Image.Ready
        }

        UiText {
            anchors.centerIn: parent
            visible: logoImage.status !== Image.Ready
            text: "󰍜"
            color: Theme.accentSecondary
            font.pixelSize: Theme.bodyFontSize
            font.bold: true
        }
    }
}
