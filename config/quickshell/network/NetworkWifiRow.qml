import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: root

    required property var network
    property bool selected: false
    property bool busy: false
    signal selectedRequested
    signal connectRequested(var network)

    implicitHeight: 54
    height: implicitHeight
    color: root.selected ? Theme.surfaceHover : (rowHover.hovered ? Theme.surfaceHover : Theme.surface)
    border.color: root.selected ? Theme.accent : Theme.border
    border.width: root.selected ? 1 : 0
    radius: Theme.radius

    HoverHandler {
        id: rowHover
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: root.selectedRequested()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.rowSpacing
        anchors.rightMargin: Theme.rowSpacing
        spacing: Theme.rowSpacing

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.compactSpacing

            Text {
                Layout.fillWidth: true
                text: root.network.ssid
                color: Theme.textStrong
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelFontSize
                textFormat: Text.PlainText
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: (root.network.security.length > 0 ? root.network.security : "Open") + " - " + root.network.signal + "% - " + root.network.device
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.smallFontSize
                textFormat: Text.PlainText
                elide: Text.ElideRight
            }
        }

        Text {
            Layout.preferredWidth: 54
            text: root.network.active ? "Active" : ""
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.smallFontSize
            textFormat: Text.PlainText
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
        }

        Rectangle {
            id: connectChip

            Layout.preferredWidth: actionText.implicitWidth + 18
            Layout.preferredHeight: Theme.chipHeight
            color: connectHover.hovered && !root.busy ? Theme.accent : Theme.border
            radius: Theme.radius
            opacity: root.busy ? 0.5 : 1

            Text {
                id: actionText

                anchors.centerIn: parent
                text: "Connect"
                color: Theme.textStrong
                font.family: Theme.fontFamily
                font.pixelSize: Theme.smallFontSize
                textFormat: Text.PlainText
            }

            HoverHandler {
                id: connectHover
                enabled: !root.busy
            }

            TapHandler {
                enabled: !root.busy
                acceptedButtons: Qt.LeftButton
                gesturePolicy: TapHandler.WithinBounds
                onTapped: root.connectRequested(root.network)
            }
        }
    }
}
