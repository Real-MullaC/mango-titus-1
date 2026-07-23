import QtQuick
import QtQuick.Layouts
import qs.core

pragma ComponentBehavior: Bound

Flickable {
    id: root

    required property var launcherModel

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

                Layout.preferredHeight: Theme.chipHeight
                Layout.preferredWidth: launcherCategoryLabel.implicitWidth + 22
                radius: Theme.radius
                color: categoryDelegate.selected ? Theme.accent
                    : categoryDelegate.hovered ? Theme.surfaceHover : Theme.surface

                HoverHandler {
                    id: categoryHover
                }

                TapHandler {
                    acceptedButtons: Qt.LeftButton
                    gesturePolicy: TapHandler.WithinBounds
                    onTapped: root.launcherModel.setCategory(categoryDelegate.modelData.id)
                }

                Text {
                    id: launcherCategoryLabel

                    anchors.centerIn: parent
                    text: categoryDelegate.modelData.label + " " + categoryDelegate.modelData.count
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
