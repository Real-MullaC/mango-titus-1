pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: root

    required property string label
    required property bool selected
    signal clicked()

    Accessible.role: Accessible.Button
    Accessible.name: root.label
    Accessible.onPressAction: root.clicked()
    activeFocusOnTab: true

    Layout.preferredWidth: Theme.workspaceButtonSize
    Layout.preferredHeight: Theme.workspaceButtonSize
    Layout.minimumWidth: Theme.workspaceButtonSize
    radius: Theme.smallRadius
    color: selected ? Theme.surfaceActive : (workspaceHover.hovered ? Theme.surfaceHover : Theme.transparent)
    border.color: selected ? Theme.accentSecondary : Theme.transparent
    border.width: selected ? Theme.pillBorderWidth : 0

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.clicked();
            event.accepted = true;
        }
    }

    HoverHandler {
        id: workspaceHover

        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: root.clicked()
    }

    Text {
        anchors.centerIn: parent
        text: root.label
        color: root.selected ? Theme.accentSecondary : Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.panelFontSize
        font.bold: root.selected
        textFormat: Text.PlainText
        verticalAlignment: Text.AlignVCenter
    }
}
