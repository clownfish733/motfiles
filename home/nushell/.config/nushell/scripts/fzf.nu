# fzf.nu — port of ~/.config/shell/fzf.sh
# Ctrl-R stays on nushell's own (sqlite-backed) history menu; fzf gets
# Ctrl-T (insert files) and Alt-C (cd into dir).

# Colors — Catppuccin Mocha. bg:-1 = transparent, inherits terminal bg.
const colors = [
    "--color=bg+:#313244,bg:-1,spinner:#f5e0dc,hl:#f38ba8"
    "--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f4,pointer:#f5e0dc"
    "--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f4,hl+:#f38ba8"
    "--color=border:#6c7086,label:#a6adc8,query:#cdd6f4"
    "--color=gutter:-1,preview-bg:-1,scrollbar:#6c7086"
]

const defaults = [
    # fzf spawns previews/execute() via $SHELL; the preview strings below are
    # sh syntax, so run them with bash instead of nu.
    "--with-shell='bash -c'"

    # layout / chrome
    "--style=full" "--layout=reverse" "--height=60%" "--min-height=15"
    "--border=rounded" "--border-label-pos=2" "--padding=0,1" "--margin=0"
    "--separator='─'" "--scrollbar='│'"

    # info line
    "--info=inline-right" "--prompt='  '" "--pointer='▶'" "--marker='✓'" "--ellipsis='…'"

    # behaviour
    "--cycle" "--multi" "--highlight-line" "--scroll-off=3" "--tabstop=2"

    # preview window
    "--preview-window='right,60%,border-left,~3'" "--preview-label-pos=2"

    # keybinds
    "--bind='ctrl-/:toggle-preview'"
    "--bind='ctrl-u:preview-half-page-up'"
    "--bind='ctrl-d:preview-half-page-down'"
    "--bind='ctrl-a:select-all'"
    "--bind='ctrl-y:execute-silent(printf %s {+} | wl-copy)+abort'"
    "--bind='alt-p:change-preview-window(down,70%|hidden|right,60%)'"
    "--bind='ctrl-j:down,ctrl-k:up'"
    "--bind='esc:abort'"
]

export-env {
    $env.FZF_DEFAULT_OPTS = ($colors ++ $defaults | str join " ")

    $env.FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git"
    $env.FZF_CTRL_T_COMMAND = $env.FZF_DEFAULT_COMMAND
    $env.FZF_ALT_C_COMMAND = "fd --type d --hidden --follow --exclude .git"

    $env.FZF_CTRL_T_OPTS = [
        "--border-label=' files '"
        "--preview='bat --style=numbers --color=always --line-range=:300 {} 2>/dev/null || eza --tree --color=always --level=2 {}'"
        "--preview-label=' preview '"
        "--bind='ctrl-o:execute($EDITOR {} > /dev/tty)'"
    ] | str join " "

    $env.FZF_ALT_C_OPTS = [
        "--border-label=' cd '"
        "--preview='eza --tree --color=always --level=2 --icons {}'"
        "--preview-label=' tree '"
        "--no-multi"
    ] | str join " "
}

# Popup/menu preset for floating menu windows.
# Use:  $list | fzf ...(fzf_menu_opts)
export def fzf_menu_opts [] {
    [
        --style=minimal --height=100% --layout=reverse --border=none
        --info=hidden --no-scrollbar --padding=1,2 "--prompt=› " "--pointer=●"
    ]
}

# Ctrl-T: pick files, insert them at the cursor.
export def fzf-file-widget [] {
    let picked = with-env {
        FZF_DEFAULT_COMMAND: $env.FZF_CTRL_T_COMMAND
        FZF_DEFAULT_OPTS: $"($env.FZF_DEFAULT_OPTS) ($env.FZF_CTRL_T_OPTS)"
    } { do -i { fzf } } | lines
    if ($picked | is-not-empty) {
        commandline edit --insert ($picked | each {|p| if ($p =~ '\s') { $"'($p)'" } else { $p } } | str join " ")
    }
}

# Alt-C: pick a directory and cd into it.
export def --env fzf-cd-widget [] {
    let dir = with-env {
        FZF_DEFAULT_COMMAND: $env.FZF_ALT_C_COMMAND
        FZF_DEFAULT_OPTS: $"($env.FZF_DEFAULT_OPTS) ($env.FZF_ALT_C_OPTS)"
    } { do -i { fzf } } | str trim
    if ($dir | is-not-empty) { cd $dir }
}
