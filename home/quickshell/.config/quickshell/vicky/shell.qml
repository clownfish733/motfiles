import Quickshell
import Quickshell.Io

// vids — a keyboard video picker for ~/Videos.
//
// Entry point only. The picker is the whole program: `qs -c vids` opens it,
// q closes the process, and picking something hands off to mpv and exits. It
// is not a resident panel, so there is nothing running between the moment you
// choose a video and the next time you want one.
//
// Bind it in hyprland.conf. The pkill makes the binding a toggle and stops a
// second press stacking a second copy on top of the first:
//
//   bind = SUPER, V, exec, pkill -f 'quickshell -c vids' || qs -c vids
ShellRoot {
    Picker {}

    // ── ipc ─────────────────────────────────────────────────────────────
    // Only useful while it is already open — mostly so a running download
    // can be watched or stopped from a terminal without stealing the
    // keyboard back from whatever has it.
    //   qs -c vids ipc call library rescan
    //   qs -c vids ipc call download add https://... 
    IpcHandler {
        target: "library"

        function rescan(): void { Library.rescan() }
        function root(): string { return Config.videoRoot }
        function playlists(): int { return Library.playlists.length }
        function videos(): int { return Library.videoCount }
    }

    IpcHandler {
        target: "download"

        function add(url: string): bool {
            return Downloads.add(url, Config.videoRoot, false);
        }

        function into(url: string, playlist: string): bool {
            return Downloads.add(url, Config.videoRoot + "/" + playlist, true);
        }

        function cancel(): void { Downloads.cancel() }
        function active(): bool { return Downloads.active }
        function status(): string {
            if (!Downloads.active) return "idle";
            return Math.round(Downloads.fraction * 100) + "% " + Downloads.title;
        }
    }
}
