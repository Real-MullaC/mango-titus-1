import QtQuick
import QtQuick.Layouts
import qs.core

pragma ComponentBehavior: Bound

Rectangle {
    id: root

    required property var rowData
    required property SystemHealthModel healthModel

    readonly property bool expanded: healthModel.isExpanded(rowData.id)
    readonly property bool hasServiceActions: rowData.repairId.indexOf("manage-") === 0
    readonly property bool hasEvidenceActions: (rowData.id === "journal-errors" || rowData.id === "kernel-errors")
        && (rowData.status === "warn" || rowData.status === "error")
        && rowData.evidence.length > 0
    readonly property color statusColor: rowData.status === "error" ? Theme.danger
        : rowData.status === "warn" ? "#ebcb8b"
        : rowData.status === "restricted" ? "#b48ead"
        : rowData.status === "ok" ? "#a3be8c"
        : Theme.accent

    height: implicitHeight
    implicitHeight: cardColumn.implicitHeight + 24
    color: rowData.status === "error" ? Theme.dangerSurface : Theme.surface
    border.color: statusColor
    border.width: 1
    radius: Theme.radius

    ColumnLayout {
        id: cardColumn

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12
        spacing: Theme.rowSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.rowSpacing

            Rectangle {
                Layout.preferredWidth: 8
                Layout.preferredHeight: 8
                color: root.statusColor
                radius: 4
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: Theme.tightSpacing

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: root.rowData.title
                    color: Theme.textStrong
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelFontSize
                    font.bold: true
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: root.rowData.summary
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.smallFontSize
                    textFormat: Text.PlainText
                    elide: root.expanded ? Text.ElideNone : Text.ElideRight
                    wrapMode: root.expanded ? Text.WordWrap : Text.NoWrap
                }
            }

            Text {
                text: root.rowData.status.toUpperCase()
                color: root.statusColor
                font.family: Theme.fontFamily
                font.pixelSize: Theme.tinyFontSize
                font.bold: true
                textFormat: Text.PlainText
            }

            ShellButton {
                visible: root.rowData.evidence.length > 0
                    || root.hasServiceActions
                    || root.hasEvidenceActions
                    || (root.rowData.repairId.length > 0 && !root.hasServiceActions)
                label: root.expanded ? qsTr("Less") : qsTr("Details")
                onActivated: root.healthModel.toggleExpanded(root.rowData.id)
            }
        }

        Loader {
            Layout.fillWidth: true
            active: root.expanded
            sourceComponent: expandedBody
        }
    }

    Component {
        id: expandedBody

        ColumnLayout {
            width: root.width - 24
            spacing: Theme.rowSpacing

            Flow {
                Layout.fillWidth: true
                spacing: Theme.listSpacing
                visible: root.hasServiceActions || root.hasEvidenceActions

                Repeater {
                    model: root.hasServiceActions ? [
                        { "action": "start", "label": qsTr("Start") },
                        { "action": "stop", "label": qsTr("Stop") },
                        { "action": "restart", "label": qsTr("Restart") },
                        { "action": "disable", "label": qsTr("Disable") },
                        { "action": "enable", "label": qsTr("Enable") }
                    ] : []

                    ShellButton {
                        id: serviceButton

                        required property var modelData

                        label: serviceButton.modelData.label
                        enabled: !root.healthModel.busy
                        danger: root.rowData.privilege === "system"
                        onActivated: root.healthModel.requestServiceAction(
                            root.rowData,
                            serviceButton.modelData.action,
                            serviceButton.modelData.label
                        )
                    }
                }

                Repeater {
                    model: root.hasEvidenceActions ? [
                        { "action": "copy", "label": qsTr("Copy") },
                        { "action": "export", "label": qsTr("Export") }
                    ] : []

                    ShellButton {
                        id: evidenceButton

                        required property var modelData

                        label: evidenceButton.modelData.label
                        enabled: !root.healthModel.busy
                        onActivated: root.healthModel.shareEvidence(root.rowData, evidenceButton.modelData.action)
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.rowData.evidence.length > 0
                text: root.rowData.evidence
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.smallFontSize
                textFormat: Text.PlainText
                wrapMode: Text.WrapAnywhere
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.rowData.repairId.length > 0 && !root.hasServiceActions

                Item {
                    Layout.fillWidth: true
                }

                ShellButton {
                    label: root.rowData.repairLabel
                    enabled: !root.healthModel.busy
                    danger: root.rowData.privilege === "system"
                    onActivated: root.healthModel.requestRepair(root.rowData)
                }
            }
        }
    }
}
