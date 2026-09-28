import QtQuick
import "root:/"

// A list you drive from the keyboard. It owns the selection index; the window
// above it owns the keys, so the picker can shadow a binding if it needs to.
//
// `items` is a plain array rather than a model alias because the list is
// rebuilt wholesale every time a scan lands. `keyFor` lets the cursor stay on
// the row you were looking at across those rebuilds instead of sliding onto
// whatever happens to occupy that index next — which is exactly what happens
// while a playlist is downloading underneath you.
Item {
    id: root

    property var items: []
    property var keyFor: null       // function (item) -> string
    property alias delegate: view.delegate
    property alias count: view.count
    property int maxHeight: Theme.listMaxHeight
    property int index: 0
    property string emptyText: "nothing here"
    property string emptyHint: ""

    signal activated(int index)

    // The card grows and shrinks with the list rather than reserving a fixed
    // slab of screen, so a library of three videos gets a card the size of
    // three videos.
    implicitHeight: root.items.length === 0
        ? placeholder.implicitHeight + 24
        : Math.min(view.contentHeight, root.maxHeight)

    // Row identity of the current selection, remembered across rebuilds.
    property string currentKey: ""

    readonly property var current:
        (index >= 0 && index < items.length) ? items[index] : null

    function keyAt(i) {
        if (!keyFor || i < 0 || i >= items.length) return "";
        return String(keyFor(items[i]));
    }

    onIndexChanged: root.currentKey = keyAt(root.index)

    onItemsChanged: {
        if (root.currentKey !== "") {
            for (let i = 0; i < items.length; i++) {
                if (keyAt(i) === root.currentKey) {
                    root.index = i;
                    return;
                }
            }
        }
        root.index = Math.max(0, Math.min(items.length - 1, root.index));
        root.currentKey = keyAt(root.index);
    }

    // Movement wraps, because a list you can fall off the end of makes you
    // look at where the cursor went instead of at the list.
    function move(delta) {
        if (!items.length) return;
        const n = items.length;
        root.index = ((root.index + delta) % n + n) % n;
        view.positionViewAtIndex(root.index, ListView.Contain);
    }

    function next() { root.move(1) }
    function prev() { root.move(-1) }

    // Half a screen, the way vim measures it.
    function page(sign) {
        const rows = Math.max(1, Math.floor(view.height / Theme.rowHeight / 2));
        root.move(sign * rows);
    }

    function first() { if (items.length) { root.index = 0; view.positionViewAtBeginning() } }
    function last() { if (items.length) { root.index = items.length - 1; view.positionViewAtEnd() } }
    function activate() { if (items.length) root.activated(root.index) }

    ListView {
        id: view
        anchors.fill: parent
        model: root.items
        clip: true
        currentIndex: root.index
        boundsBehavior: Flickable.StopAtBounds
        // The cursor is drawn by the delegate, so the built-in one would just
        // be a second highlight lagging a frame behind it.
        highlight: null
    }

    Column {
        id: placeholder
        anchors.centerIn: parent
        // Bounded rather than free: the empty text is sometimes a path, and
        // a path is exactly the kind of string that walks out of the card.
        width: Math.max(0, parent.width - 20)
        spacing: 6
        visible: root.items.length === 0

        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideMiddle
            text: root.emptyText
            color: Theme.fgFaint
        }

        Label {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            visible: root.emptyHint !== ""
            text: root.emptyHint
            color: Theme.fgFaint
            font.pixelSize: Theme.smallSize
        }
    }
}
