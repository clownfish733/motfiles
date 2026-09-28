import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "root:/"

// A horizontal strip of wallpaper previews, and nothing else.
//
// The window is a fullscreen transparent overlay with no plate, no scrim and
// no labels: the previews are the entire interface. The previews themselves
// are opaque, so selection is carried by scale and by how lit a preview is,
// plus a hairline ring on the focused one.
//
//   h / l   previous / next          ⏎   set the wallpaper and quit
//   g / G   first / last             Esc q   quit without setting
PanelWindow {
    id: root

    // Held open by the animation for one beat after the choice is made, so the
    // strip can retract instead of blinking out.
    property bool open: false

    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:wallpaper-picker"
    WlrLayershell.keyboardFocus: root.open
        ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // ── selection seeding ───────────────────────────────────────────────
    // The directory listing and awww's query both land asynchronously, so the
    // strip opens on whatever is already on the desktop only once both are in.
    // Seeding runs exactly once; after that the user owns the selection.
    property bool seeded: false

    function seed() {
        if (root.seeded || Wallpapers.count === 0 || !Wallpapers.queried)
            return;
        const i = Wallpapers.indexOf(Wallpapers.current);
        // Set before `open`, so the strip snaps to the seeded preview instead
        // of scrolling to it from the first wallpaper as it fades in.
        strip.at = i >= 0 ? i : 0;
        root.seeded = true;
        root.open = true;
    }

    Connections {
        target: Wallpapers
        function onCountChanged() { root.seed() }
        function onQueriedChanged() { root.seed() }
    }

    // An empty directory has no picker to show, so there is nothing to wait
    // for and nothing to dismiss.
    Connections {
        target: Wallpapers.model
        function onStatusChanged() {
            if (Wallpapers.model.status === FolderListModel.Ready && Wallpapers.count === 0)
                Qt.quit();
        }
    }

    Component.onCompleted: root.seed()

    // ── leaving ─────────────────────────────────────────────────────────
    // Both exits are one-shot. Dismissing releases the keyboard, which lets a
    // stray pointer event reach the backdrop and ask to dismiss a second time;
    // ungated, that restarts the quit timer and can apply a wallpaper twice.
    property bool leaving: false

    function choose() {
        if (root.leaving)
            return;
        if (strip.currentIndex >= 0)
            Wallpapers.apply(Wallpapers.pathAt(strip.currentIndex));
        root.dismiss();
    }

    function dismiss() {
        if (root.leaving)
            return;
        root.leaving = true;
        root.open = false;
        quitTimer.start();
    }

    // The retract animation is the only reason the process is still alive.
    Timer {
        id: quitTimer
        interval: Theme.closeAnim
        onTriggered: Qt.quit()
    }

    // Click anywhere the previews are not.
    MouseArea {
        anchors.fill: parent
        onClicked: root.dismiss()
    }

    FocusScope {
        id: keys
        anchors.fill: parent
        focus: true

        Keys.onPressed: (e) => {
            e.accepted = true;
            const t = e.text;

            switch (true) {
            case e.key === Qt.Key_Escape || (t === "q" && !(e.modifiers & Qt.ControlModifier)):
                root.dismiss(); break;
            case e.key === Qt.Key_Return || e.key === Qt.Key_Enter:
                root.choose(); break;
            case t === "l" || e.key === Qt.Key_Right:
                strip.step(1); break;
            case t === "h" || e.key === Qt.Key_Left:
                strip.step(-1); break;
            case t === "g":
                strip.goTo(0); break;
            case t === "G":
                strip.goTo(Wallpapers.count - 1); break;
            default:
                e.accepted = false;
            }
        }

        // ── the strip ───────────────────────────────────────────────────
        // A fixed ring of slots, not a ListView. The list is circular, so
        // there are no ends to scroll to and nothing for a Flickable to bound
        // against: what moves is `at`, and the slots stay put and re-point at
        // whatever wallpaper is now theirs.
        Item {
            id: strip

            // Where the strip is pointed, in wallpapers. Deliberately
            // unbounded — it runs negative and past the end, and only wraps
            // when it is used to index — so l off the last wallpaper carries
            // straight on to the first with no rewind.
            property int at: 0
            // What is actually drawn: chases `at` so a step slides rather than
            // cuts. Fractional in flight, which is what makes the scale and
            // fade falloff continuous.
            property real shown: at
            onAtChanged: strip.shown = strip.at

            // Disabled until the strip is up, so seeding snaps.
            Behavior on shown {
                enabled: root.open
                NumberAnimation { duration: Theme.scroll; easing.type: Easing.OutCubic }
            }

            // Slots either side of centre. One more than is visible, so the
            // preview entering at each edge is already loaded and fading in
            // rather than appearing from nothing.
            readonly property int reach: (Theme.visible - 1) / 2 + 1
            readonly property int slots: strip.reach * 2 + 1
            readonly property real pitch: Theme.cellWidth + Theme.gap

            readonly property int currentIndex:
                Wallpapers.count > 0 ? strip.wrap(strip.at, Wallpapers.count) : -1

            function wrap(i, n) { return ((i % n) + n) % n }
            function step(n) { if (Wallpapers.count > 0) strip.at += n }
            // Relative, so the strip travels to the wallpaper rather than
            // teleporting `at` somewhere unrelated to where it is now.
            function goTo(i) {
                if (Wallpapers.count > 0)
                    strip.at += i - strip.currentIndex;
            }

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            // Room for the focused preview at full size plus its lift.
            height: Theme.cellHeight + 24

            // Opening: the strip fades up and settles down a few pixels.
            opacity: root.open ? 1 : 0
            transform: Translate { y: root.open ? 0 : 14 }
            Behavior on opacity {
                NumberAnimation {
                    duration: root.open ? Theme.openAnim : Theme.closeAnim
                    easing.type: root.open ? Easing.OutCubic : Easing.InCubic
                }
            }

            Repeater {
                model: strip.slots

                delegate: Item {
                    id: slot

                    required property int index

                    // The window of wallpapers on screen, as a half-open run of
                    // `slots` consecutive positions centred on the strip.
                    readonly property int first: Math.round(strip.shown) - strip.reach
                    // This slot owns the one position in that run congruent to
                    // its own number. Stepping shifts the run by one, so
                    // exactly one slot is re-pointed per step — and it is the
                    // one wrapping from the far edge, which is off screen. Any
                    // mapping that re-points every slot would reload every
                    // preview on every keypress, in view.
                    readonly property int pos:
                        slot.first + strip.wrap(slot.index - slot.first, strip.slots)

                    // Distance from centre, in wallpapers.
                    readonly property real dist: Math.abs(slot.pos - strip.shown)
                    readonly property bool sel: slot.pos === strip.at

                    // How lit this preview is: 1 at centre, 0 at the edge of
                    // the window. A preview is opaque, so this is painted on
                    // as black rather than taken out of its alpha — one
                    // leaving the strip darkens out instead of dissolving
                    // into the desktop behind it. The second term is the edge
                    // fade, and it is what still keeps exactly
                    // `Theme.visible` previews on screen at rest: the spare
                    // slot sits at dist == reach, unlit and undrawn, until a
                    // step drags it inward.
                    readonly property real lit:
                        Math.max(0, 1 - slot.dist * Theme.fadeStep)
                        * Math.max(0, Math.min(1, strip.reach - slot.dist))

                    width: Theme.cellWidth
                    height: strip.height
                    x: strip.width / 2 - Theme.cellWidth / 2
                        + (slot.pos - strip.shown) * strip.pitch

                    Item {
                        id: art
                        anchors.centerIn: parent
                        width: Theme.cellWidth
                        height: Theme.cellHeight

                        // Driven off `dist` rather than animated per preview:
                        // one animation on `shown` moves everything, so the
                        // whole strip stays in step with itself.
                        scale: 1 - Math.min(slot.dist, strip.reach - 1) * Theme.scaleStep
                        // Fully dark is nothing to look at, and costs a
                        // composite either way — so an unlit preview is not
                        // drawn at all.
                        visible: slot.lit > 0

                        // A cheap two-layer lift: no blur, just an offset plate
                        // that reads as a shadow against any wallpaper.
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 3
                            y: 8
                            radius: Theme.radius
                            color: Theme.shadow
                            opacity: 0.5 * Math.max(0, 1 - slot.dist)
                        }

                        // Opaque ground: a wallpaper with an alpha channel
                        // of its own would otherwise show the desktop through
                        // its own preview.
                        ClippingRectangle {
                            anchors.fill: parent
                            radius: Theme.radius
                            color: Theme.previewBase

                            Image {
                                anchors.fill: parent
                                source: Wallpapers.count > 0
                                    ? "file://" + Wallpapers.pathAt(
                                        strip.wrap(slot.pos, Wallpapers.count))
                                    : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                // Decode a preview, not a 4K frame. Height
                                // follows the source aspect, so crop still has
                                // something to crop.
                                sourceSize.width: Theme.cellWidth * 2
                            }
                        }

                        // The falloff, as paint. Over the image and under
                        // the ring, so the accent stays true where it shows.
                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radius
                            color: Theme.previewBase
                            opacity: 1 - slot.lit
                        }

                        // The only chrome in the config. Fades with distance,
                        // so it is only ever really lit on the centre preview.
                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.radius
                            color: "transparent"
                            border.width: Theme.ringWidth
                            border.color: Theme.accent
                            opacity: Math.max(0, 1 - slot.dist * 1.6)
                        }

                        MouseArea {
                            anchors.fill: parent
                            // First click focuses, a click on the focused
                            // preview commits — so the mouse needs no separate
                            // confirm. Pointing `at` at this slot's own
                            // position keeps the travel short, even when the
                            // wrapped wallpaper is at the other end.
                            onClicked: slot.sel ? root.choose() : strip.at = slot.pos
                            enabled: slot.lit > 0.05
                        }
                    }
                }
            }
        }
    }
}
