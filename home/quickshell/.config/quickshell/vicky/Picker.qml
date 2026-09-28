import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.I3
import "root:/"
import "root:/components"

// The picker: one card, one list, no mouse required.
//
// It is a spawn-per-use window rather than a resident panel — `qs -c vids`
// opens it and q closes the process — so there is no visible/hidden state to
// keep, and nothing of it is running while you are watching the video it
// chose.
//
// Modes:
//   normal   j/k/gg/G/^d/^u move, ⏎ or l opens, h goes back up
//   search   / filters the current level; ⏎ keeps it, Esc clears it
//   url      a paste it hands to yt-dlp, aimed at wherever you are standing
//   confirm  y/n over a trash
PanelWindow {
    id: root

    // ── where the cursor is in the library ──────────────────────────────
    // "" is the root; anything else is a playlist folder name. There is no
    // third value, because there is no third level.
    property string where: ""

    property string mode: "normal"
    property string query: ""
    property var victim: null
    property bool pendingG: false
    property string notice: ""

    readonly property bool inPlaylist: where !== ""

    // The folder a download aimed at "here" should land in.
    readonly property string here:
        root.inPlaylist ? Config.videoRoot + "/" + root.where : Config.videoRoot

    // ── rows ────────────────────────────────────────────────────────────
    readonly property var rows: {
        const all = Library.entries(root.where);
        const q = root.query.trim().toLowerCase();
        if (q === "") return all;
        return all.filter(function (e) {
            return e.name.toLowerCase().indexOf(q) >= 0;
        });
    }

    // ── window ──────────────────────────────────────────────────────────
    // Pinned to the monitor with the keyboard on it, not to every monitor:
    // two copies of a modal picker fighting over the keyboard is worse than
    // the picker being on the wrong screen, and this is never the wrong one.
    readonly property var focusedScreen: {
        const name = I3.focusedMonitor ? I3.focusedMonitor.name : "";
        for (const s of Quickshell.screens)
            if (s.name === name) return s;
        return null;
    }

    screen: focusedScreen
    color: "transparent"
    anchors { top: true; left: true; right: true; bottom: true }
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "vids"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // ── actions ─────────────────────────────────────────────────────────
    // Leaving is just leaving. Downloads are their own detached processes now
    // and carry on without a window to report into, so there is nothing to
    // warn about on the way out.
    function quit() { Qt.quit() }

    function selected() { return list.current }

    function open(entry) {
        if (!entry) return;
        if (entry.kind === "playlist") {
            root.where = entry.name;
            root.query = "";
            list.currentKey = "";
            list.index = 0;
            return;
        }
        root.play([entry.path], {});
    }

    function up() {
        if (!root.inPlaylist) return;
        const leaving = root.where;
        root.where = "";
        root.query = "";
        // Come back out onto the folder you were just inside rather than the
        // top of the list.
        list.currentKey = "playlist:" + leaving;
    }

    function play(paths, opts) {
        if (!paths || paths.length === 0) {
            root.notice = "nothing to play";
            return;
        }
        Player.launch(paths, opts);
        if (Config.quitOnPlay) root.quit();
    }

    // p and s act on what the cursor is pointing at: a playlist row plays the
    // whole folder, anything else plays the level you are looking at, which
    // inside a playlist is that playlist.
    function playScope(opts) {
        const sel = root.selected();
        if (sel && sel.kind === "playlist") {
            root.play(Library.files(sel.name), opts);
            return;
        }
        root.play(root.rows
            .filter(function (e) { return e.kind === "video" })
            .map(function (e) { return e.path }), opts);
    }

    // ── thumbnails ──────────────────────────────────────────────────────
    // Only the rows around the cursor, never the library. A playlist borrows
    // the frame of its first video, so it is asked for too.
    function requestThumbs() {
        if (!Config.thumbnails) return;

        const from = Math.max(0, list.index - Config.thumbBehind);
        const to = Math.min(root.rows.length, list.index + Config.thumbLookahead);

        const want = [];
        for (let i = from; i < to; i++) {
            const e = root.rows[i];
            if (!e) continue;
            if (e.kind === "video") {
                want.push(e.path);
            } else {
                const first = Library.files(e.name)[0];
                if (first) want.push(first);
            }
        }
        Media.request(want);
    }

    onRowsChanged: root.requestThumbs()

    Connections {
        target: list
        function onIndexChanged() { root.requestThumbs() }
    }

    // mpv resumes on its own, so starting over needs a key of its own.
    function restart() {
        const sel = root.selected();
        if (!sel) return;
        if (sel.kind === "playlist") root.play(Library.files(sel.name), { restart: true });
        else root.play([sel.path], { restart: true });
    }

    function askUrl() {
        root.mode = "url";
        root.notice = "";
        // The url is nearly always already on the clipboard, so the prompt
        // opens with it pre-filled and selected: ⏎ takes it, typing replaces
        // it.
        const clip = Quickshell.clipboardText || "";
        field.text = /^https?:\/\//.test(clip) ? clip : "";
        field.forceActiveFocus();
        field.selectAll();
    }

    function submitUrl(url) {
        if (String(url).trim() === "") return;
        // Inside a playlist the output template is flattened, so a playlist
        // url pasted there fills the folder you are in instead of nesting a
        // folder inside it.
        Downloads.add(url, root.here, root.inPlaylist);
        root.notice = "queued";
    }

    function search() {
        root.mode = "search";
        field.text = root.query;
        field.forceActiveFocus();
    }

    function normal() {
        // The field has to be told to let go before the scope is asked to
        // take over. forceActiveFocus() on a FocusScope that already holds
        // active focus is a no-op — it re-delivers to whichever child the
        // scope is pointing at, which is still the field.
        field.focus = false;
        root.mode = "normal";
        root.victim = null;
        keys.forceActiveFocus();
    }

    function askDelete() {
        const sel = root.selected();
        if (!sel || trash.running) return;
        root.victim = sel;
        root.mode = "confirm";
    }

    function confirmDelete() {
        if (!root.victim) return;
        const path = root.victim.path;
        const name = root.victim.name;
        root.normal();

        trash.command = Config.useTrash
            ? ["gio", "trash", "--", path]
            : ["rm", "-rf", "--", path];
        trash.running = true;
        root.notice = (Config.useTrash ? "trashed " : "removed ") + name;
    }

    Process {
        id: trash
        onExited: function (code) {
            if (code !== 0) root.notice = "delete failed";
            Library.rescan();
        }
    }

    // ── keys ────────────────────────────────────────────────────────────
    Timer {
        id: gTimer
        interval: 600
        onTriggered: root.pendingG = false
    }

    function handleKey(e) {
        const ctrl = (e.modifiers & Qt.ControlModifier) !== 0;
        const t = e.text;
        e.accepted = true;

        if (root.mode === "confirm") {
            if (t === "y" || t === "Y") root.confirmDelete();
            else root.normal();
            return;
        }

        if (e.key === Qt.Key_Escape) {
            // Esc peels one layer at a time: filter, then folder, then out.
            if (root.query !== "") { root.query = ""; field.text = ""; }
            else if (root.inPlaylist) root.up();
            else root.quit();
            root.pendingG = false;
            return;
        }

        // gg needs a pending state; every other key cancels it.
        if (t === "g" && !ctrl) {
            if (root.pendingG) {
                root.pendingG = false;
                gTimer.stop();
                list.first();
            } else {
                root.pendingG = true;
                gTimer.restart();
            }
            return;
        }
        root.pendingG = false;
        gTimer.stop();

        if (ctrl && e.key === Qt.Key_D) { list.page(1); return; }
        if (ctrl && e.key === Qt.Key_U) { list.page(-1); return; }
        if (ctrl && e.key === Qt.Key_N) { list.next(); return; }
        if (ctrl && e.key === Qt.Key_P) { list.prev(); return; }
        if (ctrl) return;

        switch (e.key) {
        case Qt.Key_Down:  list.next(); return;
        case Qt.Key_Up:    list.prev(); return;
        case Qt.Key_Right: root.open(root.selected()); return;
        case Qt.Key_Left:
        case Qt.Key_Backspace: root.up(); return;
        case Qt.Key_Return:
        case Qt.Key_Enter: root.open(root.selected()); return;
        }

        switch (t) {
        case "j": list.next(); return;
        case "k": list.prev(); return;
        case "l": root.open(root.selected()); return;
        case "h": root.up(); return;
        case "G": list.last(); return;
        case "/": root.search(); return;
        case "p": root.playScope({}); return;
        case "s": root.playScope({ shuffle: true }); return;
        case "R": root.restart(); return;
        case "a": root.askUrl(); return;
        case "D": root.askDelete(); return;
        case "q": root.quit(); return;
        case "x":
            // One key for "make that stop": a running download, or the
            // wreckage of one that already did.
            if (Downloads.active) { Downloads.cancel(); root.notice = "cancelled" }
            else if (Downloads.failure !== "") { Downloads.dismissFailures() }
            return;
        case "r":
            // A deliberate rescan is the one that also throws away what the
            // picker thought each file looked like.
            root.notice = "";
            Media.invalidate();
            Library.rescan();
            root.requestThumbs();
            return;
        }
    }

    function handleFieldKey(e) {
        const ctrl = (e.modifiers & Qt.ControlModifier) !== 0;
        e.accepted = true;

        if (e.key === Qt.Key_Escape) {
            // Leaving the search box throws the filter away with it; leaving
            // the url box just abandons the paste.
            if (root.mode === "search") { root.query = ""; field.text = ""; }
            root.normal();
            return;
        }

        if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
            if (root.mode === "url") {
                const v = field.text;
                root.normal();
                root.submitUrl(v);
            } else {
                // Keep the filter, drop the box — the filtered list is now
                // just the list, and j/k drive it again.
                root.normal();
            }
            return;
        }

        // Move the cursor without leaving the search box.
        if (root.mode === "search") {
            if (e.key === Qt.Key_Down || (ctrl && e.key === Qt.Key_N)) { list.next(); return; }
            if (e.key === Qt.Key_Up || (ctrl && e.key === Qt.Key_P)) { list.prev(); return; }
        }

        if (ctrl && e.key === Qt.Key_W) {   // vim-ish: rub out the last word
            field.text = field.text.replace(/[^\s\/]*[\s\/]*$/, "");
            return;
        }
        if (ctrl && e.key === Qt.Key_U) { field.text = ""; return; }

        e.accepted = false;   // let the TextInput type it
    }

    // ── hints ───────────────────────────────────────────────────────────
    // Only the bindings you could not guess. j/k, ⏎ and q/Esc are never
    // advertised.
    readonly property var hints: {
        if (root.mode === "confirm") return [["y", "trash"], ["n", "keep"]];
        if (root.mode === "url") return [["⏎", "download"], ["esc", "cancel"]];
        if (root.mode === "search") return [["⏎", "keep filter"], ["esc", "clear"]];

        const sel = root.selected();
        const h = [];
        // Nothing to play, nothing to filter and nothing to trash when the
        // list is empty — all that is left to offer is the way to fill it.
        if (sel) {
            h.push(["p", sel.kind === "playlist" ? "play folder" : "play all"]);
            h.push(["s", "shuffle"]);
            // Only worth advertising on something you could actually be
            // partway through.
            if (Media.position(sel.path) > 0) h.push(["R", "restart"]);
            h.push(["/", "filter"]);
        }
        h.push(["a", "download"]);
        if (root.inPlaylist) h.push(["h", "back"]);
        if (sel) h.push(["D", "trash"]);
        if (Downloads.active) h.push(["x", "cancel"]);
        else if (Downloads.failure !== "") h.push(["x", "dismiss"]);
        return h;
    }

    // What the progress line says while yt-dlp is working.
    readonly property string downloadText: {
        const parts = [];
        if (Downloads.total > 1)
            parts.push(Downloads.index + "/" + Downloads.total);
        if (Downloads.title !== "") parts.push(Downloads.title);
        // Before yt-dlp has resolved the url there is no title and no
        // percentage, and the stage is the only thing worth saying.
        if (Downloads.fraction >= 0)
            parts.push(Math.round(Downloads.fraction * 100) + "%");
        else if (Downloads.phase !== "") parts.push(Downloads.phase);
        if (Downloads.speed !== "") parts.push(Downloads.speed);
        if (Downloads.eta !== "") parts.push("eta " + Downloads.eta);
        if (Downloads.pending > 0) parts.push("+" + Downloads.pending + " queued");
        return parts.join("  ·  ");
    }

    // ── chrome ──────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Theme.scrim
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.quit()
    }

    FocusScope {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: function (e) { root.handleKey(e) }

        Rectangle {
            id: card

            property real shift: 0

            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(Theme.cardWidth, parent.width - 32)

            // Sized by what is in it, the way the shell's menus are, so an
            // empty library gets a card the size of one line of apology.
            implicitHeight: column.implicitHeight + Theme.cardPadding * 2
            height: Math.min(implicitHeight, parent.height - 32)
            y: (parent.height - height) / 2 + shift

            radius: Theme.cardRadius
            color: Theme.bg
            border.width: Theme.border
            border.color: Theme.outline
            clip: true

            Behavior on height {
                NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic }
            }

            // Swallow clicks so they never reach the dismiss layer.
            MouseArea { anchors.fill: parent }

            Column {
                id: column
                anchors.fill: parent
                anchors.margins: Theme.cardPadding
                spacing: 6

                // ── header ──────────────────────────────────────────────
                Item {
                    width: parent.width
                    height: 22

                    Glyph {
                        id: headIcon
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.inPlaylist ? Icons.folder : Icons.film
                        color: Theme.accent
                    }

                    Label {
                        anchors.left: headIcon.right
                        anchors.leftMargin: 8
                        anchors.right: status.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.inPlaylist ? "video / " + root.where : "video"
                        color: Theme.fgDim
                        font.pixelSize: Theme.smallSize
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 1.2
                        elide: Text.ElideMiddle
                    }

                    Label {
                        id: status
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: Theme.smallSize
                        color: Library.scanning ? Theme.fgFaint : Theme.fgDim
                        text: {
                            if (Library.scanning) return "scanning…";
                            if (root.query !== "")
                                return root.rows.length + "/"
                                     + Library.entries(root.where).length;
                            if (root.inPlaylist)
                                return root.plural(root.rows.length, "video") + " · "
                                     + Library.fmtBytes(root.folderBytes);
                            return root.plural(Library.playlists.length, "playlist")
                                 + " · " + Library.loose.length + " loose";
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.accentSoft
                }

                // ── search / url line ───────────────────────────────────
                Rectangle {
                    id: entryBox
                    width: parent.width
                    visible: root.mode === "search" || root.mode === "url"
                    height: 28

                    // The invariant behind the line in normal(): an input
                    // nobody can see must never be the thing the keyboard is
                    // talking to. Without this, any other route out of a
                    // prompt leaves every binding dead and the keystrokes
                    // going into a hidden text box.
                    onVisibleChanged: if (!visible) field.focus = false
                    radius: Theme.rowRadius
                    color: "transparent"
                    border.width: Theme.border
                    border.color: root.mode === "url" ? Theme.warn : Theme.outline
                    clip: true

                    Glyph {
                        id: sigil
                        anchors.left: parent.left
                        anchors.leftMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.mode === "url" ? Icons.link : Icons.search
                        color: root.mode === "url" ? Theme.warn : Theme.accent
                        font.pixelSize: Theme.textSize
                    }

                    TextInput {
                        id: field
                        anchors {
                            left: sigil.right; leftMargin: 8
                            right: parent.right; rightMargin: 10
                            verticalCenter: parent.verticalCenter
                        }
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.textSize
                        selectByMouse: true
                        selectionColor: Theme.accentSoft
                        clip: true

                        onTextChanged: if (root.mode === "search") root.query = text
                        Keys.onPressed: function (e) { root.handleFieldKey(e) }

                        Label {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            visible: field.text.length === 0
                            color: Theme.fgFaint
                            text: root.mode === "url"
                                ? "paste a video or playlist url"
                                : "filter"
                        }

                        // Block cursor, because of course.
                        Rectangle {
                            x: field.cursorRectangle.x
                            y: field.cursorRectangle.y
                            width: 7
                            height: field.cursorRectangle.height
                            color: Theme.fg
                            opacity: 0.55
                            visible: field.activeFocus
                        }
                    }
                }

                // ── list ────────────────────────────────────────────────
                VimList {
                    id: list

                    width: parent.width
                    height: implicitHeight
                    maxHeight: Math.max(Theme.rowHeight * 3,
                                        Theme.listMaxHeight)

                    items: root.rows
                    keyFor: function (e) { return e.kind + ":" + e.name }

                    emptyText: {
                        if (Library.scanning) return "scanning…";
                        if (root.query !== "") return "no match";
                        if (root.inPlaylist) return "empty playlist";
                        return "nothing in " + root.tilde(Config.videoRoot);
                    }
                    emptyHint: root.query === "" && !Library.scanning
                        ? "press a to download something" : ""

                    onActivated: function (i) { root.open(list.items[i]) }

                    delegate: EntryRow {
                        required property var modelData
                        required property int index

                        // A playlist has no frame of its own, so it wears its
                        // first video's.
                        readonly property string subject: modelData.kind === "playlist"
                            ? (Library.files(modelData.name)[0] || "")
                            : modelData.path

                        selected: index === list.index
                        playlist: modelData.kind === "playlist"
                        label: modelData.name
                        thumb: subject === "" ? "" : Media.thumb(subject)
                        fallbackIcon: modelData.kind === "playlist" ? Icons.folder : Icons.video
                        watched: modelData.kind === "playlist" ? 0 : Media.fraction(modelData.path)

                        detail: {
                            if (modelData.kind === "playlist")
                                return modelData.count + " · " + Library.fmtBytes(modelData.bytes);

                            const total = Media.duration(modelData.path);
                            const at = Media.position(modelData.path);
                            if (at > 0 && total > 0)
                                return Media.clock(at) + " / " + Media.clock(total);
                            if (total > 0) return Media.clock(total);
                            // Nothing probed it yet — the size is the only
                            // true thing there is to say about it.
                            return Library.fmtBytes(modelData.bytes);
                        }

                        onClicked: {
                            list.index = index;
                            root.open(modelData);
                        }
                    }
                }

                // ── status line ─────────────────────────────────────────
                // One line that says what the picker is doing or waiting on.
                // Only one thing is ever true at once, so they share the row
                // rather than stacking.
                Item {
                    id: statusLine
                    width: parent.width
                    height: 30
                    visible: text !== ""

                    // A notice outranks the progress it covers: it is always
                    // the more recent thing to have happened, it is gone in
                    // three seconds, and one of the things it says is the
                    // warning about the download it is sitting on top of.
                    readonly property string text: {
                        if (root.mode === "confirm")
                            return "trash " + (root.victim ? root.victim.name : "") + "?";
                        if (root.notice !== "") return root.notice;
                        if (Downloads.failure !== "") return Downloads.failure;
                        if (Library.error !== "") return Library.error;
                        if (Downloads.active) return root.downloadText;
                        return "";
                    }

                    readonly property color tint: {
                        if (root.mode === "confirm") return Theme.warn;
                        if (root.notice !== "") return Theme.fgDim;
                        if (Downloads.failure !== "" || Library.error !== "") return Theme.crit;
                        if (Downloads.active) return Theme.fg;
                        return Theme.fgDim;
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.rowRadius
                        color: Theme.accentFaint
                        border.width: Theme.border
                        border.color: statusLine.tint
                    }

                    // The progress fill sits under the text rather than beside
                    // it, so a long title never squeezes the bar to nothing.
                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        anchors.margins: 1
                        width: Downloads.active && Downloads.fraction > 0
                            ? (parent.width - 2) * Math.min(1, Downloads.fraction)
                            : 0
                        radius: Theme.rowRadius - 1
                        color: Theme.accentSoft
                        visible: width > 0
                        Behavior on width { NumberAnimation { duration: Theme.anim } }
                    }

                    Glyph {
                        id: statusIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: Theme.textSize
                        color: statusLine.tint
                        text: {
                            if (root.mode === "confirm") return Icons.trash;
                            if (root.notice !== "") return Icons.check;
                            if (Downloads.failure !== "" || Library.error !== "")
                                return Icons.alert;
                            if (Downloads.active) return Icons.download;
                            return Icons.check;
                        }
                    }

                    Label {
                        anchors {
                            left: statusIcon.right; leftMargin: 8
                            right: parent.right; rightMargin: 10
                            verticalCenter: parent.verticalCenter
                        }
                        text: statusLine.text
                        color: statusLine.tint
                        font.pixelSize: Theme.smallSize
                        elide: Text.ElideRight
                    }
                }

                // ── hints ───────────────────────────────────────────────
                Item {
                    width: parent.width
                    height: 16

                    Row {
                        anchors.centerIn: parent
                        spacing: 12

                        Repeater {
                            model: root.hints
                            delegate: Row {
                                required property var modelData
                                spacing: 4

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: cap.implicitWidth + 8
                                    height: 14
                                    radius: 3
                                    color: Theme.accentFaint
                                    border.width: Theme.border
                                    border.color: Theme.outline

                                    Label {
                                        id: cap
                                        anchors.centerIn: parent
                                        text: modelData[0]
                                        font.pixelSize: Theme.smallSize
                                    }
                                }

                                Label {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData[1]
                                    color: Theme.fgDim
                                    font.pixelSize: Theme.smallSize
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function plural(n, word) { return n + " " + word + (n === 1 ? "" : "s") }

    // $HOME is the one prefix everybody reads as "~".
    function tilde(path) {
        const home = Quickshell.env("HOME") || "";
        return (home !== "" && path.startsWith(home))
            ? "~" + path.slice(home.length)
            : path;
    }

    // Total size of the playlist being looked at, for the header.
    readonly property int folderBytes: {
        const pl = Library.playlist(root.where);
        return pl ? pl.bytes : 0;
    }

    // A notice is a receipt, not a state — it goes away on its own so it
    // cannot be mistaken for something still happening.
    onNoticeChanged: if (notice !== "") noticeTimer.restart()

    Timer {
        id: noticeTimer
        interval: 3000
        onTriggered: root.notice = ""
    }

    // Entry animation, borrowed from the shell's menus so the picker arrives
    // the same way they do.
    Component.onCompleted: {
        keys.forceActiveFocus();
        entry.start();
    }

    ParallelAnimation {
        id: entry
        NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: Theme.anim }
        NumberAnimation {
            target: card; property: "shift"; from: -10; to: 0
            duration: 190; easing.type: Easing.OutCubic
        }
    }
}
