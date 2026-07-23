pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: root

    required property string label
    required property string detail
    readonly property bool hovered: actionHover.hovered

    signal activated

    Accessible.role: Accessible.Button
    Accessible.name: root.label
    Accessible.onPressAction: {
        if (root.enabled)
            root.activated();
    }
    activeFocusOnTab: true

    implicitHeight: 58
    color: !root.enabled ? Theme.surface
        : (root.enabled && root.hovered ? Theme.surfaceHover : Theme.surface)
    border.color: Theme.border
    border.width: 1
    radius: Theme.radius

    Keys.onPressed: function(event) {
        if (!root.enabled)
            return;
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.activated();
            event.accepted = true;
        }
    }

    HoverHandler {
        id: actionHover

        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        enabled: root.enabled
        acceptedButtons: Qt.LeftButton
        onTapped: root.activated()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: Theme.tightSpacing

        Text {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            text: root.label
            color: root.enabled ? Theme.textStrong : Theme.textMuted
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
