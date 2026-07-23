import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core

pragma ComponentBehavior: Bound

FloatingWindow {
    id: root

    required property var controlCenterModel

    readonly property bool isAppearance: controlCenterModel.utilityPage === "appearance"
    readonly property bool isPower: controlCenterModel.utilityPage === "power"
    readonly property bool isListPage: !isAppearance && !isPower
    readonly property int pageIndex: isAppearance ? 0 : (isPower ? 1 : 2)
    readonly property string pageTitle: controlCenterModel.utilityPage === "keybinds" ? "Keybinds"
        : controlCenterModel.utilityPage === "appearance" ? "Appearance"
        : controlCenterModel.utilityPage === "power" ? "Power Settings"
        : "System Info"
    readonly property var pageRows: controlCenterModel.utilityPage === "keybinds" ? controlCenterModel.keybindRows
        : controlCenterModel.utilityPage === "appearance" ? controlCenterModel.themeRows
        : controlCenterModel.infoRows

    visible: controlCenterModel.utilityVisible
    implicitWidth: (isAppearance || isPower) ? 360 : 680
    implicitHeight: isPower ? 560 : (isAppearance ? 520 : 500)
    color: Theme.transparent
    // The prefix keeps this window compatible with preserved user rules that
    // already float the dwm control center by title substring.
    title: "dwm control center utility"

    onVisibleChanged: {
        if (!visible) {
            root.controlCenterModel.closeUtility();
        }
    }

    component PowerTile: Rectangle {
        id: powerTile

        property string label: ""
        property bool active: false
        property bool tileEnabled: true
        signal activated()

        Layout.fillWidth: true
        implicitHeight: 32
        opacity: tileEnabled ? 1 : 0.45
        radius: Theme.smallRadius
        color: active ? Theme.surfaceActive : (powerMouse.containsMouse ? Theme.surfaceHover : Theme.surface)
        border.color: active || powerMouse.containsMouse ? Theme.accentSecondary : Theme.border
        border.width: Theme.pillBorderWidth

        UiText {
            anchors.centerIn: parent
            text: powerTile.label
            color: powerTile.active || powerMouse.containsMouse ? Theme.accentSecondary : Theme.text
        }

        MouseArea {
            id: powerMouse
            anchors.fill: parent
            enabled: powerTile.tileEnabled
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: powerTile.activated()
        }
    }

    ShellSurface {
        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                root.controlCenterModel.closeUtility();
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
                    text: root.pageTitle
                    color: Theme.textStrong
                    font.pixelSize: Theme.titleFontSize
                    font.bold: true
                    elide: Text.ElideRight
                }
                ShellButton {
                    label: "Close"
                    onActivated: root.controlCenterModel.closeUtility()
                }
            }

            UiText {
                Layout.fillWidth: true
                visible: root.controlCenterModel.message.length > 0
                text: root.controlCenterModel.message
                color: Theme.textMuted
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.pageIndex

                // Theme picker (Appearance)
                ListView {
                    clip: true
                    spacing: Theme.listSpacing
                    model: root.controlCenterModel.themeRows

                    delegate: Rectangle {
                        id: themeTile
                        required property var modelData
                        width: ListView.view ? ListView.view.width : 0
                        height: 36
                        radius: Theme.smallRadius
                        color: modelData.status === "active" ? Theme.surfaceActive : (themeMouse.containsMouse ? Theme.surfaceHover : Theme.surface)
                        border.color: modelData.status === "active" || themeMouse.containsMouse ? Theme.accentSecondary : Theme.border
                        border.width: Theme.pillBorderWidth
                        opacity: root.controlCenterModel.busy ? 0.5 : 1

                        UiText {
                            anchors.centerIn: parent
                            text: (modelData.status === "active" ? "● " : "") + modelData.name
                            color: modelData.status === "active" || themeMouse.containsMouse ? Theme.accentSecondary : Theme.text
                        }

                        MouseArea {
                            id: themeMouse
                            anchors.fill: parent
                            enabled: !root.controlCenterModel.busy
                            hoverEnabled: true
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.controlCenterModel.setTheme(modelData.name)
                        }
                    }

                    UiText {
                        anchors.centerIn: parent
                        visible: root.controlCenterModel.themeRows.length === 0
                        text: root.controlCenterModel.message.length > 0
                            ? root.controlCenterModel.message
                            : "No themes found"
                        color: Theme.textMuted
                    }
                }

                // Power settings (mangowm: swayidle lock + optional monitor sleep)
                Flickable {
                    id: powerFlickable

                    clip: true
                    contentWidth: width
                    contentHeight: powerColumn.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: powerColumn
                        width: powerFlickable.width
                        spacing: 8

                        UiText {
                            Layout.fillWidth: true
                            text: root.controlCenterModel.powerLockEnabled
                                ? "Lock after " + root.controlCenterModel.formatDuration(root.controlCenterModel.powerLockTimeout)
                                : "Auto lock disabled"
                            color: Theme.textMuted
                        }
                        PowerTile {
                            label: root.controlCenterModel.powerLockEnabled ? "Disable Auto Lock" : "Enable Auto Lock"
                            active: root.controlCenterModel.powerLockEnabled
                            tileEnabled: root.controlCenterModel.powerLockAvailable && !root.controlCenterModel.busy
                            onActivated: root.controlCenterModel.setPowerLock(!root.controlCenterModel.powerLockEnabled)
                        }
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 3
                            columnSpacing: 6
                            rowSpacing: 6
                            Repeater {
                                model: root.controlCenterModel.powerPresets
                                delegate: PowerTile {
                                    required property var modelData
                                    label: modelData.label
                                    active: root.controlCenterModel.powerLockEnabled
                                        && root.controlCenterModel.powerLockTimeout === modelData.seconds
                                    tileEnabled: root.controlCenterModel.powerLockAvailable && !root.controlCenterModel.busy
                                    onActivated: root.controlCenterModel.setPowerLockTimeout(modelData.seconds)
                                }
                            }
                        }

                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.border }

                        UiText {
                            Layout.fillWidth: true
                            text: root.controlCenterModel.powerDpmsEnabled
                                ? "Monitor sleep after " + root.controlCenterModel.formatDuration(root.controlCenterModel.powerDpmsTimeout)
                                : "Monitor sleep disabled (default)"
                            color: Theme.textMuted
                        }
                        PowerTile {
                            label: root.controlCenterModel.powerDpmsEnabled ? "Disable Monitor Sleep" : "Enable Monitor Sleep"
                            active: root.controlCenterModel.powerDpmsEnabled
                            tileEnabled: root.controlCenterModel.powerDpmsAvailable && !root.controlCenterModel.busy
                            onActivated: root.controlCenterModel.setPowerDpms(!root.controlCenterModel.powerDpmsEnabled)
                        }
                        GridLayout {
                            Layout.fillWidth: true
                            columns: 3
                            columnSpacing: 6
                            rowSpacing: 6
                            Repeater {
                                model: root.controlCenterModel.powerPresets
                                delegate: PowerTile {
                                    required property var modelData
                                    label: modelData.label
                                    active: root.controlCenterModel.powerDpmsEnabled
                                        && root.controlCenterModel.powerDpmsTimeout === modelData.seconds
                                    tileEnabled: root.controlCenterModel.powerDpmsAvailable && !root.controlCenterModel.busy
                                    onActivated: root.controlCenterModel.setPowerDpmsTimeout(modelData.seconds)
                                }
                            }
                        }

                        UiText {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            text: root.controlCenterModel.powerLockAvailable
                                ? "Uses swayidle + swaylock. Monitor sleep uses mmsg (opt-in)."
                                : "Idle helpers unavailable — is mango-titus installed?"
                            color: Theme.textMuted
                            font.pixelSize: Theme.smallFontSize
                        }
                    }
                }

                // Keybinds / System Info
                ListView {
                    clip: true
                    spacing: Theme.listSpacing
                    model: root.pageRows

                    delegate: ControlCenterRow {
                        required property var modelData
                        width: ListView.view ? ListView.view.width : 0
                        title: root.controlCenterModel.utilityPage === "keybinds" ? modelData.keys : (modelData.label || "")
                        detail: root.controlCenterModel.utilityPage === "keybinds" ? modelData.description : (modelData.detail || modelData.value || "")
                        status: modelData.status || ""
                    }
                }
            }
        }
    }
}
