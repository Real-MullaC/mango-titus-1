import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core
import qs.health
import qs.power

pragma ComponentBehavior: Bound

PopupWindow {
    id: root

    required property ControlCenterModel controlCenterModel
    required property SystemHealthModel healthModel
    required property PanelWindow panelWindow
    required property PowerMenuModel powerMenuModel

    readonly property int cardWidth: 276
    readonly property int gap: 8
    property string sidePanel: "none"
    readonly property string sideTitleText: sidePanel === "utilities" ? qsTr("Utilities")
        : sidePanel === "actions" ? qsTr("Quick Actions")
        : qsTr("Widgets")

    function openSystemHealth() {
        root.controlCenterModel.close();
        root.healthModel.openOnScreen(root.panelWindow.screen);
    }

    function toggleSidePanel(name) {
        root.sidePanel = root.sidePanel === name ? "none" : name;
        if (root.sidePanel === "actions") {
            root.controlCenterModel.openActions();
        }
    }

    visible: controlCenterModel.visible
    implicitWidth: cardWidth + (sidePanel === "none" ? 0 : cardWidth + gap)
    implicitHeight: sidePanel === "none" ? controlCard.implicitHeight : Math.max(controlCard.implicitHeight, sideCard.implicitHeight)
    anchor.window: panelWindow
    anchor.rect.x: 6
    anchor.rect.y: Theme.panelHeight
    grabFocus: true
    color: Theme.transparent

    onVisibleChanged: {
        if (visible) {
            sidePanel = "none";
            Qt.callLater(function() {
                if (root.visible && controlCard) {
                    controlCard.forceActiveFocus();
                }
            });
        } else if (root.controlCenterModel.visible) {
            // Popup dismissed (X / outside) — keep utility windows open.
            root.controlCenterModel.dismissMenu();
        }
    }

    component Tile: Rectangle {
        id: tile

        property string label: ""
        property bool active: false
        signal activated()

        Accessible.role: Accessible.Button
        Accessible.name: tile.label
        Accessible.onPressAction: {
            if (tile.enabled)
                tile.activated();
        }
        activeFocusOnTab: true

        implicitHeight: 26
        radius: Theme.smallRadius
        color: active ? Theme.surfaceActive : (tileHover.hovered ? Theme.surfaceHover : Theme.surface)
        border.color: !tile.enabled ? Theme.border
            : (active || tileHover.hovered ? Theme.accentSecondary : Theme.border)
        border.width: Theme.pillBorderWidth

        Keys.onPressed: function(event) {
            if (!tile.enabled)
                return;
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                tile.activated();
                event.accepted = true;
            }
        }

        HoverHandler {
            id: tileHover
            enabled: tile.enabled
            cursorShape: tile.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        }

        TapHandler {
            enabled: tile.enabled
            acceptedButtons: Qt.LeftButton
            onTapped: tile.activated()
        }

        UiText {
            anchors.centerIn: parent
            text: tile.label
            color: !tile.enabled ? Theme.textMuted
                : (tile.active || tileHover.hovered ? Theme.accentSecondary : Theme.text)
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: root.gap

        ShellSurface {
            id: controlCard

            Layout.preferredWidth: root.cardWidth
            Layout.maximumHeight: implicitHeight
            Layout.alignment: Qt.AlignTop
            margin: 12
            implicitHeight: controlColumn.implicitHeight + margin * 2
            focus: true

            Keys.onPressed: function(event) {
                if (event.key === Qt.Key_Escape) {
                    root.controlCenterModel.dismissMenu();
                    event.accepted = true;
                }
            }

            ColumnLayout {
                id: controlColumn
                width: parent.width
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true

                    UiText {
                        Layout.fillWidth: true
                        text: qsTr("Control")
                        color: Theme.textStrong
                        font.letterSpacing: 2
                    }

                    UiText {
                        text: qsTr("x")
                        color: closeHover.hovered ? Theme.accent : Theme.textMuted

                        Accessible.role: Accessible.Button
                        Accessible.name: qsTr("Close")
                        Accessible.onPressAction: root.controlCenterModel.dismissMenu()
                        activeFocusOnTab: true

                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                root.controlCenterModel.dismissMenu();
                                event.accepted = true;
                            }
                        }

                        HoverHandler {
                            id: closeHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: root.controlCenterModel.dismissMenu()
                        }
                    }
                }

                UiText {
                    Layout.fillWidth: true
                    visible: root.controlCenterModel.message.length > 0
                    text: root.controlCenterModel.message
                    color: Theme.textMuted
                    elide: Text.ElideRight
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.border }

                UiText { text: qsTr("Actions"); color: Theme.textMuted; font.letterSpacing: 1 }
                Tile {
                    Layout.fillWidth: true
                    label: qsTr("Reload QS-Config")
                    enabled: !root.controlCenterModel.busy
                    onActivated: root.controlCenterModel.runAction("restart-quickshell")
                }
                Tile {
                    Layout.fillWidth: true
                    label: root.sidePanel === "actions" ? qsTr("Quick Actions  <") : qsTr("Quick Actions  >")
                    active: root.sidePanel === "actions"
                    onActivated: root.toggleSidePanel("actions")
                }
                Tile {
                    Layout.fillWidth: true
                    label: qsTr("Power  >")
                    onActivated: {
                        root.controlCenterModel.close();
                        root.powerMenuModel.open();
                    }
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.border }
                UiText { text: qsTr("Bar Functions"); color: Theme.textMuted; font.letterSpacing: 1 }
                Tile {
                    Layout.fillWidth: true
                    label: root.sidePanel === "widgets" ? qsTr("Bar Functions  <") : qsTr("Bar Functions  >")
                    active: root.sidePanel === "widgets"
                    onActivated: root.toggleSidePanel("widgets")
                }

                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.border }
                UiText { text: qsTr("Utilities"); color: Theme.textMuted; font.letterSpacing: 1 }
                Tile {
                    Layout.fillWidth: true
                    label: root.sidePanel === "utilities" ? qsTr("Utilities  <") : qsTr("Utilities  >")
                    active: root.sidePanel === "utilities"
                    onActivated: root.toggleSidePanel("utilities")
                }
            }
        }

        ShellSurface {
            id: sideCard

            Layout.preferredWidth: root.cardWidth
            Layout.maximumHeight: implicitHeight
            Layout.alignment: Qt.AlignTop
            margin: 12
            implicitHeight: sideColumn.implicitHeight + margin * 2
            visible: root.sidePanel !== "none"

            ColumnLayout {
                id: sideColumn
                width: parent.width
                spacing: 8

                UiText {
                    text: root.sideTitleText
                    color: Theme.textStrong
                    font.letterSpacing: 2
                }
                Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.border }

                Loader {
                    Layout.fillWidth: true
                    active: root.sidePanel !== "none"
                    sourceComponent: root.sidePanel === "widgets" ? widgetsSide
                        : root.sidePanel === "utilities" ? utilitiesSide
                        : root.sidePanel === "actions" ? actionsSide
                        : null
                }
            }
        }
    }

    Component {
        id: widgetsSide

        GridLayout {
            width: parent ? parent.width : 0
            columns: 2
            columnSpacing: 8
            rowSpacing: 8

            Repeater {
                model: ["Volume", "Bluetooth", "Network", "Power", "Workspaces"]
                delegate: Tile {
                    required property string modelData
                    Layout.fillWidth: true
                    label: qsTr(modelData)
                    active: root.controlCenterModel.widgetEnabled(modelData)
                    onActivated: root.controlCenterModel.toggleWidget(modelData)
                }
            }
        }
    }

    Component {
        id: utilitiesSide

        ColumnLayout {
            width: parent ? parent.width : 0
            spacing: 8

            Tile {
                Layout.fillWidth: true
                label: qsTr("System Health  >")
                onActivated: root.openSystemHealth()
            }
            Tile {
                Layout.fillWidth: true
                label: qsTr("Appearance  >")
                onActivated: root.controlCenterModel.openAppearance()
            }
            Tile {
                Layout.fillWidth: true
                label: qsTr("Keybinds  >")
                onActivated: root.controlCenterModel.openKeybinds()
            }
            Tile {
                Layout.fillWidth: true
                label: qsTr("Power Settings  >")
                onActivated: root.controlCenterModel.openPower()
            }
            Tile {
                Layout.fillWidth: true
                label: qsTr("System Info  >")
                onActivated: root.controlCenterModel.openInfo()
            }
        }
    }

    Component {
        id: actionsSide

        ColumnLayout {
            width: parent ? parent.width : 0
            spacing: 8

            Repeater {
                model: root.controlCenterModel.actions
                delegate: Tile {
                    id: actionTile

                    required property var modelData

                    Layout.fillWidth: true
                    label: actionTile.modelData.label
                    enabled: !root.controlCenterModel.busy
                    onActivated: root.controlCenterModel.runAction(actionTile.modelData.id)
                }
            }
        }
    }
}
