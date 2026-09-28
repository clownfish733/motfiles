pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// The whole library in one shot.
//
// The model is deliberately two levels deep and no more: a loose file in the
// root is a video, a folder in the root is a playlist, and the files inside
// that folder are its items. Anything below that is not addressable, so one
// `find -maxdepth 2` sees the entire world and there is never a second scan
// to fire when you walk into a playlist.
Singleton {
    id: root

    readonly property string dir: Config.videoRoot

    property bool scanning: false
    // Set when find could not read the root at all — an unmounted drive
    // rather than an empty folder, which the empty list cannot express.
    property string error: ""

    // [{ name, path, items: [file], bytes, mtime }]
    property var playlists: []
    // [{ name, path, bytes, mtime }] — loose files in the root.
    property var loose: []

    readonly property int videoCount: {
        let n = loose.length;
        for (const p of playlists) n += p.items.length;
        return n;
    }

    signal rescanned()

    // ── record separators ───────────────────────────────────────────────
    // find -printf writes them as octal escapes; they are the two ASCII
    // separators that cannot appear in a filename, which is what lets the
    // parse survive names containing tabs, quotes and newlines.
    readonly property string fieldSep: "\x1f"
    readonly property string recordSep: "\x1e"

    function isVideo(name) {
        const dot = name.lastIndexOf(".");
        if (dot <= 0) return false;
        return Config.extensions.indexOf(name.slice(dot + 1).toLowerCase()) >= 0;
    }

    // "ep2" before "ep10". Written out rather than handed to localeCompare
    // with { numeric: true }, because Qt's JavaScript engine accepts that
    // option and then ignores it — which sorts an entire season wrong while
    // looking exactly like code that works.
    //
    // Names are chopped into runs of digits and runs of everything else, and
    // the runs are compared pairwise: digits numerically, the rest as text.
    function natural(a, b) {
        const chunks = /\d+|\D+/g;
        const x = String(a).toLowerCase().match(chunks) || [];
        const y = String(b).toLowerCase().match(chunks) || [];

        const n = Math.min(x.length, y.length);
        for (let i = 0; i < n; i++) {
            const p = x[i];
            const q = y[i];
            const pNum = p.charCodeAt(0) >= 48 && p.charCodeAt(0) <= 57;
            const qNum = q.charCodeAt(0) >= 48 && q.charCodeAt(0) <= 57;

            if (pNum && qNum) {
                const d = parseInt(p, 10) - parseInt(q, 10);
                if (d !== 0) return d;
                // "01" and "1" are the same number but not the same name, so
                // the padding breaks the tie rather than leaving it to
                // whichever order find happened to walk them in.
                if (p.length !== q.length) return p.length - q.length;
            } else if (p !== q) {
                return p < q ? -1 : 1;
            }
        }
        return x.length - y.length;
    }

    function fmtBytes(n) {
        if (!n || n < 0) return "";
        const units = ["B", "K", "M", "G", "T"];
        let i = 0;
        let v = n;
        while (v >= 1024 && i < units.length - 1) { v /= 1024; i++; }
        return (v >= 10 || i === 0 ? Math.round(v) : v.toFixed(1)) + units[i];
    }

    // ── scanning ────────────────────────────────────────────────────────
    function rescan() {
        if (scanProc.running) return;
        root.scanning = true;
        scanProc.running = true;
    }

    // The root is created rather than reported missing: a picker that opens
    // onto "no such directory" the first time it runs is just a chore.
    Process {
        id: mkProc
        running: true
        command: ["sh", "-c", 'mkdir -p "$1"', "sh", root.dir]
        onExited: root.rescan()
    }

    Process {
        id: scanProc

        command: [
            "find", "-L", root.dir, "-mindepth", "1", "-maxdepth", "2",
            "-printf", "%y" + root.fieldSep + "%p" + root.fieldSep + "%f"
                     + root.fieldSep + "%s" + root.fieldSep + "%T@" + root.recordSep
        ]

        stderr: StdioCollector {
            onStreamFinished: root.error = text.trim().split("\n")[0] || ""
        }

        stdout: StdioCollector {
            onStreamFinished: root.ingest(text)
        }

        onExited: root.scanning = false
    }

    function ingest(text) {
        const prefix = root.dir + "/";
        const folders = ({});   // name -> playlist record
        const order = [];       // folder names, in discovery order
        const files = [];       // loose root files
        const orphans = [];     // depth-2 files seen before their folder

        for (const record of text.split(root.recordSep)) {
            if (record === "") continue;
            const f = record.split(root.fieldSep);
            if (f.length < 5) continue;

            const type = f[0];
            const path = f[1];
            const name = f[2];
            const bytes = parseInt(f[3], 10) || 0;
            const mtime = parseFloat(f[4]) || 0;

            if (!path.startsWith(prefix)) continue;
            const rel = path.slice(prefix.length);
            const slash = rel.indexOf("/");

            if (slash < 0) {
                // Depth 1.
                if (type === "d") {
                    folders[name] = { name: name, path: path, items: [],
                                      bytes: 0, mtime: mtime };
                    order.push(name);
                } else if (type === "f" && root.isVideo(name)) {
                    files.push({ name: name, path: path, bytes: bytes, mtime: mtime });
                }
            } else if (type === "f" && root.isVideo(name)) {
                // Depth 2 — an item of the folder named by the first segment.
                orphans.push({ parent: rel.slice(0, slash), name: name,
                               path: path, bytes: bytes, mtime: mtime });
            }
        }

        // find walks a directory's children before it has necessarily
        // reported every sibling, so items are attached in a second pass.
        for (const item of orphans) {
            const pl = folders[item.parent];
            if (!pl) continue;
            pl.items.push(item);
            pl.bytes += item.bytes;
        }

        const lists = [];
        for (const name of order) {
            const pl = folders[name];
            if (Config.hideEmptyPlaylists && pl.items.length === 0) continue;
            pl.items.sort(function (a, b) { return root.natural(a.name, b.name) });
            lists.push(pl);
        }
        lists.sort(function (a, b) { return root.natural(a.name, b.name) });
        files.sort(function (a, b) { return root.natural(a.name, b.name) });

        root.playlists = lists;
        root.loose = files;

        // Where mpv left off can have changed since the last look — you have
        // just come back from watching something — but what a video looks
        // like and how long it is cannot have, so the probe cache survives an
        // automatic rescan and only a deliberate one throws it away.
        Media.refreshPositions();

        root.rescanned();
    }

    // ── views ───────────────────────────────────────────────────────────
    // `where` is "" for the root or a playlist name. Rows carry a `kind` so
    // the delegate and the key handlers never have to guess.
    function entries(where) {
        if (where === "") {
            const out = [];
            for (const pl of root.playlists)
                out.push({ kind: "playlist", name: pl.name, path: pl.path,
                           count: pl.items.length, bytes: pl.bytes });
            for (const v of root.loose)
                out.push({ kind: "video", name: v.name, path: v.path,
                           count: 0, bytes: v.bytes });
            return out;
        }

        const pl = root.playlist(where);
        if (!pl) return [];
        return pl.items.map(function (v) {
            return { kind: "video", name: v.name, path: v.path,
                     count: 0, bytes: v.bytes };
        });
    }

    function playlist(name) {
        for (const pl of root.playlists)
            if (pl.name === name) return pl;
        return null;
    }

    // Every playable file under `where`, in the order the list shows them.
    function files(where) {
        return root.entries(where)
            .filter(function (e) { return e.kind === "video" })
            .map(function (e) { return e.path });
    }
}
