import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.core

pragma ComponentBehavior: Bound

FloatingWindow {
    id: root

    required property var launcherModel

    title: "dwm launcher"
    visible: launcherModel.visible
    implicitWidth: 760
    implicitHeight: 560
    color: Theme.transparent

    function focusSearch() {
        if (!root.visible || !launcherSearch) {
            return;
        }
        launcherSearch.forceActiveFocus();
        launcherSearch.cursorPosition = launcherSearch.text.length;
    }

    function syncSearchFromModel() {
        if (launcherSearch.text !== root.launcherModel.query) {
            launcherSearch.text = root.launcherModel.query;
        }
    }

    onVisibleChanged: {
        if (visible) {
            root.syncSearchFromModel();
            Qt.callLater(root.focusSearch);
        } else {
            root.launcherModel.close();
        }
    }

    Connections {
        target: root.launcherModel

        function onQueryChanged() {
            root.syncSearchFromModel();
        }
    }

    ShellSurface {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            spacing: Theme.popupSpacing

            Text {
                text: "Applications"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.titleFontSize
                font.bold: true
                verticalAlignment: Text.AlignVCenter
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                color: Theme.surface
                radius: Theme.radius

                TextInput {
                    id: launcherSearch

                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.textStrong
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.accentText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.inputFontSize
                    clip: true

                    onTextEdited: root.launcherModel.setQuery(text)

                    Keys.onPressed: function(event) {
                        const ctrl = event.modifiers & Qt.ControlModifier;

                        if (event.key === Qt.Key_Down || (event.key === Qt.Key_N && ctrl)) {
                            root.launcherModel.selectRelative(1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up || (event.key === Qt.Key_P && ctrl)) {
                            root.launcherModel.selectRelative(-1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_PageDown) {
                            root.launcherModel.selectRelative(8);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_PageUp) {
                            root.launcherModel.selectRelative(-8);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Home) {
                            root.launcherModel.selectAbsolute(0);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_End) {
                            root.launcherModel.selectAbsolute(root.launcherModel.filteredApps.length - 1);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.launcherModel.launchSelectedApp();
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Escape || (event.key === Qt.Key_C && ctrl)) {
                            root.launcherModel.close();
                            event.accepted = true;
                        }
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    visible: launcherSearch.text.length === 0
                    text: "Search applications"
                    color: Theme.placeholder
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.inputFontSize
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.launcherModel.filteredApps.length + " shown / " + root.launcherModel.status
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.smallFontSize
                elide: Text.ElideRight
            }

            LauncherCategoryRow {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                launcherModel: root.launcherModel
            }

            ListView {
                id: launcherResults

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: Theme.listSpacing
                model: root.launcherModel.filteredApps

                onModelChanged: {
                    if (root.launcherModel.filteredApps.length > 0) {
                        positionViewAtIndex(root.launcherModel.selectedIndex, ListView.Contain);
                    }
                }

                Connections {
                    target: root.launcherModel

                    function onSelectedIndexChanged() {
                        if (root.launcherModel.filteredApps.length > 0) {
                            launcherResults.positionViewAtIndex(root.launcherModel.selectedIndex, ListView.Contain);
                        }
                    }
                }

                delegate: LauncherResultDelegate {
                    width: ListView.view ? ListView.view.width : 0
                    selected: index === root.launcherModel.selectedIndex
                    launcherModel: root.launcherModel
                }
            }
        }
    }
}
