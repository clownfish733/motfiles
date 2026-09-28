# wallpaper

A wallpaper picker for Hyprland: a horizontal strip of previews over the
desktop, and nothing else. `awww` does the actual setting.

    ln -s ~/Dev/wallpaper ~/.config/quickshell/wallpaper
    qs -c wallpaper

It is one-shot — it draws the strip, sets what you pick, and exits — so bind it
straight to a key:

    bind = SUPER, W, exec, qs -c wallpaper

| key       | does                                  |
|-----------|---------------------------------------|
| `h` / `l` | previous / next preview (wraps)       |
| `g` / `G` | first / last                          |
| `⏎`       | set that wallpaper and quit           |
| `Esc`/`q` | quit without setting                  |

Five previews are on screen at all times, centred on the selected one, and the
list is circular: `l` off the last wallpaper carries straight on to the first
with no rewind. With fewer than five wallpapers in the directory the window is
wider than the list, so a wallpaper shows up more than once — that is what a
circular list of four looks like through a five-wide window, not a glitch.

Clicking a preview focuses it; clicking the focused one sets it. Clicking
anywhere else quits.

The strip opens on whatever is already on the desktop, which it learns by
asking `awww query` rather than by keeping its own state file — so a wallpaper
set from somewhere else is still the one selected.

Directory is `dir` in `Wallpapers.qml`; everything else is a token in
`Theme.qml`, including `visible` (how many previews are on screen — keep it
odd, so one is dead centre).
