# ~/.config/shell/fzf.sh  —  source this from .zshrc 
# fzf >= 0.55 assumed. Check with: fzf --version

# ─────────────────────────────────────────────────────────────
# Colors — Catppuccin Mocha. Swap the hexes for another palette.
# ─────────────────────────────────────────────────────────────
_fzf_colors="
  --color=bg+:#313244,bg:-1,spinner:#f5e0dc,hl:#f38ba8
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f4,pointer:#f5e0dc
  --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f4,hl+:#f38ba8
  --color=border:#6c7086,label:#a6adc8,query:#cdd6f4
  --color=gutter:-1,preview-bg:-1,scrollbar:#6c7086
"
# bg:-1 = transparent, inherits terminal bg. Nice with WezTerm opacity.

# ─────────────────────────────────────────────────────────────
# Global defaults
# ─────────────────────────────────────────────────────────────
export FZF_DEFAULT_OPTS="
  $_fzf_colors

  # --- layout / chrome ---
  --style=full
  --layout=reverse
  --height=60%
  --min-height=15
  --border=rounded
  --border-label-pos=2
  --padding=0,1
  --margin=0
  --separator='─'
  --scrollbar='│'

  # --- info line ---
  --info=inline-right
  --prompt='  '
  --pointer='▶'
  --marker='✓'
  --ellipsis='…'

  # --- behaviour ---
  --cycle
  --multi
  --highlight-line
  --scroll-off=3
  --tabstop=2

  # --- preview window ---
  --preview-window='right,60%,border-left,~3'
  --preview-label-pos=2

  # --- keybinds ---
  --bind='ctrl-/:toggle-preview'
  --bind='ctrl-u:preview-half-page-up'
  --bind='ctrl-d:preview-half-page-down'
  --bind='ctrl-a:select-all'
  --bind='ctrl-y:execute-silent(printf %s {+} | wl-copy)+abort'
  --bind='alt-p:change-preview-window(down,70%|hidden|right,60%)'
  --bind='ctrl-j:down,ctrl-k:up'
  --bind='esc:abort'
"

# ─────────────────────────────────────────────────────────────
# Source commands (needs fd + ripgrep)
# ─────────────────────────────────────────────────────────────
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# ─────────────────────────────────────────────────────────────
# Per-binding overrides
# ─────────────────────────────────────────────────────────────
export FZF_CTRL_T_OPTS="
  --border-label=' files '
  --preview='bat --style=numbers --color=always --line-range=:300 {} 2>/dev/null || eza --tree --color=always --level=2 {}'
  --preview-label=' preview '
  --bind='ctrl-o:execute(\$EDITOR {} > /dev/tty)'
"

export FZF_CTRL_R_OPTS="
  --border-label=' history '
  --preview='echo {2..}'
  --preview-window='down,4,wrap,border-top'
  --preview-label=' command '
  --bind='ctrl-y:execute-silent(echo -n {2..} | wl-copy)+abort'
  --header='ctrl-y: copy'
  --header-first
"

export FZF_ALT_C_OPTS="
  --border-label=' cd '
  --preview='eza --tree --color=always --level=2 --icons {}'
  --preview-label=' tree '
"

# ─────────────────────────────────────────────────────────────
# Tab-completion trigger + preview (fzf's shell completion)
# ─────────────────────────────────────────────────────────────
export FZF_COMPLETION_TRIGGER='**'
export FZF_COMPLETION_OPTS='--border=rounded --info=inline'

_fzf_comprun() {
  local command=$1; shift
  case "$command" in
    cd)           fzf --preview 'eza --tree --color=always --level=2 {}' "$@" ;;
    export|unset) fzf --preview "eval 'echo \$'{}"                        "$@" ;;
    ssh)          fzf --preview 'dig +short {}'                           "$@" ;;
    *)            fzf --preview 'bat -n --color=always {}'                "$@" ;;
  esac
}

# ─────────────────────────────────────────────────────────────
# Popup/menu preset — for your floating WezTerm menu-* windows.
# Use:  fzf $(fzf_menu_opts) < list
# ─────────────────────────────────────────────────────────────
fzf_menu_opts() {
  printf '%s' "
    --style=minimal
    --height=100%
    --layout=reverse
    --border=none
    --info=hidden
    --no-scrollbar
    --padding=1,2
    --prompt='› '
    --pointer='●'
  "
}

# ─────────────────────────────────────────────────────────────
# Shell integration (keep last)
# ─────────────────────────────────────────────────────────────

if [ -n "$ZSH_VERSION" ]; then
  eval "$(fzf --zsh)"
elif [ -n "$BASH_VERSION" ]; then
  eval "$(fzf --bash)"
fi

