pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.core

Item {
    id: root

    required property int index
    required property var modelData
    required property bool selected
    required property LauncherModel launcherModel

    property bool iconFailed: false
    readonly property string iconName: modelData ? (modelData.icon || "") : ""

    Accessible.role: Accessible.Button
    Accessible.name: root.modelData ? root.modelData.name : ""
    Accessible.onPressAction: {
        if (root.modelData)
            root.launcherModel.launchApp(root.modelData);
    }
    activeFocusOnTab: true

    implicitHeight: 54
    height: implicitHeight

    onIconNameChanged: root.iconFailed = false

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.launcherModel.launchApp(root.modelData);
            event.accepted = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: root.selected ? Theme.surface : Theme.transparent
        visible: root.selected
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
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
                    return detail.length > 0 ? qsTr("%1  -  %2").arg(detail).arg(category) : category;
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
