alias ls='eza'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'


HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY EXTENDED_HISTORY HIST_REDUCE_BLANKS HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE

export NEWT_COLORS_FILE=~/.config/newt/colors

export PATH="$HOME/.ghcup/bin:$HOME/.local/bin:$PATH"
export EZA_COLORS="di=1;38;2;240;150;170"  # bold, RGB

export PATH="$HOME/.cargo/bin:$PATH"

fpath=(~/.config/zsh/functions $fpath)
autoload -Uz compinit && compinit

mkcd() {
  mkdir -p -- "$@" && cd -- "$1"
}
compdef _directories mkcd

#   newtex [dir] [tmpl]     scaffold dir/main.tex from tmpl (default: article)
#   newtex -l               list templates
#   newtex -s <name> [file] save file (default main.tex) as template <name>
newtex() {
  local tdir="$HOME/.config/tex/templates"
  local -a templates
  templates=($tdir/*.tex(N:t:r))

  case "$1" in
    -l|--list)
      (( $#templates )) && print -l -- $templates || echo "no templates in $tdir" >&2
      return
      ;;
    -s|--save)
      local name="$2" src="${3:-main.tex}"
      [[ -n "$name" ]] || { echo "usage: newtex -s <name> [file]" >&2; return 1; }
      [[ -f "$src" ]] || { echo "no such file: $src" >&2; return 1; }
      mkdir -p "$tdir" && cp -i "$src" "$tdir/$name.tex" && echo "saved template: $name"
      return
      ;;
  esac

  local dir="${1:-.}" tmpl="${2:-article}"
  local src="$tdir/$tmpl.tex"
  [[ -f "$src" ]] || {
    echo "no template: $tmpl" >&2
    echo "available: ${templates[*]:-none}" >&2
    return 1
  }
  mkdir -p "$dir" && cp -n "$src" "$dir/main.tex"
  cp -n "$HOME/.config/tex/gitignore" "$dir/.gitignore" 2>/dev/null
  cd "$dir" && nvim main.tex
}

#   usb              list partitions on every USB disk
#   usb m [dev]      mount (default: the first unmounted partition)
#   usb u [dev]      unmount (default: every mounted partition)
#   usb e [dev]      unmount the whole disk, then power it down for unplugging
usb() {
  emulate -L zsh
  local -a disks all free
  local d p cmd=${1:-list} dev=$2

  disks=(${(f)"$(lsblk -rpno NAME,TYPE,TRAN | awk '$2=="disk" && $3=="usb"{print $1}')"})
  (( $#disks )) || { echo "no usb disks attached" >&2; return 1 }

  for d in $disks; do
    all+=(${(f)"$(lsblk -rpno NAME,TYPE,FSTYPE $d | awk '$2=="part" && $3!=""{print $1}')"})
  done
  for p in $all; do [[ -z $(findmnt -nro TARGET $p) ]] && free+=($p); done

  [[ $cmd == /dev/* ]] && { dev=$cmd; cmd=mount }

  case $cmd in
    list|l)
      lsblk -po NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT $disks
      ;;
    mount|m)
      : ${dev:=$free[1]}
      [[ -n $dev ]] || { echo "nothing left to mount" >&2; return 1 }
      udisksctl mount -b $dev
      ;;
    umount|unmount|u)
      local -a targets=(${dev:-${all:|free}})
      (( $#targets )) || { echo "nothing mounted" >&2; return 1 }
      for p in $targets; do udisksctl unmount -b $p; done
      ;;
    eject|e)
      d=${dev:-$disks[1]}
      [[ $d == $disks[(r)$d] ]] || d=/dev/$(lsblk -nro PKNAME $d)
      for p in ${all:|free}; do
        [[ $p == $d* ]] && udisksctl unmount -b $p
      done
      udisksctl power-off -b $d && echo "safe to unplug $d"
      ;;
    *)
      echo "usage: usb [list|m|u|e] [dev]" >&2; return 1
      ;;
  esac
}

source <(fzf --zsh)
source ~/.config/shell/fzf.sh
eval "$(starship init zsh)"

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

bindkey -v
export KEYTIMEOUT=1

bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char
