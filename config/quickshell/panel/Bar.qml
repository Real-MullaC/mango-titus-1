import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.controlcenter
import qs.controls
import qs.core
import qs.network
import qs.power
import qs.state

pragma ComponentBehavior: Bound

// qmllint disable uncreatable-type
PanelWindow {
    id: root

    required property WmState state
    required property SystemClock clock
    required property NetworkModel networkModel
    required property ControlsModel controlsModel
    required property BluetoothModel bluetoothModel
    required property ControlCenterModel controlCenterModel
    required property PowerMenuModel powerMenuModel

    implicitHeight: Theme.panelHeight
    color: Theme.transparent
    exclusiveZone: Theme.panelHeight
    aboveWindows: true

    anchors {
        top: true
        left: true
        right: true
    }

    Rectangle {
        id: island

        anchors.fill: parent
        anchors.leftMargin: Theme.panelEdgeMargin
        anchors.rightMargin: Theme.panelEdgeMargin
        anchors.topMargin: Theme.panelMargin
        anchors.bottomMargin: Theme.panelMargin
        color: Theme.barBackground
        border.color: Theme.border
        border.width: Theme.pillBorderWidth
        radius: Theme.barRadius

        PillShadow { cornerRadius: island.radius }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.panelGap
            anchors.rightMargin: Theme.panelGap
            spacing: Theme.panelGap

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0

                RowLayout {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, parent.width)
                    spacing: 6

                    LogoButton {
                        onActivated: root.controlCenterModel.toggle()
                    }

                    PanelPill {
                        id: workspacePill

                        visible: root.controlCenterModel.showWorkspaceWidget
                        // Size from content only — never cap via parent.width (circular layout
                        // was clipping tags and hiding the menu button).
                        implicitWidth: workspaceRow.implicitWidth + 10
                        Layout.preferredWidth: implicitWidth
                        Layout.preferredHeight: Theme.pillHeight

                        RowLayout {
                            id: workspaceRow

                            anchors.centerIn: parent
                            spacing: 3

                            Repeater {
                                model: root.state.workspaceNames

                                delegate: WorkspaceButton {
                                    required property int index
                                    required property string modelData

                                    label: modelData
                                    selected: index === root.state.currentWorkspace
                                    onClicked: root.state.switchWorkspace(index)
                                }
                            }
                        }
                    }

                    PanelPill {
                        implicitWidth: Math.min(260, Math.max(96, activeWindowLabel.implicitWidth + Theme.pillHorizontalPadding * 2))
                        Layout.preferredWidth: implicitWidth
                        Layout.preferredHeight: Theme.pillHeight

                        UiText {
                            id: activeWindowLabel

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: Theme.pillHorizontalPadding
                            anchors.rightMargin: Theme.pillHorizontalPadding
                            text: root.state.activeWindowTitle
                            color: Theme.text
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            PanelPill {
                Layout.preferredWidth: clockLabel.implicitWidth + Theme.pillHorizontalPadding * 2
                Layout.preferredHeight: Theme.pillHeight

                UiText {
                    id: clockLabel

                    anchors.centerIn: parent
                    text: Qt.formatDateTime(root.clock.date, "ddd dd MMM  HH:mm")
                    color: Theme.textStrong
                    font.bold: true
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0

                RowLayout {
                    anchors.fill: parent
                    spacing: Theme.panelGap

                    Item { Layout.fillWidth: true }

                    Repeater {
                        model: root.state.statusSegments

                        delegate: UiText {
                            required property string modelData
                            text: modelData
                            color: Theme.text
                        }
                    }

                    TrayArea {
                        Layout.maximumWidth: 160
                        Layout.minimumWidth: 0
                    }

                    PanelPill {
                        visible: root.controlCenterModel.showVolumeWidget
                        Layout.preferredWidth: volumeRow.implicitWidth + Theme.pillHorizontalPadding * 2
                        Layout.maximumWidth: 120
                        Layout.preferredHeight: Theme.pillHeight
                        active: root.controlsModel.visible
                        hovered: volumeHover.hovered

                        Accessible.role: Accessible.Button
                        Accessible.name: qsTr("Volume")
                        Accessible.onPressAction: root.controlsModel.toggle()
                        activeFocusOnTab: true

                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                root.controlsModel.toggle();
                                event.accepted = true;
                            }
                        }

                        HoverHandler {
                            id: volumeHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: root.controlsModel.toggle()
                        }

                        RowLayout {
                            id: volumeRow

                            anchors.centerIn: parent
                            spacing: Theme.compactSpacing + 2

                            Rectangle {
                                Layout.preferredWidth: 30
                                Layout.preferredHeight: 6
                                radius: 3
                                color: Theme.borderStrong

                                Rectangle {
                                    width: Math.max(4, parent.width * root.controlsModel.volumePercent / 100)
                                    height: parent.height
                                    radius: parent.radius
                                    color: Theme.accentSecondary
                                }
                            }

                            UiText {
                                text: root.controlsModel.volumeMuted ? qsTr("Muted") : qsTr("%1%").arg(root.controlsModel.volumePercent)
                                color: Theme.accentSecondary
                            }
                        }
                    }

                    PanelPill {
                        visible: root.controlCenterModel.showBluetoothWidget
                        Layout.preferredWidth: bluetoothRow.implicitWidth + Theme.pillHorizontalPadding * 2
                        Layout.preferredHeight: Theme.pillHeight
                        active: root.bluetoothModel.visible
                        hovered: bluetoothHover.hovered

                        Accessible.role: Accessible.Button
                        Accessible.name: qsTr("Bluetooth")
                        Accessible.onPressAction: root.bluetoothModel.toggle()
                        activeFocusOnTab: true

                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                root.bluetoothModel.toggle();
                                event.accepted = true;
                            }
                        }

                        HoverHandler {
                            id: bluetoothHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: root.bluetoothModel.toggle()
                        }

                        RowLayout {
                            id: bluetoothRow
                            anchors.centerIn: parent
                            spacing: Theme.compactSpacing

                            IconText { text: "󰂯" }
                            UiText { text: qsTr("BT") }
                        }
                    }

                    PanelPill {
                        visible: root.controlCenterModel.showNetworkWidget
                        Layout.preferredWidth: networkRow.implicitWidth + Theme.pillHorizontalPadding * 2
                        Layout.preferredHeight: Theme.pillHeight
                        active: root.networkModel.visible
                        hovered: networkHover.hovered

                        Accessible.role: Accessible.Button
                        Accessible.name: qsTr("Network")
                        Accessible.onPressAction: root.networkModel.toggle()
                        activeFocusOnTab: true

                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                root.networkModel.toggle();
                                event.accepted = true;
                            }
                        }

                        HoverHandler {
                            id: networkHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: root.networkModel.toggle()
                        }

                        RowLayout {
                            id: networkRow
                            anchors.centerIn: parent
                            spacing: Theme.compactSpacing

                            UiText { text: qsTr("NET") }
                            IconText {
                                text: root.networkModel.networkOffline ? "󰤭" : "󰤨"
                            }
                        }
                    }

                    PanelPill {
                        visible: root.controlCenterModel.showPowerWidget
                        Layout.preferredWidth: Theme.pillHeight
                        Layout.preferredHeight: Theme.pillHeight
                        active: root.powerMenuModel.visible
                        hovered: powerHover.hovered

                        Accessible.role: Accessible.Button
                        Accessible.name: qsTr("Power")
                        Accessible.onPressAction: root.powerMenuModel.toggle()
                        activeFocusOnTab: true

                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                root.powerMenuModel.toggle();
                                event.accepted = true;
                            }
                        }

                        HoverHandler {
                            id: powerHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: root.powerMenuModel.toggle()
                        }

                        IconText {
                            anchors.centerIn: parent
                            text: "󰐥"
                            color: Theme.accentSecondary
                        }
                    }
                }
            }
        }
    }
}
