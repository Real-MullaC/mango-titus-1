import QtQuick
import QtQuick.Layouts
import qs.core

Text {
    id: root

    required property string label

    Layout.fillWidth: true
    text: label
    color: Theme.textMuted
    font.family: Theme.fontFamily
    font.pixelSize: Theme.smallFontSize
    font.bold: true
    textFormat: Text.PlainText
    elide: Text.ElideRight
}
