pragma ComponentBehavior: Bound

import QtQuick
import qs.core

Rectangle {
    id: root

    required property string label
    property bool danger: false
    property bool compact: true
    readonly property bool hovered: buttonHover.hovered

    signal activated

    Accessible.role: Accessible.Button
    Accessible.name: root.label
    Accessible.onPressAction: {
        if (root.enabled)
            root.activated();
    }
    activeFocusOnTab: true

    implicitWidth: buttonLabel.implicitWidth + 18
    implicitHeight: Theme.buttonHeight
    color: !root.enabled ? Theme.surface
        : (hovered ? Theme.surfaceHover : Theme.surface)
    border.color: !root.enabled ? Theme.border
        : (danger ? Theme.danger : Theme.border)
    border.width: 1
    radius: Theme.radius

    Keys.onPressed: function(event) {
        if (!root.enabled)
            return;
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.activated();
            event.accepted = true;
        }
    }

    HoverHandler {
        id: buttonHover

        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        enabled: root.enabled
        acceptedButtons: Qt.LeftButton
        onTapped: root.activated()
    }

    Text {
        id: buttonLabel

        anchors.centerIn: parent
        text: root.label
        color: !root.enabled ? Theme.textMuted
            : (root.danger ? Theme.textStrong : Theme.text)
        font.family: Theme.fontFamily
        font.pixelSize: root.compact ? Theme.smallFontSize : Theme.panelFontSize
        font.bold: true
        textFormat: Text.PlainText
        elide: Text.ElideRight
    }
}
