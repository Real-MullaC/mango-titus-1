pragma ComponentBehavior: Bound

import QtQuick
import qs.core

Rectangle {
    id: root

    required property string label

    signal activated

    Accessible.role: Accessible.Button
    Accessible.name: root.label
    Accessible.onPressAction: {
        if (root.enabled)
            root.activated();
    }
    activeFocusOnTab: true

    implicitWidth: actionLabel.implicitWidth + 24
    implicitHeight: Theme.buttonHeight
    radius: Theme.radius
    color: !root.enabled ? Theme.surface
        : (controlHover.hovered ? Theme.surfaceHover : Theme.surface)
    border.color: Theme.border
    border.width: 1

    Keys.onPressed: function(event) {
        if (!root.enabled)
            return;
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.activated();
            event.accepted = true;
        }
    }

    HoverHandler {
        id: controlHover

        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        enabled: root.enabled
        acceptedButtons: Qt.LeftButton
        onTapped: root.activated()
    }

    Text {
        id: actionLabel

        anchors.centerIn: parent
        text: root.label
        color: !root.enabled ? Theme.textMuted : Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.panelFontSize
        font.bold: true
        textFormat: Text.PlainText
        elide: Text.ElideRight
    }
}
