import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core

pragma ComponentBehavior: Bound

PopupWindow {
    id: root

    required property PowerMenuModel powerMenuModel
    required property PanelWindow panelWindow

    readonly property int popupWidth: 240
    readonly property int menuHeight: 292
    readonly property int confirmHeight: 210
    readonly property int edgeMargin: Theme.rowSpacing

    visible: powerMenuModel.visible
    implicitWidth: popupWidth
    implicitHeight: powerMenuModel.confirming ? confirmHeight : menuHeight
    anchor.window: panelWindow
    anchor.rect.x: Math.max(edgeMargin, panelWindow.width - popupWidth - edgeMargin)
    anchor.rect.y: Theme.panelHeight
    grabFocus: true
    color: Theme.transparent

    onVisibleChanged: if (!visible) root.powerMenuModel.close()

    readonly property var cancelAction: {
        "label": qsTr("Cancel"),
        "detail": qsTr("Return to power menu")
    }

    readonly property var confirmButtonAction: {
        "label": qsTr("Confirm"),
        "detail": powerMenuModel.pendingAction ? powerMenuModel.pendingAction.label : ""
    }

    ShellSurface {
        id: content

        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                if (root.powerMenuModel.confirming) {
                    root.powerMenuModel.cancelConfirmation();
                } else {
                    root.powerMenuModel.close();
                }
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: Theme.listSpacing

            Repeater {
                model: root.powerMenuModel.confirming ? [] : root.powerMenuModel.sessionActions

                delegate: PowerMenuActionButton {
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: 58
                    action: modelData
                    danger: modelData.id === "shutdown"
                    onActivated: root.powerMenuModel.requestAction(modelData)
                }
            }

            ColumnLayout {
                visible: root.powerMenuModel.confirming
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Theme.sectionSpacing

                Text {
                    Layout.fillWidth: true
                    text: root.powerMenuModel.pendingAction ? root.powerMenuModel.pendingAction.label : ""
                    color: Theme.textStrong
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.inputFontSize
                    font.bold: true
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("This action will affect the current session or system.")
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.smallFontSize
                    textFormat: Text.PlainText
                    wrapMode: Text.WordWrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignBottom
                    spacing: Theme.listSpacing

                    PowerMenuActionButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.confirmButtonHeight
                        action: root.cancelAction
                        compact: true
                        onActivated: root.powerMenuModel.cancelConfirmation()
                    }

                    PowerMenuActionButton {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.confirmButtonHeight
                        action: root.confirmButtonAction
                        compact: true
                        danger: true
                        onActivated: root.powerMenuModel.confirmAction()
                    }
                }
            }
        }
    }
}
