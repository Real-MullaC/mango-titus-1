import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core

pragma ComponentBehavior: Bound

PopupWindow {
    id: root

    required property BluetoothModel bluetoothModel
    required property PanelWindow panelWindow

    readonly property int popupWidth: 360
    readonly property int popupHeight: 420

    visible: bluetoothModel.visible
    implicitWidth: popupWidth
    implicitHeight: popupHeight
    anchor.window: panelWindow
    anchor.rect.x: Math.max(Theme.rowSpacing, panelWindow.width - popupWidth - Theme.rowSpacing)
    anchor.rect.y: Theme.panelHeight
    grabFocus: true
    color: Theme.transparent

    onVisibleChanged: if (!visible) root.bluetoothModel.close()

    ShellSurface {
        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                root.bluetoothModel.close();
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: Theme.popupSpacing

            RowLayout {
                Layout.fillWidth: true
                UiText {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: root.bluetoothModel.statusText
                    color: Theme.textStrong
                    font.pixelSize: Theme.titleFontSize
                    font.bold: true
                    elide: Text.ElideRight
                }
                ShellButton { label: qsTr("Scan"); onActivated: root.bluetoothModel.refresh(true) }
            }

            RowLayout {
                Layout.fillWidth: true
                ShellButton { Layout.fillWidth: true; label: qsTr("Bluetooth On"); onActivated: root.bluetoothModel.action("bluetooth-power", ["on"]) }
                ShellButton { Layout.fillWidth: true; label: qsTr("Bluetooth Off"); onActivated: root.bluetoothModel.action("bluetooth-power", ["off"]) }
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: Theme.listSpacing
                model: root.bluetoothModel.devices

                delegate: Rectangle {
                    id: deviceRow

                    required property var modelData
                    width: ListView.view ? ListView.view.width : 0
                    height: 58
                    radius: Theme.smallRadius
                    color: Theme.surface
                    border.color: Theme.border
                    border.width: Theme.pillBorderWidth

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        UiText {
                            Layout.fillWidth: true
                            text: deviceRow.modelData.name.length > 0 ? deviceRow.modelData.name : deviceRow.modelData.address
                            elide: Text.ElideRight
                        }
                        ShellButton {
                            label: deviceRow.modelData.connected ? qsTr("Disconnect") : (deviceRow.modelData.paired ? qsTr("Connect") : qsTr("Pair"))
                            onActivated: root.bluetoothModel.action(deviceRow.modelData.connected ? "bluetooth-disconnect" : (deviceRow.modelData.paired ? "bluetooth-connect" : "bluetooth-pair"), [deviceRow.modelData.address])
                        }
                    }
                }
            }
        }
    }
}
