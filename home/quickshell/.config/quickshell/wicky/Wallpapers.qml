pragma Singleton

import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel

// The wallpaper directory, and the one command that changes anything.
//
// awww is already the thing painting the desktop, so this singleton does not
// try to own wallpaper state: it asks awww what is on screen (`query`) and
// tells it what to put there (`img`). Nothing is cached to disk, which means
// a wallpaper set from anywhere else is still the one highlighted on open.
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/Pictures/Wallpapers"

    // Absolute path awww reports as currently displayed, "" until `query`
    // answers. Used only to pick the initial selection.
    property string current: ""
    // `current` is only meaningful once the query has come back; until then ""
    // means "not asked yet" rather than "no wallpaper set".
    property bool queried: false

    readonly property alias model: folder
    readonly property int count: folder.count

    // Case folding is left to `caseSensitive`, so .JPG needs no second filter.
    FolderListModel {
        id: folder
        folder: "file://" + root.dir
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.bmp"]
        caseSensitive: false
        showDirs: false
        showHidden: false
        sortField: FolderListModel.Name
    }

    function pathAt(i) {
        if (i < 0 || i >= folder.count)
            return "";
        return String(folder.get(i, "filePath"));
    }

    // -1 when the path is not in the directory (or nothing is known yet), so
    // callers can fall back to the first entry.
    function indexOf(path) {
        if (path === "")
            return -1;
        for (let i = 0; i < folder.count; i++)
            if (root.pathAt(i) === path)
                return i;
        return -1;
    }

    // ── apply ───────────────────────────────────────────────────────────
    // Detached, not a Process: the picker quits milliseconds after choosing,
    // and quickshell reaps its children on the way out — an awww still
    // negotiating the transition would be killed before it drew anything.
    function apply(path) {
        if (path === "")
            return;
        Quickshell.execDetached([
            "awww", "img", path,
            "--resize", "crop",
            "--filter", "Lanczos3",
            "--transition-type", "fade",
            "--transition-duration", "0.6",
            "--transition-fps", "60"
        ]);
        root.current = path;
    }

    // ── query ───────────────────────────────────────────────────────────
    // One line per output: "... currently displaying: image: /path/to/file".
    // Every output shows the same wallpaper here, so the first match wins.
    Process {
        id: queryProc
        // A literal rather than a binding, so it fires once at load and is not
        // re-armed when the process exits. Quickshell singletons get no
        // Component.onCompleted, so this is the whole of the init.
        running: true
        command: ["awww", "query"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/image:\s*(\S.*?)\s*$/m);
                root.current = m ? m[1] : "";
                root.queried = true;
            }
        }
        // Covers awww being absent or refusing to answer: the picker waits on
        // `queried`, so it must flip either way or the strip never seeds.
        onExited: root.queried = true
    }

    function refresh() { queryProc.running = true }
}
