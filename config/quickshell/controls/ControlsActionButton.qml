import QtQuick
import qs.core

Rectangle {
    id: root

    required property string label

    signal activated

    implicitWidth: actionLabel.implicitWidth + 24
    implicitHeight: Theme.buttonHeight
    radius: Theme.radius
    color: controlHover.hovered && root.enabled ? Theme.surfaceHover : Theme.surface
    border.color: Theme.border
    border.width: 1
    opacity: root.enabled ? 1 : 0.5

    HoverHandler {
        id: controlHover
        enabled: root.enabled
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
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.panelFontSize
        font.bold: true
        textFormat: Text.PlainText
        elide: Text.ElideRight
    }
}
