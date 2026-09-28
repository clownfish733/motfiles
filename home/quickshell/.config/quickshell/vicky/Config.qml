pragma Singleton

import Quickshell
import QtQuick

// Every behavioural knob. Change these, not the module bodies.
Singleton {
    id: root

    // ── library ─────────────────────────────────────────────────────────
    // One folder, two kinds of thing in it: loose video files, and folders
    // of video files. The scan stops at depth 2 on purpose — a playlist is
    // a flat folder, and anything nested deeper is not part of the model.
    // $VIDS_ROOT overrides it, which is how you point a second copy at a
    // different library without editing this file.
    readonly property string videoRoot: {
        const override = Quickshell.env("VIDS_ROOT");
        return (override && override !== "") ? override
                                             : Quickshell.env("HOME") + "/Videos";
    }

    // Lowercase, no dot. Anything else in the folder is invisible to the
    // picker, which is what keeps yt-dlp's .part and .ytdl scratch files out
    // of the list while a download is running.
    readonly property var extensions: [
        "mp4", "mkv", "webm", "avi", "mov", "m4v", "flv",
        "wmv", "mpg", "mpeg", "ts", "m2ts", "ogv", "3gp"
    ]

    // A folder with no playable file in it is somebody's notes directory,
    // not a playlist, so it stays out of the list. A folder that is being
    // downloaded into appears the moment its first file finishes.
    readonly property bool hideEmptyPlaylists: true

    // ── state and cache ─────────────────────────────────────────────────
    // Downloads outlive the picker, so their state cannot live inside it.
    // Thumbnails are derived data and belong in the cache, where deleting
    // them costs a regenerate and nothing else.
    readonly property string stateDir:
        (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
        + "/vids"
    readonly property string cacheDir:
        (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache"))
        + "/vids"

    readonly property string jobsDir: stateDir + "/jobs"
    readonly property string thumbDir: cacheDir + "/thumbs"

    readonly property string dlScript: Quickshell.shellPath("bin/vids-dl")
    readonly property string probeScript: Quickshell.shellPath("bin/vids-probe")
    readonly property string resumeScript: Quickshell.shellPath("bin/vids-resume")

    // ── thumbnails ──────────────────────────────────────────────────────
    // Generated at 2x the size they are drawn, so they stay sharp on a
    // scaled monitor, and only for the rows near the cursor — a library of a
    // thousand videos must not become a thousand ffmpeg invocations.
    readonly property bool thumbnails: true
    readonly property int thumbWidth: Theme.thumbWidth * 2
    readonly property int thumbLookahead: 16
    readonly property int thumbBehind: 4
    readonly property int thumbBatch: 24

    // ── resume ──────────────────────────────────────────────────────────
    // mpv keeps the positions; the picker only reads them. Turning this off
    // stops both the reading and the saving.
    readonly property bool resume: true
    readonly property string watchLaterDir:
        (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
        + "/mpv/watch_later"

    // A video this close to the end is finished, not paused. mpv itself
    // deletes the entry at EOF, but quitting during the credits leaves one
    // behind that would otherwise show as a nearly-full bar forever.
    readonly property real resumeDoneFraction: 0.98

    // ── playback ────────────────────────────────────────────────────────
    // --force-window matters for audio-only files that slipped in: without
    // it mpv plays them with no window and there is nothing to close.
    readonly property var player: ["mpv", "--force-window=yes"]

    // Launching a video is the end of the picker's job.
    readonly property bool quitOnPlay: true

    // ── downloads ───────────────────────────────────────────────────────
    // Playlists land in a folder named after the playlist; single videos land
    // loose at the top level. `%(playlist_title|.)s` is what does it — the
    // fallback is "." rather than "" because an empty first path component
    // would make the template absolute and silently discard -P.
    readonly property string outputTemplate:
        "%(playlist_title|.)s/%(playlist_index&{:03d} - |)s%(title)s.%(ext)s"

    // Inside a playlist folder the nesting has to stop, so whatever is
    // pasted is flattened into the folder you are already looking at.
    readonly property string outputTemplateFlat:
        "%(playlist_index&{:03d} - |)s%(title)s.%(ext)s"

    // ── cookies ─────────────────────────────────────────────────────────
    // YouTube refuses anonymous downloads from most addresses now — "Sign in
    // to confirm you're not a bot" — and no choice of player client gets
    // around it once an address is flagged. Cookies from a logged-in browser
    // are the documented way through, and yt-dlp locates Firefox's profile by
    // itself, including this machine's non-default ~/.config/mozilla one.
    //
    // Worth knowing: YouTube rotates these, and reading them out of a browser
    // that is still using them can occasionally log that browser out of
    // YouTube. If that becomes a nuisance, log in once in a second Firefox
    // profile, never browse in it, and point this at that profile by name —
    // "firefox:downloads" — or set it to "" to go back to anonymous.
    readonly property string cookiesFrom: ""

    readonly property var ytdlpArgs: {
        const args = ytdlpBaseArgs.slice();
        if (root.cookiesFrom !== "") {
            args.push("--cookies-from-browser");
            args.push(root.cookiesFrom);
        }
        return args;
    }

    readonly property var ytdlpBaseArgs: [
        "--no-warnings",
        "--newline",
        "--no-colors",
        "--progress",
        "--concurrent-fragments", "4",
        "--merge-output-format", "mkv",
        // Keeps a half-finished download resumable across a cancel.
        "--continue"
    ]

    // yt-dlp is happy to spend an hour on a 200-video playlist; the picker
    // only ever runs one job so the queue stays comprehensible.
    readonly property int downloadRescanInterval: 4000

    // How often the picker re-reads the job files while any are live. The
    // downloads run whether or not anything is watching, so this only paces
    // the display.
    readonly property int jobPoll: 600

    // ── deletion ────────────────────────────────────────────────────────
    // gio trash is reversible and rm is not, so the picker only ever trashes.
    // Set to false and D becomes rm -rf, which is your problem.
    readonly property bool useTrash: true
}
