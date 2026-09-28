import QtQuick
import "root:/"

// An icon. Separate from Label only so the font size defaults differ.
Text {
    color: Theme.fg
    font.family: Theme.font
    font.pixelSize: Theme.iconSize
    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
}
