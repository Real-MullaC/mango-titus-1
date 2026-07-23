import QtQuick
import QtQuick.Layouts
import qs.core

pragma ComponentBehavior: Bound

Flickable {
    id: root

    required property LauncherModel launcherModel

    contentWidth: launcherCategoryRow.width
    contentHeight: height
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    RowLayout {
        id: launcherCategoryRow

        height: parent ? parent.height : Theme.chipHeight
        spacing: Theme.listSpacing + Theme.compactSpacing

        Repeater {
            model: root.launcherModel.categories

            delegate: Rectangle {
                id: categoryDelegate

                required property var modelData

                readonly property bool selected: root.launcherModel.category === categoryDelegate.modelData.id
                readonly property bool hovered: categoryHover.hovered

                Accessible.role: Accessible.Button
                Accessible.name: categoryDelegate.modelData.label
                Accessible.onPressAction: root.launcherModel.setCategory(categoryDelegate.modelData.id)
                activeFocusOnTab: true

                Layout.preferredHeight: Theme.chipHeight
                Layout.preferredWidth: launcherCategoryLabel.implicitWidth + 22
                radius: Theme.radius
                color: categoryDelegate.selected ? Theme.accent
                    : categoryDelegate.hovered ? Theme.surfaceHover : Theme.surface

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        root.launcherModel.setCategory(categoryDelegate.modelData.id);
                        event.accepted = true;
                    }
                }

                HoverHandler {
                    id: categoryHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    gesturePolicy: TapHandler.WithinBounds
                    onTapped: root.launcherModel.setCategory(categoryDelegate.modelData.id)
                }

                Text {
                    id: launcherCategoryLabel

                    anchors.centerIn: parent
                    text: qsTr("%1 %2").arg(categoryDelegate.modelData.label).arg(categoryDelegate.modelData.count)
                    color: categoryDelegate.selected ? Theme.accentText : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.smallFontSize
                    font.bold: categoryDelegate.selected
                    textFormat: Text.PlainText
                }
            }
        }
    }
}
