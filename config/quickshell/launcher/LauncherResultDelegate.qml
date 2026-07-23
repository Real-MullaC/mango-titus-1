import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.core

Item {
    id: root

    required property int index
    required property var modelData
    required property bool selected
    required property var launcherModel

    property bool iconFailed: false
    readonly property string iconName: modelData ? (modelData.icon || "") : ""

    implicitHeight: 54
    height: implicitHeight

    onIconNameChanged: root.iconFailed = false

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: root.selected ? Theme.surface : Theme.transparent
        visible: root.selected
    }

    TapHandler {
        onTapped: root.launcherModel.launchApp(root.modelData)
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.rowSpacing

        Item {
            Layout.preferredWidth: Theme.iconSize
            Layout.preferredHeight: Theme.iconSize
            Layout.alignment: Qt.AlignVCenter

            IconImage {
                id: appIcon

                anchors.fill: parent
                source: Icons.launcherIcon(root.modelData.icon)
                asynchronous: true
                visible: status === Image.Ready && !root.iconFailed

                onStatusChanged: {
                    if (status === Image.Error) {
                        root.iconFailed = true;
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.iconFailed || appIcon.status !== Image.Ready
                text: {
                    const name = root.modelData.name || "?";
                    return name.length > 0 ? name.charAt(0).toUpperCase() : "?";
                }
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.tinyFontSize
                font.bold: true
                textFormat: Text.PlainText
            }
        }

        Column {
            Layout.fillWidth: true
            spacing: Theme.tightSpacing

            Text {
                width: parent.width
                text: root.modelData.name
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.bodyFontSize
                font.bold: root.selected
                textFormat: Text.PlainText
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                readonly property string detailLine: {
                    const detail = root.modelData.generic.length > 0 ? root.modelData.generic : root.modelData.comment;
                    const category = root.launcherModel.categoryLabel(root.modelData.primaryCategory);
                    return detail.length > 0 ? (detail + "  -  " + category) : category;
                }
                text: detailLine
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.smallFontSize
                textFormat: Text.PlainText
                elide: Text.ElideRight
                visible: detailLine.length > 0
            }
        }
    }
}
