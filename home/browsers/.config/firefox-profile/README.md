Profiles live under `~/.config/mozilla/firefox`, not `~/.mozilla`: Firefox 153+
follows the XDG base directories on Linux.


## Profile config

`user.js`, `userChrome.css` and `userContent.css` are symlinked into every
profile named in `profiles.txt`, so an edit here is live in all of them after
the next restart. `install.sh` runs this; by hand it is

    firefox-profile-setup                   # links + add-ons
    firefox-profile-setup --no-extensions   # links only

Profiles are matched on the `Name=` in `profiles.ini`, not on the directory,
because release profiles get a salted directory name
(`216g1vpt.default-release`). `firefox-profile-setup` does that lookup; add or
drop lines in `profiles.txt` to change which profiles are covered.
`firefox-basic` is deliberately left out (see below).

`default-release` does not exist until Firefox has been started once, so on a
fresh install the script reports it missing and skips it. Start Firefox, then
run the script again. Anything already at one of those paths that is not a
symlink is moved aside to `.bak` rather than overwritten.

`user.js` is re-applied on every startup, so the prefs it sets cannot be changed
from `about:config` permanently -- they revert on the next launch. Edit the file
here instead.


## Add-ons

`extensions.txt` lists `<add-on id> <addons.mozilla.org slug>`. For every
configured profile, `firefox-profile-setup` downloads the latest release of
each one from AMO and drops it at `<profile>/extensions/<id>.xpi`; Firefox
installs it on the next start. The filename has to be the add-on's real id or
Firefox ignores the file -- look it up with

    curl -s https://addons.mozilla.org/api/v5/addons/addon/<slug>/ | jq -r .guid

Add-ons dropped in like this normally come up disabled behind an "add this
extension?" prompt. `user.js` sets `extensions.autoDisableScopes` to 14 (the
default 15 minus the profile scope) so they are enabled straight away.

Anything already in the profile, installed by hand or by an earlier run, is
skipped. Firefox keeps them updated from then on, and removing one in
`about:addons` sticks unless its line is still here and the script is rerun.

Bypass Paywalls Clean is not on AMO, so it is not in the list: install the
signed .xpi from
<https://gitflic.ru/project/magnolia1234/bypass-paywalls-firefox-clean#installation>.


## Toolbars at the bottom

`userChrome.css` moves `#navigator-toolbox` (tab strip, address bar, bookmarks)
below the content area, and flips the address bar's results panel upwards so it
is not cut off by the bottom edge of the screen.

Nothing has to be switched on by hand in the browser: `user.js` sets
`toolkit.legacyUserProfileCustomizations.stylesheets`, which is what makes
Firefox read `chrome/userChrome.css` at all. Two things are still worth knowing:

  - Restart Firefox completely after editing it. The file is parsed once at
    startup; opening a new window does not re-read it.
  - `about:support` -> "Profile Directory" confirms which profile is live, if a
    change does not show up.

Anything that overrides a property Firefox's own stylesheets already set needs
`!important`. userChrome.css loads in the *user* cascade origin, which loses to
author styles -- the `order` rule is the exception only because nothing else
sets `order` on the toolbox.

Checked against Firefox 155. The chrome DOM is not a stable API, so if an update
breaks the layout, read the real markup instead of guessing at selectors:

    unzip -o /usr/lib/firefox/browser/omni.ja \
        'chrome/browser/content/browser/browser.xhtml' \
        'chrome/browser/skin/classic/browser/*.css' -d /tmp/ffx

`toolbars_below_content.css` in <https://github.com/MrOtherGuy/firefox-csshacks>
is the maintained-by-someone-else version, if keeping up with this stops being
worth it.


## Black blank tab

`browser.newtabpage.enabled` is false, so a new tab is not `about:newtab` --
it is `chrome://browser/content/blanktab.html`, a document containing nothing
but `<meta name="color-scheme" content="light dark">`. It sets no background,
so the window is filled by the canvas colour Gecko picks for a dark document,
`#1c1b22`. That is not a theme token and not a pref:
`browser.display.background_color.dark` leaves it alone, since that only
applies when document colours are overridden wholesale.

`userContent.css` gives the root element a background instead. The rule has to
be there and not in `userChrome.css` -- blanktab.html loads in the tab, so it
takes the content sheet despite the `chrome:` URI. Rendering the page under
each sheet is how to check that, and is worth redoing if an update breaks it:

    firefox --headless --window-size=600,400 --screenshot=out.png \
        --profile <tmp> chrome://browser/content/blanktab.html

The toolbars are already black here, and menus and panels are a separate
surface (`--arrowpanel-background`), left alone.


## Google results

`userContent.css` also blacks out google.com. Google's dark theme is #202124
and it repaints its containers individually under obfuscated class names that
turn over every few months, so the rule paints the page and makes the
long-lived structural ids (`#main`, `#center_col`, `#searchform` ...)
transparent to let it through. A selector that stops matching then costs
nothing, where a missed container would leave a grey slab. Unlike the blanktab
rule this one is unverified -- Google will not render under headless
automation.

The clutter is a search setting rather than CSS. `udm=14` is Google's plain
"Web" mode: no AI Overview, no knowledge panels, no "People also ask", no
sponsored cards. Settings -> Search -> Add, with

    https://www.google.com/search?q=%s&udm=14

as the URL, then set it as the default. It lives in `search.json.mozlz4`, not
in a pref, so it cannot be symlinked in from here -- it has to be added by hand
per profile.


## Extra profiles

Two more Firefox launchers, each its own instance with its own window class:

| launcher | profile / app_id | config |
| --- | --- | --- |
| Firefox (Other) | `firefox-clone` | everything here, same as `default-release` |
| Firefox (Basic) | `firefox-basic` | none: stock Firefox, no `user.js`, styles or add-ons |

`install.sh` creates both profiles (after starting Firefox headless once so
`default-release` exists first). By hand:

    env MOZ_APP_REMOTINGNAME=firefox-basic-setup /usr/lib/firefox/firefox \
        --no-remote \
        -CreateProfile "firefox-basic $HOME/.config/mozilla/firefox/firefox-basic"

Check, with them running:

    swaymsg -t get_tree | grep -oE '"app_id": "firefox[^"]*"' | sort -u

Expect `firefox`, `firefox-clone` and `firefox-basic`. Fewer means a launch was
folded into an instance that was already running.

sway rules target `app_id=firefox-clone` / `app_id=firefox-basic`.
For a different launcher icon, set `Icon=` to an absolute path.
Do not add `MimeType=`; it competes for the default browser.
