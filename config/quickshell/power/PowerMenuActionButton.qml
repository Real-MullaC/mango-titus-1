import QtQuick
import qs.core

Rectangle {
    id: root

    required property var action
    property bool compact: false
    property bool danger: false

    signal activated

    implicitWidth: Math.max(120, labelColumn.implicitWidth + (root.compact ? 24 : 28))
    implicitHeight: root.compact
        ? Theme.confirmButtonHeight
        : Math.max(58, labelColumn.implicitHeight + 20)
    radius: Theme.radius
    color: actionHover.hovered ? Theme.surfaceHover : Theme.surface
    border.color: danger ? Theme.danger : Theme.border
    border.width: 1

    HoverHandler {
        id: actionHover
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: root.activated()
    }

    Column {
        id: labelColumn

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: root.compact ? 12 : 14
        anchors.rightMargin: root.compact ? 12 : 14
        spacing: root.compact ? Theme.compactSpacing : Theme.listSpacing

        Text {
            width: parent.width
            text: root.action.label
            color: root.danger ? Theme.textStrong : Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: root.compact ? Theme.bodyFontSize : Theme.bodyFontSize + 1
            font.bold: true
            textFormat: Text.PlainText
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: root.action.detail || ""
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.smallFontSize
            textFormat: Text.PlainText
            elide: Text.ElideRight
            visible: text.length > 0
        }
    }
}
