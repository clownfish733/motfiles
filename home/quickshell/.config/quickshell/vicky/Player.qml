pragma Singleton

import Quickshell
import QtQuick

// mpv, detached. The picker is a chooser, not a frontend — once mpv has the
// files it owns the session, and nothing here waits on it.
Singleton {
    id: root

    property string lastPlayed: ""

    // opts: { shuffle: bool, restart: bool }
    function launch(paths, opts) {
        if (!paths || paths.length === 0) return false;
        const o = opts || ({});

        const cmd = Config.player.slice();

        // mpv is the thing that knows where you stopped, so it is the thing
        // asked to remember. --write-filename-in-watch-later-config is what
        // puts the path inside the saved file, which is the only reason the
        // picker can map one back to a video without reimplementing mpv's
        // hashing.
        if (Config.resume) {
            cmd.push("--save-position-on-quit");
            cmd.push("--write-filename-in-watch-later-config");
        }

        if (o.shuffle) cmd.push("--shuffle");
        // Starting over is a flag rather than a deleted state file, so the
        // position survives if you change your mind and quit early again.
        if (o.restart) cmd.push("--no-resume-playback");

        // Everything after this is a filename, so a video called `--version`
        // is a video and not an argument.
        cmd.push("--");
        for (const p of paths) cmd.push(p);

        Quickshell.execDetached(cmd);
        root.lastPlayed = paths[0];
        return true;
    }
}
