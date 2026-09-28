import os
import sys

sys.path.insert(0, os.path.dirname(os.path.realpath(__file__)))

import keys
import theme

config.load_autoconfig(False)

# ---- fonts ---------------------------------------------------------------
c.fonts.default_family = ["Hack Nerd Font", "Hack"]
c.fonts.default_size = "13px"
c.fonts.web.family.standard = "sans-serif"
c.fonts.web.family.sans_serif = "sans-serif"
c.fonts.web.family.serif = "serif"
c.fonts.web.family.fixed = "Fira Code"
c.fonts.web.size.default = 16
c.fonts.web.size.default_fixed = 14
c.fonts.hints = "bold 13px Hack Nerd Font"
c.fonts.statusbar = "13px Hack Nerd Font"
c.fonts.tabs.selected = "13px Hack Nerd Font"
c.fonts.tabs.unselected = "13px Hack Nerd Font"

# ---- window / chrome -----------------------------------------------------
c.window.hide_decoration = True
c.window.title_format = "{audio}{perc}{current_title}"
c.tabs.show = "multiple"
c.tabs.position = "top"
c.tabs.title.format = "{audio}{index}: {current_title}"
c.tabs.indicator.width = 2
c.tabs.indicator.padding = {"top": 2, "bottom": 2, "left": 0, "right": 3}
c.tabs.padding = {"top": 4, "bottom": 4, "left": 8, "right": 8}
c.tabs.favicons.scale = 1.0
c.tabs.last_close = "close"
c.tabs.new_position.related = "next"
c.tabs.select_on_remove = "prev"
c.tabs.mousewheel_switching = False

c.statusbar.show = "always"
c.statusbar.widgets = ["keypress", "url", "scroll", "history", "tabs", "progress"]
c.statusbar.padding = {"top": 4, "bottom": 4, "left": 6, "right": 6}

c.completion.height = "40%"
c.completion.shrink = True
c.completion.scrollbar.width = 4
c.completion.scrollbar.padding = 2
c.completion.timestamp_format = "%Y-%m-%d"

c.scrolling.smooth = True
c.zoom.default = "100%"

# ---- hints ---------------------------------------------------------------
c.hints.chars = "asdfghjkl"
c.hints.uppercase = False
c.hints.border = "none"
c.hints.radius = 8

# ---- input ---------------------------------------------------------------
c.input.insert_mode.auto_load = False
c.input.insert_mode.auto_leave = True
c.input.partial_timeout = 2000
c.editor.command = [
    "wezterm", "start", "--",
    "nvim", "-c", "normal {line}G{column0}l", "{file}",
]

# ---- qt ------------------------------------------------------------------
c.qt.environ = {"NODE_PATH": "/usr/lib/node_modules"}
c.qt.args = ["enable-features=VaapiVideoDecoder"]

# ---- content / privacy ---------------------------------------------------
c.content.blocking.method = "both"
c.content.blocking.adblock.lists = [
    "https://easylist.to/easylist/easylist.txt",
    "https://easylist.to/easylist/easyprivacy.txt",
    "https://secure.fanboy.co.nz/fanboy-annoyance.txt",
    "https://easylist.to/easylist/fanboy-social.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/filters.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/privacy.txt",
    "https://github.com/uBlockOrigin/uAssets/raw/master/filters/badware.txt",
    "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts",
]
c.content.cookies.accept = "no-3rdparty"
# Microsoft login bounces across domains and breaks without 3rd-party cookies
for pattern in [
    "*://*.microsoftonline.com/*",
    "*://*.microsoft.com/*",
    "*://*.live.com/*",
    "*://*.office.com/*",
    "*://*.microsoft365.com/*",
]:
    config.set("content.cookies.accept", "all", pattern)
c.content.headers.do_not_track = True
c.content.headers.referer = "same-domain"
c.content.autoplay = False
c.content.geolocation = "ask"
c.content.notifications.enabled = "ask"
c.content.notifications.presenter = "libnotify"
c.content.pdfjs = True
c.content.prefers_reduced_motion = False
c.content.javascript.clipboard = "ask"

# ---- downloads -----------------------------------------------------------
c.downloads.location.directory = os.path.expanduser("~/Downloads")
c.downloads.location.prompt = False
c.downloads.location.remember = False
c.downloads.position = "bottom"
c.downloads.remove_finished = 10000

# ---- session -------------------------------------------------------------
c.auto_save.session = True
c.session.lazy_restore = True
c.url.default_page = "about:blank"
c.url.start_pages = ["about:blank"]
c.confirm_quit = ["downloads"]
c.spellcheck.languages = ["en-GB"]

# ---- search --------------------------------------------------------------
c.url.searchengines = {
    "DEFAULT": "https://noai.duckduckgo.com/?q={}",
    "g": "https://www.google.com/search?q={}",
    "aw": "https://wiki.archlinux.org/index.php?search={}",
    "ap": "https://archlinux.org/packages/?q={}",
    "aur": "https://aur.archlinux.org/packages?K={}",
    "gh": "https://github.com/search?q={}",
    "yt": "https://www.youtube.com/results?search_query={}",
    "w": "https://en.wikipedia.org/w/index.php?search={}",
    "rs": "https://docs.rs/releases/search?query={}",
    "cr": "https://crates.io/search?q={}",
    "hs": "https://hoogle.haskell.org/?hoogle={}",
    "hk": "https://hackage.haskell.org/packages/search?terms={}",
    "cpp": "https://en.cppreference.com/mwiki/index.php?search={}",
    "so": "https://stackoverflow.com/search?q={}",
    "ctan": "https://ctan.org/search?phrase={}",
    "man": "https://man.archlinux.org/search?q={}",
}

# ---- aliases -------------------------------------------------------------
c.aliases["mpv"] = "spawn --detach mpv --force-window yes {url}"
c.aliases["zathura"] = "spawn --detach zathura {url}"

theme.apply(c, config)
keys.apply(c, config)
