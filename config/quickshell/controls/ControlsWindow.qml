import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core

pragma ComponentBehavior: Bound

PopupWindow {
    id: root

    required property ControlsModel controlsModel
    required property PanelWindow panelWindow

    readonly property int popupWidth: 360
    readonly property int popupHeight: 560
    readonly property int edgeMargin: Theme.rowSpacing
    readonly property int contentSpacing: Theme.popupSpacing
    readonly property int rowSpacing: Theme.rowSpacing
    readonly property int actionButtonHeight: Theme.compactButtonHeight
    readonly property int volumeControlHeight: 46
    readonly property int volumePercentWidth: 42
    readonly property int muteButtonWidth: 84
    readonly property int outputDeviceRowHeight: 34

    visible: controlsModel.visible
    implicitWidth: popupWidth
    implicitHeight: popupHeight
    anchor.window: panelWindow
    anchor.rect.x: Math.max(edgeMargin, panelWindow.width - popupWidth - edgeMargin)
    anchor.rect.y: Theme.panelHeight
    grabFocus: true
    color: Theme.transparent

    onVisibleChanged: {
        if (visible) {
            Qt.callLater(function() {
                if (root.visible && content) {
                    content.forceActiveFocus();
                }
            });
        } else {
            root.controlsModel.close();
        }
    }

    function setVolumePendingFromX(x) {
        volumeSlider.pendingPercent = volumeSlider.percentFromX(x);
    }

    ShellSurface {
        id: content

        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                root.controlsModel.close();
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: root.contentSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: root.rowSpacing

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: root.controlsModel.volumeDisplayText
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.titleFontSize
                    font.bold: true
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }

                ShellButton {
                    Layout.preferredWidth: implicitWidth
                    Layout.preferredHeight: Theme.buttonHeight
                    label: qsTr("Refresh")
                    onActivated: root.controlsModel.refresh()
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.controlsModel.message.length > 0
                text: root.controlsModel.message
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.smallFontSize
                textFormat: Text.PlainText
                elide: Text.ElideRight
            }

            SectionLabel {
                label: qsTr("Volume")
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: root.rowSpacing

                Item {
                    id: volumeSlider

                    property int pendingPercent: root.controlsModel.volumePercent
                    readonly property int displayPercent: volumeMouse.pressed ? pendingPercent : root.controlsModel.volumePercent

                    Accessible.role: Accessible.Slider
                    Accessible.name: qsTr("Volume")
                    Accessible.description: qsTr("%1 percent").arg(volumeSlider.displayPercent)
                    activeFocusOnTab: true

                    Layout.fillWidth: true
                    Layout.preferredHeight: root.volumeControlHeight

                    function percentFromX(x) {
                        return Math.max(0, Math.min(100, Math.round((x / Math.max(1, width)) * 100)));
                    }

                    Rectangle {
                        id: sliderTrack

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: 8
                        color: Theme.surface
                        radius: Theme.radius

                        Rectangle {
                            width: Math.round((volumeSlider.displayPercent / 100) * parent.width)
                            height: parent.height
                            color: root.controlsModel.volumeMuted ? Theme.textMuted : Theme.accent
                            radius: parent.radius
                        }
                    }

                    Rectangle {
                        width: 20
                        height: 20
                        x: Math.max(0, Math.min(parent.width - width, Math.round((volumeSlider.displayPercent / 100) * parent.width) - width / 2))
                        y: parent.height / 2 - height / 2
                        color: volumeMouse.enabled ? Theme.text : Theme.textMuted
                        border.color: Theme.border
                        border.width: 1
                        radius: height / 2
                    }

                    MouseArea {
                        id: volumeMouse

                        anchors.fill: parent
                        enabled: !root.controlsModel.busy
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: function(mouse) {
                            root.setVolumePendingFromX(mouse.x);
                        }
                        onPositionChanged: function(mouse) {
                            if (pressed) {
                                root.setVolumePendingFromX(mouse.x);
                            }
                        }
                        onReleased: function(mouse) {
                            root.setVolumePendingFromX(mouse.x);
                            root.controlsModel.volumeSet(volumeSlider.pendingPercent);
                        }
                    }
                }

                Text {
                    Layout.preferredWidth: root.volumePercentWidth
                    text: root.controlsModel.volumePercent + "%"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelFontSize
                    font.bold: true
                    textFormat: Text.PlainText
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                }

                ControlsActionButton {
                    Layout.preferredWidth: root.muteButtonWidth
                    Layout.preferredHeight: root.volumeControlHeight
                    label: root.controlsModel.volumeMuted ? qsTr("Unmute") : qsTr("Mute")
                    enabled: !root.controlsModel.busy
                    onActivated: root.controlsModel.volumeToggleMute()
                }
            }

            SectionLabel {
                label: qsTr("Output")
            }

            Text {
                Layout.fillWidth: true
                visible: root.controlsModel.outputDevices.length === 0
                text: qsTr("OUTPUT unavailable")
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelFontSize
                font.bold: true
                textFormat: Text.PlainText
                elide: Text.ElideRight
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.maximumHeight: 180
                visible: root.controlsModel.outputDevices.length > 0
                clip: true
                spacing: Theme.compactSpacing
                model: root.controlsModel.outputDevices

                delegate: Rectangle {
                    id: outputDeviceRow

                    required property var modelData

                    Accessible.role: Accessible.Button
                    Accessible.name: outputDeviceRow.modelData.description
                    Accessible.onPressAction: {
                        if (!root.controlsModel.busy && !outputDeviceRow.modelData.isDefault)
                            root.controlsModel.outputSetDefault(outputDeviceRow.modelData.name);
                    }
                    activeFocusOnTab: !outputDeviceRow.modelData.isDefault

                    width: ListView.view ? ListView.view.width : 0
                    height: root.outputDeviceRowHeight
                    radius: Theme.radius
                    color: outputDeviceRow.modelData.isDefault || (root.controlsModel.busy && !outputDeviceRow.modelData.isDefault)
                        ? Theme.surface
                        : (outputHover.hovered ? Theme.surfaceHover : Theme.surface)
                    border.color: outputDeviceRow.modelData.isDefault ? Theme.accent : Theme.border
                    border.width: 1

                    Keys.onPressed: function(event) {
                        if (root.controlsModel.busy || outputDeviceRow.modelData.isDefault)
                            return;
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                            root.controlsModel.outputSetDefault(outputDeviceRow.modelData.name);
                            event.accepted = true;
                        }
                    }

                    HoverHandler {
                        id: outputHover
                        enabled: !root.controlsModel.busy && !outputDeviceRow.modelData.isDefault
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    }

                    TapHandler {
                        enabled: !root.controlsModel.busy && !outputDeviceRow.modelData.isDefault
                        acceptedButtons: Qt.LeftButton
                        onTapped: root.controlsModel.outputSetDefault(outputDeviceRow.modelData.name)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: root.rowSpacing

                        Text {
                            Layout.fillWidth: true
                            text: outputDeviceRow.modelData.description
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.panelFontSize
                            font.bold: outputDeviceRow.modelData.isDefault
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            Layout.preferredWidth: 58
                            text: outputDeviceRow.modelData.isDefault ? qsTr("Default") : qsTr("Set")
                            color: outputDeviceRow.modelData.isDefault ? Theme.accent : Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.smallFontSize
                            font.bold: true
                            textFormat: Text.PlainText
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: root.rowSpacing

                SectionLabel {
                    label: qsTr("Microphone")
                }

                Text {
                    text: root.controlsModel.micText
                    color: root.controlsModel.micText === qsTr("MIC muted") ? Theme.danger : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelFontSize
                    font.bold: true
                    textFormat: Text.PlainText
                }
            }

            SectionLabel {
                label: qsTr("Media")
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 54
                color: Theme.surface
                radius: Theme.radius
                border.color: Theme.border
                border.width: 1

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: Theme.compactSpacing

                    Text {
                        width: parent.width
                        text: root.controlsModel.mediaText
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelFontSize
                        font.bold: true
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        visible: root.controlsModel.mediaPlayer.length > 0
                        text: root.controlsModel.mediaPlayer
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.smallFontSize
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.listSpacing * 2

                ControlsActionButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.actionButtonHeight
                    label: qsTr("Previous")
                    enabled: !root.controlsModel.busy && root.controlsModel.mediaPlayer.length > 0
                    onActivated: root.controlsModel.mediaPrevious()
                }

                ControlsActionButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.actionButtonHeight
                    label: qsTr("Play/Pause")
                    enabled: !root.controlsModel.busy && root.controlsModel.mediaPlayer.length > 0
                    onActivated: root.controlsModel.mediaPlayPause()
                }

                ControlsActionButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.actionButtonHeight
                    label: qsTr("Next")
                    enabled: !root.controlsModel.busy && root.controlsModel.mediaPlayer.length > 0
                    onActivated: root.controlsModel.mediaNext()
                }
            }
        }
    }
}
