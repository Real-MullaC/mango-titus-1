pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.core

Rectangle {
    id: root

    required property string label
    property string detail: ""
    property bool active: false
    property bool danger: false
    readonly property bool hovered: optionHover.hovered

    signal activated

    Accessible.role: Accessible.Button
    Accessible.name: root.label
    Accessible.onPressAction: {
        if (root.enabled)
            root.activated();
    }
    activeFocusOnTab: true

    implicitWidth: Math.max(76, optionLabel.implicitWidth + 22)
    implicitHeight: root.detail.length > 0 ? 48 : Theme.buttonHeight
    color: !root.enabled ? Theme.surface
        : (root.active ? Theme.accent : root.hovered ? Theme.surfaceHover : Theme.surface)
    border.color: !root.enabled ? Theme.border
        : (root.danger ? Theme.danger : root.active ? Theme.accent : Theme.border)
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
        id: optionHover

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
        anchors.margins: 8
        spacing: Theme.compactSpacing

        Text {
            id: optionLabel

            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.fillHeight: root.detail.length === 0
            text: root.label
            color: !root.enabled ? Theme.textMuted
                : (root.active ? Theme.accentText : Theme.textStrong)
            font.family: Theme.fontFamily
            font.pixelSize: Theme.smallFontSize
            font.bold: true
            textFormat: Text.PlainText
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        Text {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            visible: root.detail.length > 0
            text: root.detail
            color: !root.enabled ? Theme.textMuted
                : (root.active ? Theme.accentText : Theme.textMuted)
            font.family: Theme.fontFamily
            font.pixelSize: Theme.tinyFontSize
            textFormat: Text.PlainText
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }
}
