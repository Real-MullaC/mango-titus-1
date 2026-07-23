import QtQuick
import QtQuick.Layouts
import qs.core

PanelPill {
    id: root

    signal activated

    Layout.preferredWidth: 34
    Layout.preferredHeight: Theme.pillHeight
    Layout.minimumWidth: 34
    hovered: logoMouse.containsMouse
    active: logoMouse.containsMouse

    Item {
        anchors.centerIn: parent
        width: 20
        height: 20

        Image {
            id: logoImage

            anchors.fill: parent
            sourceSize.width: 40
            sourceSize.height: 40
            source: Qt.resolvedUrl("../assets/ctt_logo.png")
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            smooth: true
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

    MouseArea {
        id: logoMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
