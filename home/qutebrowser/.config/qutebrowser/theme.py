# quickshell's palette. Black, outlined in #993954.

bg      = "#000000"
outline = "#993954"

# outline at 0.28 / 0.14 over bg, flattened
accent        = outline
accent_soft   = "#2b1018"
accent_faint  = "#15080c"
accent_bright = "#ff5f8c"

fg       = "#e6dde0"
fg_dim   = "#8b7076"
fg_faint = "#57444a"

warn = "#d8a05a"
crit = "#d2536a"
good = "#7fb069"


def apply(c, config):
    # ---- completion ------------------------------------------------------
    c.colors.completion.fg = fg
    c.colors.completion.odd.bg = bg
    c.colors.completion.even.bg = bg
    c.colors.completion.category.fg = fg_dim
    c.colors.completion.category.bg = bg
    c.colors.completion.category.border.top = outline
    c.colors.completion.category.border.bottom = bg
    c.colors.completion.item.selected.fg = fg
    c.colors.completion.item.selected.bg = accent_soft
    c.colors.completion.item.selected.border.top = outline
    c.colors.completion.item.selected.border.bottom = outline
    c.colors.completion.item.selected.match.fg = accent_bright
    c.colors.completion.match.fg = accent_bright
    c.colors.completion.scrollbar.fg = outline
    c.colors.completion.scrollbar.bg = bg

    # ---- context menu ----------------------------------------------------
    c.colors.contextmenu.menu.bg = bg
    c.colors.contextmenu.menu.fg = fg
    c.colors.contextmenu.selected.bg = accent_soft
    c.colors.contextmenu.selected.fg = fg
    c.colors.contextmenu.disabled.bg = bg
    c.colors.contextmenu.disabled.fg = fg_faint

    # ---- downloads -------------------------------------------------------
    c.colors.downloads.bar.bg = bg
    c.colors.downloads.start.fg = fg
    c.colors.downloads.start.bg = accent_soft
    c.colors.downloads.stop.fg = bg
    c.colors.downloads.stop.bg = good
    c.colors.downloads.error.fg = bg
    c.colors.downloads.error.bg = crit
    c.colors.downloads.system.fg = "none"
    c.colors.downloads.system.bg = "none"

    # ---- hints -----------------------------------------------------------
    # accentBright: marks drawn over arbitrary page content, same as vicky's
    # posters -- the outline itself vanishes on a light page.
    c.colors.hints.bg = accent_bright
    c.colors.hints.fg = bg
    c.colors.hints.match.fg = fg_faint

    # ---- keyhint ---------------------------------------------------------
    c.colors.keyhint.bg = accent_faint
    c.colors.keyhint.fg = fg
    c.colors.keyhint.suffix.fg = accent_bright

    # ---- messages --------------------------------------------------------
    c.colors.messages.error.bg = bg
    c.colors.messages.error.fg = crit
    c.colors.messages.error.border = crit
    c.colors.messages.warning.bg = bg
    c.colors.messages.warning.fg = warn
    c.colors.messages.warning.border = warn
    c.colors.messages.info.bg = bg
    c.colors.messages.info.fg = fg_dim
    c.colors.messages.info.border = outline

    # ---- prompts ---------------------------------------------------------
    c.colors.prompts.bg = bg
    c.colors.prompts.fg = fg
    c.colors.prompts.border = f"1px solid {outline}"
    c.colors.prompts.selected.bg = accent_soft
    c.colors.prompts.selected.fg = fg

    # ---- statusbar -------------------------------------------------------
    c.colors.statusbar.normal.bg = bg
    c.colors.statusbar.normal.fg = fg
    c.colors.statusbar.insert.bg = accent_soft
    c.colors.statusbar.insert.fg = good
    c.colors.statusbar.passthrough.bg = accent_soft
    c.colors.statusbar.passthrough.fg = warn
    c.colors.statusbar.command.bg = bg
    c.colors.statusbar.command.fg = fg
    c.colors.statusbar.private.bg = accent_faint
    c.colors.statusbar.private.fg = fg_dim
    c.colors.statusbar.command.private.bg = accent_faint
    c.colors.statusbar.command.private.fg = fg
    c.colors.statusbar.caret.bg = accent_soft
    c.colors.statusbar.caret.fg = accent_bright
    c.colors.statusbar.caret.selection.bg = accent_soft
    c.colors.statusbar.caret.selection.fg = fg
    c.colors.statusbar.progress.bg = outline

    c.colors.statusbar.url.fg = fg_dim
    c.colors.statusbar.url.hover.fg = fg
    c.colors.statusbar.url.success.http.fg = warn
    c.colors.statusbar.url.success.https.fg = fg
    c.colors.statusbar.url.warn.fg = warn
    c.colors.statusbar.url.error.fg = crit

    # ---- tabs ------------------------------------------------------------
    # The workspace-pill ladder: selected fills accentSoft, occupied is fgDim
    # text on nothing, and only the urgent case borrows crit.
    c.colors.tabs.bar.bg = bg
    c.colors.tabs.odd.bg = bg
    c.colors.tabs.odd.fg = fg_dim
    c.colors.tabs.even.bg = bg
    c.colors.tabs.even.fg = fg_dim
    c.colors.tabs.selected.odd.bg = accent_soft
    c.colors.tabs.selected.odd.fg = fg
    c.colors.tabs.selected.even.bg = accent_soft
    c.colors.tabs.selected.even.fg = fg
    c.colors.tabs.pinned.odd.bg = accent_faint
    c.colors.tabs.pinned.odd.fg = fg_dim
    c.colors.tabs.pinned.even.bg = accent_faint
    c.colors.tabs.pinned.even.fg = fg_dim
    c.colors.tabs.pinned.selected.odd.bg = accent_soft
    c.colors.tabs.pinned.selected.odd.fg = fg
    c.colors.tabs.pinned.selected.even.bg = accent_soft
    c.colors.tabs.pinned.selected.even.fg = fg
    c.colors.tabs.indicator.start = outline
    c.colors.tabs.indicator.stop = accent_bright
    c.colors.tabs.indicator.error = crit

    # ---- webpage ---------------------------------------------------------
    c.colors.webpage.bg = bg
    c.colors.webpage.preferred_color_scheme = "dark"
    c.colors.webpage.darkmode.enabled = True
    c.colors.webpage.darkmode.algorithm = "lightness-cielab"
    c.colors.webpage.darkmode.policy.page = "smart"
    c.colors.webpage.darkmode.policy.images = "never"
    c.colors.webpage.darkmode.threshold.foreground = 150
    c.colors.webpage.darkmode.threshold.background = 100
