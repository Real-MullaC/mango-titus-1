import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core

pragma ComponentBehavior: Bound

FloatingWindow {
    id: root

    required property SystemHealthModel healthModel

    title: qsTr("System Health")
    visible: healthModel.visible
    // Leave fullscreen while elevating so the mate-polkit password dialog is not covered.
    fullscreen: visible && !healthModel.systemRunning
    color: Theme.bg

    onVisibleChanged: {
        if (visible) {
            Qt.callLater(function() {
                if (root.visible && content) {
                    content.forceActiveFocus();
                }
            });
        } else {
            root.healthModel.close();
        }
    }

    Item {
        id: content

        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Escape) {
                if (root.healthModel.confirming) {
                    root.healthModel.cancelRepair();
                } else {
                    root.healthModel.close();
                }
                event.accepted = true;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: Theme.sectionSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.sectionSpacing

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: Theme.tightSpacing

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("System Health")
                        color: Theme.textStrong
                        font.family: Theme.fontFamily
                        font.pixelSize: 26
                        font.bold: true
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.healthModel.coverageMessage
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.smallFontSize
                        textFormat: Text.PlainText
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 170
                    Layout.preferredHeight: 42
                    color: root.healthModel.errorCount > 0 ? Theme.dangerSurface : Theme.surface
                    border.color: root.healthModel.errorCount > 0 ? Theme.danger : Theme.accent
                    border.width: 1
                    radius: Theme.radius

                    Text {
                        anchors.centerIn: parent
                        text: root.healthModel.overallLabelText
                        color: Theme.textStrong
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.panelFontSize
                        font.bold: true
                        textFormat: Text.PlainText
                    }
                }

                ShellButton {
                    label: root.healthModel.showIssuesOnly ? qsTr("Show All") : qsTr("Issues Only")
                    onActivated: root.healthModel.showIssuesOnly = !root.healthModel.showIssuesOnly
                }

                ShellButton {
                    label: root.healthModel.busy ? qsTr("Scanning...") : qsTr("Refresh")
                    enabled: !root.healthModel.busy
                    onActivated: root.healthModel.refresh()
                }

                ShellButton {
                    label: root.healthModel.systemRunning ? qsTr("Elevating...") : qsTr("Elevated scan")
                    enabled: !root.healthModel.busy
                    onActivated: root.healthModel.refreshElevated()
                }

                ShellButton {
                    label: qsTr("Close")
                    onActivated: root.healthModel.close()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.listSpacing * 2

                Repeater {
                    model: [
                        { "label": qsTr("Errors"), "status": "error", "color": Theme.danger },
                        { "label": qsTr("Warnings"), "status": "warn", "color": "#ebcb8b" },
                        { "label": qsTr("Restricted"), "status": "restricted", "color": "#b48ead" },
                        { "label": qsTr("Passing"), "status": "ok", "color": "#a3be8c" }
                    ]

                    Rectangle {
                        id: statusTile

                        required property var modelData

                        Layout.preferredWidth: 132
                        Layout.preferredHeight: 34
                        color: Theme.surface
                        border.color: statusTile.modelData.color
                        border.width: 1
                        radius: Theme.radius

                        Text {
                            anchors.centerIn: parent
                            text: qsTr("%1 %2").arg(statusTile.modelData.label).arg(
                                statusTile.modelData.status === "error" ? root.healthModel.errorCount
                                : statusTile.modelData.status === "warn" ? root.healthModel.warnCount
                                : statusTile.modelData.status === "restricted" ? root.healthModel.restrictedCount
                                : root.healthModel.okCount)
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.smallFontSize
                            font.bold: true
                            textFormat: Text.PlainText
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    visible: root.healthModel.repairMessage.length > 0
                    text: root.healthModel.repairMessage
                    color: root.healthModel.repairError.length > 0 ? Theme.danger : Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.smallFontSize
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignRight
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Theme.sectionSpacing

                Rectangle {
                    Layout.preferredWidth: 220
                    Layout.fillHeight: true
                    color: Theme.surface
                    border.color: Theme.border
                    border.width: 1
                    radius: Theme.radius

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: Theme.listSpacing

                        Repeater {
                            model: root.healthModel.categories

                            Rectangle {
                                id: categoryButton

                                required property var modelData
                                readonly property int issueCount: root.healthModel.categoryIssueCount(categoryButton.modelData.id)

                                Accessible.role: Accessible.Button
                                Accessible.name: categoryButton.modelData.label
                                Accessible.onPressAction: root.healthModel.selectedCategory = categoryButton.modelData.id
                                activeFocusOnTab: true

                                Layout.fillWidth: true
                                Layout.preferredHeight: 46
                                color: root.healthModel.selectedCategory === categoryButton.modelData.id ? Theme.surfaceHover : Theme.transparent
                                border.color: root.healthModel.selectedCategory === categoryButton.modelData.id ? Theme.accent : Theme.transparent
                                border.width: 1
                                radius: Theme.radius

                                Keys.onPressed: function(event) {
                                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                        root.healthModel.selectedCategory = categoryButton.modelData.id;
                                        event.accepted = true;
                                    }
                                }

                                HoverHandler {
                                    cursorShape: Qt.PointingHandCursor
                                }

                                TapHandler {
                                    acceptedButtons: Qt.LeftButton
                                    onTapped: root.healthModel.selectedCategory = categoryButton.modelData.id
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10

                                    Text {
                                        Layout.fillWidth: true
                                        Layout.minimumWidth: 0
                                        text: categoryButton.modelData.label
                                        color: Theme.textStrong
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.panelFontSize
                                        font.bold: root.healthModel.selectedCategory === categoryButton.modelData.id
                                        textFormat: Text.PlainText
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        visible: categoryButton.issueCount > 0
                                        text: categoryButton.issueCount
                                        color: Theme.danger
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.smallFontSize
                                        font.bold: true
                                        textFormat: Text.PlainText
                                    }
                                }
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Current boot only\nNo external network probes")
                            color: Theme.placeholder
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.tinyFontSize
                            textFormat: Text.PlainText
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                ListView {
                    id: healthList

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: Theme.listSpacing * 2
                    model: root.healthModel.visibleRows

                    delegate: HealthCheckCard {
                        id: healthCard

                        required property var modelData

                        width: ListView.view ? ListView.view.width : 0
                        rowData: healthCard.modelData
                        healthModel: root.healthModel
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: healthList.count === 0
                        text: root.healthModel.busy ? qsTr("Collecting system health...") : qsTr("No checks match this view")
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.bodyFontSize
                        textFormat: Text.PlainText
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            visible: root.healthModel.confirming
            color: "#99000000"
            z: 10

            Rectangle {
                anchors.centerIn: parent
                width: Math.min(620, parent.width - 80)
                height: 280
                color: Theme.bg
                border.color: Theme.danger
                border.width: 1
                radius: Theme.radius

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: Theme.sectionSpacing

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Confirm Repair")
                        color: Theme.textStrong
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.titleFontSize
                        font.bold: true
                        textFormat: Text.PlainText
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.healthModel.pendingRepair ? root.healthModel.pendingRepair.repairLabel : ""
                        color: Theme.textStrong
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.inputFontSize
                        font.bold: true
                        textFormat: Text.PlainText
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        text: root.healthModel.pendingRepair ? root.healthModel.repairImpact(root.healthModel.pendingRepair.repairId) : ""
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.bodyFontSize
                        textFormat: Text.PlainText
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.healthModel.pendingRepair && root.healthModel.pendingRepair.privilege === "system"
                            ? qsTr("Administrator authorization is required.")
                            : qsTr("This action affects only the current user session.")
                        color: root.healthModel.pendingRepair && root.healthModel.pendingRepair.privilege === "system" ? "#ebcb8b" : Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.smallFontSize
                        textFormat: Text.PlainText
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Item {
                            Layout.fillWidth: true
                        }

                        ShellButton {
                            label: qsTr("Cancel")
                            onActivated: root.healthModel.cancelRepair()
                        }

                        ShellButton {
                            label: qsTr("Run Repair")
                            danger: true
                            onActivated: root.healthModel.confirmRepair()
                        }
                    }
                }
            }
        }
    }
}
