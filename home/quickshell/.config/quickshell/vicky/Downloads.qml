pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// The downloads, which are not ours.
//
// yt-dlp used to be a child of this process, which meant closing the picker
// killed it. It is now `bin/vids-dl`, started detached and left to get on
// with it: it queues itself against every other job with a lock, writes its
// progress into a one-line file per job, and posts a desktop notification
// when it finishes. This singleton only reads those files.
//
// So there is no owning, no lifetime and no queue to keep here — a job
// started by a picker you closed an hour ago shows up in this list the next
// time you open one, at whatever percentage it has reached.
Singleton {
    id: root

    readonly property string fieldSep: "\x1f"

    // [{ status, url, title, percent, speed, eta, index, total, phase, error, pgid }]
    property var jobs: []

    readonly property var current: jobs.length > 0 ? jobs[0] : null
    readonly property bool active: jobs.some(function (j) {
        return j.status === "running" || j.status === "queued";
    })
    readonly property int pending: Math.max(0, jobs.length - 1)

    readonly property var failed: jobs.filter(function (j) { return j.status === "failed" })

    // ── what the status line reads ──────────────────────────────────────
    readonly property real fraction: {
        if (!current || current.percent === "") return -1;
        const p = parseFloat(current.percent);
        return isNaN(p) ? -1 : p / 100;
    }
    readonly property string title: current ? current.title : ""
    readonly property string speed: current ? current.speed : ""
    readonly property string eta: current ? current.eta : ""
    readonly property string phase: current ? current.phase : ""
    readonly property int index: current ? (parseInt(current.index, 10) || 0) : 0
    readonly property int total: current ? (parseInt(current.total, 10) || 0) : 0

    readonly property string failure: failed.length > 0 ? failed[0].error : ""

    // ── starting one ────────────────────────────────────────────────────
    // setsid puts the job in its own session and process group, which is what
    // lets it outlive this process and be cancelled later as a single signal.
    function add(url, dest, flat) {
        const trimmed = String(url).trim();
        if (trimmed === "") return false;

        Quickshell.execDetached(
            ["setsid", Config.dlScript, "add", trimmed,
             "-P", dest,
             "-o", flat ? Config.outputTemplateFlat : Config.outputTemplate]
            .concat(Config.ytdlpArgs));

        // The job file will not exist for a few milliseconds yet; poll early
        // so the row appears while the keypress still feels connected to it.
        poll.restart();
        soon.restart();
        return true;
    }

    function cancel() {
        Quickshell.execDetached([Config.dlScript, "cancel"]);
        soon.restart();
    }

    // Clearing a failure is just deleting its job file — the process behind
    // it is long gone.
    function dismissFailures() {
        if (root.failed.length === 0) return;
        // `clear` and not `cancel`: waving away an error must never be able
        // to stop a download that is still running.
        Quickshell.execDetached([Config.dlScript, "clear"]);
        soon.restart();
    }

    // ── reading them ────────────────────────────────────────────────────
    function refresh() { if (!reader.running) reader.running = true }

    Process {
        id: reader
        command: ["sh", "-c", 'cat "$1"/* 2>/dev/null || true', "sh", Config.jobsDir]
        stdout: StdioCollector { onStreamFinished: root.ingest(text) }
    }

    function ingest(text) {
        const out = [];
        for (const line of text.split("\n")) {
            if (line === "") continue;
            const job = ({ status: "", url: "", title: "", percent: "", speed: "",
                           eta: "", index: "", total: "", phase: "", error: "",
                           pgid: "" });
            for (const field of line.split(root.fieldSep)) {
                const eq = field.indexOf("=");
                if (eq <= 0) continue;
                const key = field.slice(0, eq);
                if (key in job) job[key] = field.slice(eq + 1);
            }
            if (job.status !== "") out.push(job);
        }

        // Running first, then queued, then failures, so the head of the list
        // is always the thing actually happening.
        const rank = ({ running: 0, queued: 1, failed: 2 });
        out.sort(function (a, b) {
            return (rank[a.status] === undefined ? 3 : rank[a.status])
                 - (rank[b.status] === undefined ? 3 : rank[b.status]);
        });

        const wasActive = root.active;
        root.jobs = out;

        // A job that has left the list has finished — its own notification
        // has already fired, but the library needs to learn about the file.
        if (wasActive && !root.active) Library.rescan();
    }

    // Polls only while there is something to poll for. The downloads run
    // whether or not anything is watching; this paces the display, not them.
    Timer {
        id: poll
        interval: Config.jobPoll
        running: root.active
        repeat: true
        onTriggered: root.refresh()
    }

    // A one-shot to close the gap between asking for something and the job
    // file that proves it appearing.
    Timer {
        id: soon
        interval: 250
        repeat: false
        onTriggered: root.refresh()
    }

    // Finished files only appear once yt-dlp renames them off .part, so a
    // long playlist would otherwise sit still until the very end.
    Timer {
        interval: Config.downloadRescanInterval
        running: root.active
        repeat: true
        onTriggered: Library.rescan()
    }

    Component.onCompleted: root.refresh()
}
