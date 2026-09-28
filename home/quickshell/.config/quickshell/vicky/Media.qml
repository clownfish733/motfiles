pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Everything about a video that is not its name: how long it is, what it
// looks like, and how far into it you got.
//
// Durations and poster frames come from `bin/vids-probe` and are cached on
// disk under a key that folds in mtime and size, so the work is done once per
// file and a replaced file gets a new frame instead of a stale one. Positions
// come from mpv's own watch_later files, read by `bin/vids-resume` — mpv is
// already the thing that knows where you stopped, and a second opinion would
// only ever be a worse one.
//
// Probing is demand-driven: the picker asks for the rows near the cursor, not
// for the library. A thousand videos must not be a thousand ffmpeg runs.
Singleton {
    id: root

    readonly property string fieldSep: "\x1f"
    readonly property string recordSep: "\x1e"

    // path -> { duration: seconds, thumb: "/path.jpg" }
    // Replaced wholesale rather than mutated: QML cannot see into an object.
    property var info: ({})

    // path -> seconds
    property var positions: ({})

    // ── lookups ─────────────────────────────────────────────────────────
    function duration(path) {
        const i = root.info[path];
        return i ? i.duration : 0;
    }

    function thumb(path) {
        const i = root.info[path];
        return i && i.thumb !== "" ? "file://" + i.thumb : "";
    }

    function position(path) {
        if (!Config.resume) return 0;
        const at = root.positions[path] || 0;
        if (at <= 0) return 0;

        // A position in the last couple of percent is a film you sat through
        // the credits of, not one you are partway into.
        const total = root.duration(path);
        if (total > 0 && at / total >= Config.resumeDoneFraction) return 0;
        return at;
    }

    function fraction(path) {
        const total = root.duration(path);
        if (total <= 0) return 0;
        return Math.min(1, root.position(path) / total);
    }

    // 92 -> "1:32", 3750 -> "1:02:30"
    function clock(seconds) {
        if (!seconds || seconds <= 0) return "";
        const s = Math.round(seconds);
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const sec = s % 60;
        const pad = function (n) { return n < 10 ? "0" + n : String(n) };
        return h > 0 ? h + ":" + pad(m) + ":" + pad(sec) : m + ":" + pad(sec);
    }

    // ── probing ─────────────────────────────────────────────────────────
    // Paths asked for but not yet known. `asked` stops the same path being
    // queued again on every cursor move while its ffmpeg is still running.
    property var queue: []
    property var asked: ({})

    function request(paths) {
        if (!Config.thumbnails) return;

        const add = [];
        for (const p of paths) {
            if (!p || p === "") continue;
            if (root.info[p] !== undefined) continue;
            if (root.asked[p]) continue;
            root.asked[p] = true;
            add.push(p);
        }
        if (add.length === 0) return;

        root.queue = root.queue.concat(add);
        root.pump();
    }

    function pump() {
        if (prober.running || root.queue.length === 0) return;

        const batch = root.queue.slice(0, Config.thumbBatch);
        root.queue = root.queue.slice(Config.thumbBatch);

        prober.command = [Config.probeScript, Config.thumbDir,
                          String(Config.thumbWidth)].concat(batch);
        prober.running = true;
    }

    Process {
        id: prober
        stdout: StdioCollector { onStreamFinished: root.ingestProbe(text) }
        onExited: root.pump()
    }

    function ingestProbe(text) {
        const next = ({});
        for (const key in root.info) next[key] = root.info[key];

        for (const record of text.split(root.recordSep)) {
            if (record === "") continue;
            const f = record.split(root.fieldSep);
            if (f.length < 3) continue;
            next[f[0]] = { duration: parseFloat(f[1]) || 0, thumb: f[2] };
        }
        root.info = next;
    }

    // ── positions ───────────────────────────────────────────────────────
    function refreshPositions() {
        if (!Config.resume) return;
        if (!resumer.running) resumer.running = true;
    }

    Process {
        id: resumer
        command: [Config.resumeScript, Config.watchLaterDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const next = ({});
                for (const record of text.split(root.recordSep)) {
                    if (record === "") continue;
                    const f = record.split(root.fieldSep);
                    if (f.length < 2) continue;
                    next[f[0]] = parseFloat(f[1]) || 0;
                }
                root.positions = next;
            }
        }
    }

    // Throwing away what we thought we knew is the only honest response to a
    // rescan: the files may not be the files any more.
    function invalidate() {
        root.info = ({});
        root.asked = ({});
        root.queue = [];
        root.refreshPositions();
    }

    Component.onCompleted: root.refreshPositions()
}
