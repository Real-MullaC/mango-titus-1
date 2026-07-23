import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: root

    required property string label
    required property bool selected
    signal clicked()

    Layout.preferredWidth: Theme.workspaceButtonSize
    Layout.preferredHeight: Theme.workspaceButtonSize
    Layout.minimumWidth: Theme.workspaceButtonSize
    radius: Theme.smallRadius
    color: selected ? Theme.surfaceActive : (workspaceMouse.containsMouse ? Theme.surfaceHover : Theme.transparent)
    border.color: selected ? Theme.accentSecondary : Theme.transparent
    border.width: selected ? Theme.pillBorderWidth : 0

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

    MouseArea {
        id: workspaceMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
