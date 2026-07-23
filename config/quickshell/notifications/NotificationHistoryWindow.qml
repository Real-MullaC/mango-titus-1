import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core

pragma ComponentBehavior: Bound

FloatingWindow {
    id: root

    required property var notificationModel

    title: "dwm notification history"
    visible: notificationModel.historyVisible
    implicitWidth: 520
    implicitHeight: 560
    color: Theme.transparent

    onVisibleChanged: {
        if (!visible) {
            root.notificationModel.closeHistory();
        }
    }

    ShellSurface {
        anchors.fill: parent
        margin: 16

        ColumnLayout {
            anchors.fill: parent
            spacing: Theme.popupSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.listSpacing * 2

                Text {
                    Layout.fillWidth: true
                    text: "Notifications"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.titleFontSize
                    font.bold: true
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                }

                ShellButton {
                    Layout.preferredWidth: 58
                    Layout.preferredHeight: Theme.buttonHeight
                    label: "Clear"
                    onActivated: root.notificationModel.clearHistory()
                }

                ShellButton {
                    Layout.preferredWidth: Theme.closeButtonSize
                    Layout.preferredHeight: Theme.closeButtonSize
                    label: "x"
                    onActivated: root.notificationModel.closeHistory()
                }
            }

            ListView {
                id: historyList

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: Theme.listSpacing * 2
                model: root.notificationModel.history

                delegate: Rectangle {
                    id: historyEntry

                    required property var modelData

                    width: ListView.view ? ListView.view.width : 0
                    height: Math.max(74, historyContent.implicitHeight + 22)
                    radius: Theme.radius
                    color: historyEntry.modelData.urgencyName === "critical" ? Theme.dangerSurface : Theme.surface
                    border.color: historyEntry.modelData.urgencyName === "critical" ? Theme.danger : Theme.border
                    border.width: 1

                    ColumnLayout {
                        id: historyContent

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 11
                        spacing: Theme.tightSpacing

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.listSpacing * 2

                            Text {
                                Layout.fillWidth: true
                                text: historyEntry.modelData.appName || "Notification"
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.smallFontSize
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                            }

                            Text {
                                text: Qt.formatTime(new Date(historyEntry.modelData.timestamp || Date.now()), "hh:mm")
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.smallFontSize
                                textFormat: Text.PlainText
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: historyEntry.modelData.summary || historyEntry.modelData.urgencyName || ""
                            color: Theme.textStrong
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.bodyFontSize
                            font.bold: true
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: text.length > 0
                            text: historyEntry.modelData.body || ""
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.smallFontSize
                            textFormat: Text.PlainText
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: historyList.count === 0
                    text: "No notifications"
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.smallFontSize
                    textFormat: Text.PlainText
                }
            }
        }
    }
}
