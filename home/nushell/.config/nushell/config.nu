# config.nu
# Port of the old zshrc. Nu already gives you autosuggestions (hints),
# syntax highlighting and a structured `ls`, so no plugins are needed for those.

$env.config.show_banner = false
$env.config.buffer_editor = "nvim"

# --- history (sqlite = timestamps, cwd, exit codes: like EXTENDED_HISTORY) ---
# Commands starting with a space are not saved (HIST_IGNORE_SPACE).
$env.config.history = {
    file_format: sqlite
    max_size: 50_000
    sync_on_enter: true   # SHARE_HISTORY
    isolation: false
}

# --- vi mode (bindkey -v); reedline has no ESC delay, so no KEYTIMEOUT needed ---
$env.config.edit_mode = "vi"
$env.config.cursor_shape = {vi_insert: line, vi_normal: block}
# hide nu's default vi-mode indicators (": " / "> "); starship draws the prompt char
$env.PROMPT_INDICATOR_VI_INSERT = ""
$env.PROMPT_INDICATOR_VI_NORMAL = ""

# --- completions ---
$env.config.completions.algorithm = "fuzzy"
$env.config.completions.case_sensitive = false

# --- aliases ---
# `ls` stays nu's builtin (returns a table you can `where`/`sort-by`).
# Use `eza` directly when you want its tree/icons view.
alias l = ls -l
alias la = ls -a
alias lla = ls -la

# Make a directory (with parents) and cd into it
def --env mkcd [dir: directory] {
    mkdir $dir
    cd $dir
}

use ~/.config/nushell/scripts/newtex.nu
use ~/.config/nushell/scripts/usb.nu
use ~/.config/nushell/scripts/fzf.nu *

# --- fzf keybindings (only if fzf is installed) ---
if (which fzf | is-not-empty) {
    $env.config.keybindings ++= [
        {
            name: fzf_files
            modifier: control
            keycode: char_t
            mode: [emacs vi_insert vi_normal]
            event: {send: executehostcommand, cmd: "fzf-file-widget"}
        }
        {
            name: fzf_cd
            modifier: alt
            keycode: char_c
            mode: [emacs vi_insert vi_normal]
            event: {send: executehostcommand, cmd: "fzf-cd-widget"}
        }
    ]
}

# --- validity highlighting (like zsh-syntax-highlighting) ---
# Known commands turn green as you type; unknown ones red. Parse errors
# already get a red background (shape_garbage).
$env.config.highlight_resolved_externals = true
$env.config.color_config.shape_internalcall = "green_bold"       # builtins, aliases, defs
$env.config.color_config.shape_external_resolved = "green_bold"  # found on $PATH
$env.config.color_config.shape_external = "red_bold"             # not found
