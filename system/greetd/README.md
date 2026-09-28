FILE_LOCATION:
  config.toml   -> /etc/greetd/config.toml
  greeter       -> /etc/greetd/greeter        (0755)
  vtrgb         -> /etc/greetd/vtrgb
  tuigreet.toml -> /etc/tuigreet/config.toml
  sway-session  -> /usr/local/bin/sway-session (0755)

install.sh does all of this. The rest of this file is why.

# The greeter

../tuigreet is a fork of the greetd TUI greeter, restyled to match the
quickshell palette: bevelled containers, a drop shadow, and the wine outline
from ~/.config/quickshell/quicky/Theme.qml. install.sh builds it and puts the
binary at /usr/local/bin/tuigreet — out of pacman's way, so an upgrade of the
packaged greetd-tuigreet cannot quietly replace it.

The packaged /usr/bin/tuigreet stays installed on purpose. It is the way back:
from any TTY, setting `command = "tuigreet"` in /etc/greetd/config.toml gets
you to a working login again.

# Why the console needs its own colours

VT 1 is a much poorer display than a terminal emulator, and two things do not
survive the trip.

**Colour.** The console has sixteen palette slots and no truecolour. A 24-bit
escape is not rejected — the kernel thresholds each channel and picks the
nearest slot — so #993954 (outline), #c74e6f (lit edge) and #57444a (shaded
edge) all land on magenta and the bevel flattens into one tone. So `vtrgb`
repoints the sixteen slots at the desktop palette, and `tuigreet.toml` names
ANSI colours that land in them exactly. Under a terminal emulator none of this
is needed: the built-in defaults are already these colours as hex.

`setvtrgb` runs from the `greeter` wrapper rather than a boot-time unit
because the palette is per-VT and only survives on the console greetd actually
opens. The ioctl behind it (PIO_CMAP) is permitted because the greeter user
owns that VT for the duration.

**Glyphs.** Console fonts carry a few hundred glyphs. None on this system has
the rounded corners at U+256D-256F, so the greeter defaults to plain corners
and U+25B6 for the menu cursor — every glyph it draws is in even the stock
default8x16.

The console *font* cannot be set from the wrapper (KDFONTOP wants
CAP_SYS_TTY_CONFIG), so install.sh sets FONT=ter-v32n in /etc/vconsole.conf
instead. This is legibility, not correctness: at 8x16 on a 1920x1200 panel the
greeter gets 240x75 cells and tuigreet sizes itself to the monitor, so the
text ends up tiny.

# Check it before you trust it

A greeter that fails to start is a machine you cannot log into. Before
rebooting, on a spare VT (Ctrl+Alt+F3, log in, then):

    setvtrgb /etc/greetd/vtrgb
    /usr/local/bin/tuigreet --mock

That is the real console, the real font and the real palette, with no greetd
involved — what you see there is what you get at login. Ctrl+C to leave;
`setvtrgb default` puts the palette back.

The one thing that cannot be checked from a logged-in session is whether
setvtrgb succeeds as the unprivileged greeter user. The wrapper treats a
failure as non-fatal, so the worst case is stock console colours rather than a
login you cannot reach. If the palette does not take, run it from a root unit
ordered Before=greetd.service with TTYPath=/dev/tty1 instead.

# Updating the greeter

../tuigreet is a vendored copy of the working tree at ~/Probe/tuigreet, minus
that checkout's .git, target/ and contrib/console/ — the last because its
deployable files live here in greetd/ instead, so there is only one copy of
the palette and the theme. To re-vendor after changing the fork:

    cd ~/Probe/tuigreet
    tar -cf - --exclude=./.git --exclude=./target --exclude=./contrib/console . \
      | (rm -rf ~/Dots/tuigreet && mkdir -p ~/Dots/tuigreet \
         && cd ~/Dots/tuigreet && tar -xf -)

That resets one link in tuigreet/README.md, which points at
[`greetd/README.md`](README.md) here rather than at the deleted
contrib/console. Fix it or leave it; nothing reads it but you.
