import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: root

    property string title: ""
    property string detail: ""
    property string status: ""
    readonly property color statusColor: root.status === "error" ? Theme.danger : root.status === "warn" ? "#ebcb8b" : Theme.accent

    // Height from content — do not anchors.fill the sized axis (feedback clip).
    height: implicitHeight
    implicitHeight: Math.max(42, row.implicitHeight + 20)
    color: Theme.surface
    border.color: root.status === "error" ? Theme.danger : Theme.border
    border.width: 1
    radius: Theme.radius

    RowLayout {
        id: row

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: Theme.rowSpacing

        Rectangle {
            Layout.preferredWidth: 10
            Layout.preferredHeight: 10
            radius: 5
            color: root.statusColor
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: Theme.tightSpacing

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: root.title
                color: Theme.textStrong
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelFontSize
                font.bold: true
                textFormat: Text.PlainText
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: root.detail
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.smallFontSize
                textFormat: Text.PlainText
                elide: Text.ElideRight
            }
        }
    }
}
