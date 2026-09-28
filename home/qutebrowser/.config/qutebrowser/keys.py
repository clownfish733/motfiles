LEADER = ","  # space stays page-down

DOMAIN = "*://{url:host}/*"


def apply(c, config):
    b = config.bind
    unbind = config.unbind

    # ---- close needs two keys --------------------------------------------
    unbind("d")
    unbind("D")
    b("dd", "tab-close")
    b("dD", "tab-close -o")

    # ---- tabs (wezterm ALT layout) ---------------------------------------
    b("<Alt-t>", "open -t")
    b("<Alt-w>", "tab-close")
    b("<Alt-q>", "tab-close")
    b("<Alt-n>", "tab-next")
    b("<Alt-p>", "tab-prev")
    b("<Alt-l>", "tab-next")
    b("<Alt-h>", "tab-prev")
    b("<Alt-Shift-l>", "tab-move +")
    b("<Alt-Shift-h>", "tab-move -")
    b("<Alt-o>", "tab-only")

    # ---- navigation ------------------------------------------------------
    b("<Ctrl-h>", "back")
    b("<Ctrl-l>", "forward")
    b("gh", "home")
    b("gI", "devtools")

    # ---- leader ----------------------------------------------------------
    b(f"{LEADER}m", "hint links spawn --detach mpv --force-window yes {hint-url}")
    b(f"{LEADER}M", "spawn --detach mpv --force-window yes {url}")
    b(f"{LEADER}v", "spawn --userscript view_in_mpv")
    b(f"{LEADER}z", "hint links download")
    b(f"{LEADER}r", "spawn --userscript readability-js")
    b(f"{LEADER}e", "edit-url")
    b(f"{LEADER}q", "quickmark-save")
    b(f"{LEADER}c", "config-cycle colors.webpage.preferred_color_scheme dark light ;; reload")
    b(f"{LEADER}d", f"config-cycle -p -u {DOMAIN} colors.webpage.darkmode.enabled ;; reload")
    b(f"{LEADER}j", f"config-cycle -p -u {DOMAIN} content.javascript.enabled ;; reload")
    b(f"{LEADER}i", f"config-cycle -p -u {DOMAIN} content.images ;; reload")
    b(f"{LEADER}a", f"config-cycle -p -u {DOMAIN} content.blocking.enabled ;; reload")

    # ---- modes -----------------------------------------------------------
    b("<Ctrl-e>", "edit-text", mode="insert")
    for mode in ("insert", "passthrough", "command", "hint", "caret"):
        b("<Ctrl-[>", "mode-leave", mode=mode)
    b("<Ctrl-j>", "completion-item-focus next", mode="command")
    b("<Ctrl-k>", "completion-item-focus prev", mode="command")

    # ---- misc ------------------------------------------------------------
    b("<Ctrl-Shift-r>", "restart")
