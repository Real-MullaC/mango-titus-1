import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core

pragma ComponentBehavior: Bound

PopupWindow {
    id: root

    required property NetworkModel networkModel
    required property PanelWindow panelWindow

    readonly property int popupWidth: 620
    readonly property int popupHeight: 680
    readonly property int edgeMargin: Theme.rowSpacing

    visible: networkModel.visible
    implicitWidth: popupWidth
    implicitHeight: popupHeight
    anchor.window: panelWindow
    anchor.rect.x: Math.max(edgeMargin, panelWindow.width - popupWidth - edgeMargin)
    anchor.rect.y: Theme.panelHeight
    grabFocus: true
    color: Theme.transparent

    onVisibleChanged: {
        if (visible) {
            if (wifiPasswordInput.text !== root.networkModel.wifiPassword) {
                wifiPasswordInput.text = root.networkModel.wifiPassword;
            }
        } else {
            root.networkModel.close();
        }
    }

    Connections {
        target: root.networkModel

        function onWifiPasswordChanged() {
            if (wifiPasswordInput.text !== root.networkModel.wifiPassword) {
                wifiPasswordInput.text = root.networkModel.wifiPassword;
            }
        }
    }

    ShellSurface {
        id: content

        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                root.networkModel.close();
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: Theme.popupSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.rowSpacing

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: root.networkModel.statusText
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
                    label: qsTr("Scan")
                    enabled: !root.networkModel.busy
                    onActivated: root.networkModel.refresh(true)
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.networkModel.message.length > 0
                text: root.networkModel.message
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.smallFontSize
                textFormat: Text.PlainText
                elide: Text.ElideRight
            }

            SectionLabel {
                label: qsTr("Active")
            }

            ListView {
                readonly property int rowHeight: Theme.confirmButtonHeight
                readonly property int rowCount: root.networkModel.activeConnections.length

                Layout.fillWidth: true
                Layout.preferredHeight: rowCount === 0 ? 0
                    : Math.min(150, rowCount * rowHeight + Math.max(0, rowCount - 1) * Theme.listSpacing)
                visible: rowCount > 0
                clip: true
                spacing: Theme.listSpacing
                model: root.networkModel.activeConnections

                delegate: NetworkProfileRow {
                    required property var modelData

                    width: ListView.view ? ListView.view.width : 0
                    profile: modelData
                    active: true
                    onDisconnectRequested: device => root.networkModel.disconnectDevice(device)
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.networkModel.activeConnections.length === 0
                text: qsTr("No active connections")
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.smallFontSize
                textFormat: Text.PlainText
            }

            SectionLabel {
                label: qsTr("Wi-Fi")
            }

            ListView {
                readonly property int rowHeight: 54
                readonly property int rowCount: root.networkModel.wifiNetworks.length

                Layout.fillWidth: true
                Layout.preferredHeight: rowCount === 0 ? 0
                    : Math.min(220, rowCount * rowHeight + Math.max(0, rowCount - 1) * Theme.listSpacing)
                visible: rowCount > 0
                clip: true
                spacing: Theme.listSpacing
                model: root.networkModel.wifiNetworks

                delegate: NetworkWifiRow {
                    required property int index
                    required property var modelData

                    width: ListView.view ? ListView.view.width : 0
                    network: modelData
                    selected: index === root.networkModel.selectedWifiIndex
                    busy: root.networkModel.busy
                    onSelectedRequested: root.networkModel.selectWifi(index)
                    onConnectRequested: network => {
                        root.networkModel.selectWifi(index);
                        root.networkModel.connectWifi(network);
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.networkModel.wifiNetworks.length === 0
                text: qsTr("No visible Wi-Fi networks")
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.smallFontSize
                textFormat: Text.PlainText
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: root.networkModel.selectedWifi && root.networkModel.selectedWifi.secured ? 44 : 0
                visible: root.networkModel.selectedWifi && root.networkModel.selectedWifi.secured
                color: Theme.surface
                radius: Theme.radius

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.rowSpacing
                    anchors.rightMargin: Theme.rowSpacing
                    spacing: Theme.rowSpacing

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        TextInput {
                            id: wifiPasswordInput

                            anchors.fill: parent
                            echoMode: TextInput.Password
                            color: Theme.textStrong
                            selectionColor: Theme.accent
                            selectedTextColor: Theme.accentText
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.inputFontSize
                            clip: true
                            verticalAlignment: TextInput.AlignVCenter
                            enabled: !root.networkModel.busy

                            onTextEdited: root.networkModel.wifiPassword = text
                            onAccepted: root.networkModel.connectSelectedWifi()
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            visible: wifiPasswordInput.text.length === 0
                            text: qsTr("Password")
                            color: Theme.placeholder
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.inputFontSize
                            textFormat: Text.PlainText
                        }
                    }

                    ShellButton {
                        Layout.preferredWidth: implicitWidth
                        Layout.preferredHeight: Theme.buttonHeight
                        label: qsTr("Connect")
                        enabled: !root.networkModel.busy
                        onActivated: root.networkModel.connectSelectedWifi()
                    }
                }
            }

            SectionLabel {
                label: qsTr("Saved")
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.networkModel.savedProfiles.length > 0
                clip: true
                spacing: Theme.listSpacing
                model: root.networkModel.savedProfiles

                delegate: NetworkProfileRow {
                    required property var modelData

                    width: ListView.view ? ListView.view.width : 0
                    profile: modelData
                    active: false
                    onConnectRequested: profile => root.networkModel.connectProfile(profile)
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.networkModel.savedProfiles.length === 0
                text: qsTr("No saved Ethernet, Wi-Fi, or VPN profiles")
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.smallFontSize
                textFormat: Text.PlainText
            }

            ShellButton {
                Layout.fillWidth: true
                Layout.preferredHeight: root.networkModel.editorAvailable ? 36 : 0
                visible: root.networkModel.editorAvailable
                label: qsTr("Edit Connections")
                compact: false
                onActivated: root.networkModel.openEditor()
            }
        }
    }
}
