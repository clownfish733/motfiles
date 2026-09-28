# vids

A keyboard video picker for `~/Videos`, built on [Quickshell]. Same black-and-
`#993954` skin as `quicky`, same vim bindings, same list component.

The picker itself is spawn-per-use: `qs -c vids` opens it, `q` closes the
process, and choosing a video hands off to mpv and exits. Downloads are not —
they are detached, and outlive the window that started them.

## The model

Two levels, and no more:

```
~/Videos/
├── a loose video.mkv          ← a video
├── another one.mp4            ← a video
└── Some Playlist/             ← a playlist
    ├── 001 - first.mkv        ← its items
    └── 002 - second.mkv
```

A folder in the root is a playlist. A file in the root is a video. Files inside
a playlist folder are its items. Anything deeper is invisible, and a folder with
no playable file in it is somebody's notes directory rather than a playlist, so
it is not listed either.

## Keys

| | |
|---|---|
| `j` `k` `↓` `↑` `^n` `^p` | move |
| `^d` `^u` | half a screen |
| `gg` `G` | top, bottom |
| `⏎` `l` `→` | open — descend into a playlist, or play a video |
| `h` `←` `⌫` | back up to the root |
| `p` | play — the playlist under the cursor, or everything at this level |
| `s` | the same, shuffled |
| `R` | play from the beginning, ignoring the saved position |
| `/` | filter this level; `⏎` keeps the filter, `esc` clears it |
| `a` | download a url with yt-dlp (the clipboard is pre-filled) |
| `D` | trash the selection, `y` to confirm |
| `x` | cancel a running download, or dismiss a failed one |
| `r` | rescan, and re-read every thumbnail and duration |
| `q` `esc` | out — `esc` first clears a filter, then leaves a playlist |

## Downloads

`a` takes a video or playlist url and hands it to yt-dlp, aimed at wherever the
cursor is standing:

- **In the root** — a single video lands loose in `~/Videos`, and a playlist gets
  a folder named after itself, with its items numbered inside it.
- **Inside a playlist** — everything is flattened into that folder, so a playlist
  url pasted there fills the folder you are in rather than nesting a third level
  that the picker could not show you.

**The download is not the picker's child.** `bin/vids-dl` is started detached, in
its own session, and carries on with no window to report into — close the picker,
log out of the picker, open five more of them, the job keeps going. When it
finishes it says so with a desktop notification (which quicky is already the
server for), and a failure notifies too, at critical urgency.

### Cookies

YouTube refuses anonymous downloads from most addresses now — *"Sign in to
confirm you're not a bot"* — and no choice of `player_client` gets around it
once an address is flagged. `Config.cookiesFrom` is set to `"firefox"`, which
makes yt-dlp read cookies from the logged-in browser; it finds the profile on
its own, including this machine's non-default `~/.config/mozilla` one.

Two things follow from that. Resolving a url takes a few seconds longer, so the
status line sits on `resolving…` for a moment before the first percentage. And
YouTube rotates these cookies: reading them out of a browser that is still using
them can occasionally log that browser out of YouTube. If that becomes a
nuisance, log in once in a second Firefox profile, never browse in it, and point
`cookiesFrom` at it by name — `"firefox:downloads"`. Setting it to `""` goes back
to anonymous.

Progress lives in one file per job under `$XDG_STATE_HOME/vids/jobs`, written
off a yt-dlp `--progress-template` rather than scraped from its bar. Any picker
you open reads those files, so a job started an hour ago appears at whatever
percentage it has reached. Jobs queue against each other with a lock — one
download at a time across every picker that has ever run — and `x` stops the
lot. A finished job deletes its own file; a failed one is kept so the error is
still there to read, until `x` dismisses it.

## Thumbnails and durations

Every row carries a poster frame taken a fifth of the way into the file, and its
running time instead of its size. A playlist wears its first video's frame.

`Theme.thumbHeight` is the one number that sets how big a row is — the frame is
16:9 off it, the row is the frame plus air, and the cached image is generated at
twice the drawn width so it stays sharp. The generated width is part of the
cache key, so changing the size regenerates rather than silently reusing frames
made at the old one.

`bin/vids-probe` does this with `ffmpeg` and `ffprobe`, and caches both under
`$XDG_CACHE_HOME/vids/thumbs` against a key that folds in mtime and size — so
the work happens once per file, and a file that gets replaced gets a new frame
rather than keeping a stale one. Only the rows near the cursor are ever asked
for, so a library of a thousand videos is not a thousand ffmpeg runs. Deleting
the cache directory costs nothing but a regenerate.

## Resume

mpv is asked to remember where you stopped (`--save-position-on-quit`), and the
picker reads those positions back: a partly-watched video shows `12:34 / 45:02`
and a bar along the bottom of its poster frame. Pressing `⏎` resumes — that is
mpv's own doing — and `R` starts from the beginning instead.

The mapping back from mpv's saved state to a file comes from
`--write-filename-in-watch-later-config`, which writes the path into the file
itself, so there is no need to reimplement mpv's hashing. mpv deletes an entry
when a file plays to the end, and anything past `resumeDoneFraction` of the way
through is treated as finished rather than shown as a nearly-full bar forever.

## Install

Nothing to install: `mpv`, `yt-dlp`, `ffmpeg`, `notify-send`, `flock` and
`awk` are all it uses, and all of them are already here.

The config lives wherever you keep it, symlinked into Quickshell's config dir:

```sh
ln -s ~/Dev/video ~/.config/quickshell/vids
```

Bind it. `-n` makes a second press a no-op rather than a second copy; the `pkill`
form makes it a toggle instead:

```lua
-- ~/.config/hypr/keybinds.lua
hl.bind("SUPER + V", hl.dsp.exec_cmd("qs -c vids -n"))
-- or, to toggle:
hl.bind("SUPER + V", hl.dsp.exec_cmd("sh -c \"pkill -f 'quickshell -c vids' || qs -c vids\""))
```

Or add it to `apps.lua` alongside the others:

```lua
videomanager = "qs -c vids -n",
```

## Configuration

Everything behavioural is in `Config.qml` — the library root, which extensions
count as video, the mpv command, the yt-dlp flags and output templates, whether
`D` trashes or deletes, whether thumbnails and resume are on at all, and where
the state and cache live. The scripts in `bin/` take every yt-dlp and ffmpeg
option from their caller, so `Config.qml` stays the one place that decides how a
download runs.

`$VIDS_ROOT` overrides the library root without editing anything, which is how
you point a second copy at a different library.

`Theme.qml` is the palette and the metrics, and is a copy of quicky's so the two
stay in step.

## Layout

```
shell.qml         entry point and IPC
Picker.qml        the window: layout, modes, every key
Library.qml       one `find` over the library, parsed into playlists and videos
Media.qml         durations, poster frames, and where mpv left off
Downloads.qml     reads the detached jobs; starts and stops them
Player.qml        mpv, detached
Config.qml        every behavioural knob
Theme.qml         palette and metrics
Icons.qml         Nerd Font codepoints
components/       Label, Glyph, EntryRow, VimList
bin/vids-dl       one download: queued, reported, notified — outlives the picker
bin/vids-probe    one poster frame and one duration per video, cached
bin/vids-resume   mpv's saved positions, as path/seconds pairs
```

The scripts are usable on their own:

```sh
bin/vids-dl add https://... -P ~/Videos -o '%(title)s.%(ext)s'
bin/vids-dl cancel          # stop everything running and queued
bin/vids-dl clear           # forget the failed ones
bin/vids-probe ~/.cache/vids/thumbs 160 video.mkv
bin/vids-resume
```

## IPC

Useful while the picker is open, and mostly so a download can be watched from a
terminal without taking the keyboard back:

```sh
qs -c vids ipc call library rescan
qs -c vids ipc call library videos
qs -c vids ipc call download add https://...
qs -c vids ipc call download into https://... "Some Playlist"
qs -c vids ipc call download status
qs -c vids ipc call download cancel
```

[Quickshell]: https://quickshell.org
