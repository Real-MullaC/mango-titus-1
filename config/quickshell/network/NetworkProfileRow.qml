pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: root

    required property var profile
    property bool active: false
    signal connectRequested(var profile)
    signal disconnectRequested(string device)

    Accessible.role: Accessible.ListItem
    Accessible.name: root.profile ? root.profile.name : qsTr("Network profile")

    implicitHeight: Theme.confirmButtonHeight
    height: implicitHeight
    color: rowHover.hovered ? Theme.surfaceHover : Theme.surface
    radius: Theme.radius

    HoverHandler {
        id: rowHover
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.rowSpacing
        anchors.rightMargin: Theme.rowSpacing
        spacing: Theme.rowSpacing

        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            spacing: Theme.compactSpacing

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: root.profile.name
                color: Theme.textStrong
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelFontSize
                textFormat: Text.PlainText
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: root.active ? qsTr("%1 on %2").arg(root.profile.type).arg(root.profile.device) : root.profile.type
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.smallFontSize
                textFormat: Text.PlainText
                elide: Text.ElideRight
            }
        }

        Rectangle {
            id: actionChip

            Accessible.role: Accessible.Button
            Accessible.name: root.active ? qsTr("Disconnect") : qsTr("Connect")
            Accessible.onPressAction: {
                if (root.active)
                    root.disconnectRequested(root.profile.device);
                else
                    root.connectRequested(root.profile);
            }
            activeFocusOnTab: true

            Layout.preferredWidth: actionText.implicitWidth + 18
            Layout.preferredHeight: Theme.chipHeight
            color: actionHover.hovered ? Theme.accent : Theme.border
            radius: Theme.radius

            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                    if (root.active)
                        root.disconnectRequested(root.profile.device);
                    else
                        root.connectRequested(root.profile);
                    event.accepted = true;
                }
            }

            Text {
                id: actionText

                anchors.centerIn: parent
                text: root.active ? qsTr("Disconnect") : qsTr("Connect")
                color: Theme.textStrong
                font.family: Theme.fontFamily
                font.pixelSize: Theme.smallFontSize
                textFormat: Text.PlainText
            }

            HoverHandler {
                id: actionHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                gesturePolicy: TapHandler.WithinBounds
                onTapped: root.active
                    ? root.disconnectRequested(root.profile.device)
                    : root.connectRequested(root.profile)
            }
        }
    }
}
