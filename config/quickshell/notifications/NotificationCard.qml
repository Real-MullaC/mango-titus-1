pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import qs.core

Rectangle {
    id: root

    required property var item

    signal dismiss
    signal expired

    Layout.fillWidth: true
    Layout.preferredHeight: Math.max(72, content.implicitHeight + 24)

    radius: Theme.radius
    color: root.item.urgency === NotificationUrgency.Critical ? Theme.dangerSurface : Theme.surface
    border.color: root.item.urgency === NotificationUrgency.Critical ? Theme.danger : Theme.border
    border.width: 1

    // One-shot TTL from absolute deadline (avoids per-toast 500ms polling).
    Timer {
        interval: Math.max(0, root.item.expiresAt - Date.now())
        running: true
        repeat: false
        onTriggered: root.expired()
    }

    RowLayout {
        id: content

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: Theme.rowSpacing

        Rectangle {
            Layout.preferredWidth: Theme.notificationAccentWidth
            Layout.fillHeight: true
            Layout.minimumHeight: Theme.closeButtonSize
            radius: Theme.notificationAccentRadius
            color: root.item.urgency === NotificationUrgency.Critical ? Theme.danger : Theme.accent
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.tightSpacing

            Text {
                Layout.fillWidth: true
                text: root.item.appName
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.smallFontSize
                textFormat: Text.PlainText
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.item.summary || root.item.urgencyName
                color: Theme.textStrong
                font.family: Theme.fontFamily
                font.pixelSize: Theme.bodyFontSize
                font.bold: true
                textFormat: Text.PlainText
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: root.item.body || ""
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.smallFontSize
                textFormat: Text.PlainText
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }
        }

        Rectangle {
            id: closeButton

            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Dismiss notification")
            Accessible.onPressAction: root.dismiss()
            activeFocusOnTab: true

            Layout.preferredWidth: Theme.closeButtonSize - Theme.listSpacing
            Layout.preferredHeight: Theme.closeButtonSize - Theme.listSpacing
            radius: Theme.radius
            color: closeHover.hovered ? Theme.surfaceHover : Theme.transparent
            border.color: Theme.border
            border.width: 1

            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                    root.dismiss();
                    event.accepted = true;
                }
            }

            HoverHandler {
                id: closeHover

                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                acceptedButtons: Qt.LeftButton
                onTapped: root.dismiss()
            }

            Text {
                anchors.centerIn: parent
                text: qsTr("x")
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelFontSize
                font.bold: true
                textFormat: Text.PlainText
            }
        }
    }
}
