import QtQuick
import "root:/"

// One line in the list: a poster frame, a name, and a number.
//
// `selected` is the vim cursor. The watched-so-far bar lives along the bottom
// of the thumbnail rather than under the name, which keeps the row one line
// tall and puts the progress where the eye already is.
Item {
    id: root

    property bool selected: false
    property bool playlist: false
    property string label: ""
    property string detail: ""
    property string thumb: ""       // "" while it is still being made
    property real watched: 0        // 0..1
    property string fallbackIcon: ""

    signal clicked()

    implicitHeight: Theme.rowHeight
    width: ListView.view ? ListView.view.width : implicitWidth

    Rectangle {
        anchors.fill: parent
        anchors.rightMargin: 1
        anchors.topMargin: 1
        anchors.bottomMargin: 1
        radius: Theme.rowRadius
        color: root.selected ? Theme.accentSoft
             : mouse.containsMouse ? Theme.accentFaint
             : "transparent"
        border.width: root.selected ? Theme.border : 0
        border.color: Theme.outline
    }

    // The cursor also gets a bar on the left, so selection survives being
    // read on a black background at a glance.
    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: parent.height - 18
        radius: 1
        color: Theme.outline
        visible: root.selected
    }

    // ── poster frame ────────────────────────────────────────────────────
    Rectangle {
        id: frame
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.thumbWidth
        height: Theme.thumbHeight
        radius: 3
        color: "#0b0b0b"
        border.width: Theme.border
        border.color: root.selected ? Theme.outline : Theme.accentFaint
        clip: true

        Image {
            id: poster
            anchors.fill: parent
            anchors.margins: 1
            source: root.thumb
            visible: root.thumb !== "" && status === Image.Ready
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            // Decoded at the size it is drawn, not at the size it was made.
            sourceSize.width: Theme.thumbWidth * 2
            sourceSize.height: Theme.thumbHeight * 2
        }

        // Whatever the row is before its frame exists — and what a folder
        // stays as when nothing inside it could be read.
        Text {
            anchors.centerIn: parent
            visible: !poster.visible
            text: root.fallbackIcon
            color: root.playlist ? Theme.accent : Theme.fgFaint
            font.family: Theme.font
            font.pixelSize: Theme.iconSize
            renderType: Text.NativeRendering
        }

        // How far in you got, along the bottom edge of the frame.
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 4
            color: "#b3000000"
            visible: root.watched > 0

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.max(2, parent.width * Math.min(1, root.watched))
                color: Theme.accentBright
            }
        }
    }

    Text {
        id: name
        anchors.left: frame.right
        anchors.leftMargin: 10
        anchors.right: detailText.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        elide: Text.ElideRight
        color: Theme.fg
        font.family: Theme.font
        font.pixelSize: Theme.textSize
        font.bold: root.playlist
        renderType: Text.NativeRendering
        verticalAlignment: Text.AlignVCenter
    }

    Text {
        id: detailText
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: root.detail
        color: root.watched > 0 ? Theme.accent : Theme.fgDim
        font.family: Theme.font
        font.pixelSize: Theme.smallSize
        renderType: Text.NativeRendering
        verticalAlignment: Text.AlignVCenter
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
