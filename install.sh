#!/usr/bin/env bash
# Takes a fresh minimal Arch install (see INSTALL.md for what comes before
# this) to the full setup: packages, toolchains, dotfiles, boot/login, shell.
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"
dots="$PWD"

install_pkgs=true
install_lang=true
install_system=true
install_browsers=true
windows_entry=false
pin_os_age=false
os_age_epoch=""
backup_dir="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

usage() {
    cat <<'USAGE'
Usage: install.sh [-n|--no-packages] [-L|--no-lang] [-S|--no-system] [-l|--low-spec] [-w|--windows] [-a|--os-age EPOCH] [-h|--help] [PACKAGE...]

  -n, --no-packages   Skip pacman/yay installs, toolchains and first-run app setup
  -L, --no-lang       Skip rustup/ghcup/cabal toolchain setup
  -S, --no-system     Skip everything outside $HOME (grub, reboot watchdog, greetd,
                      tuigreet, power-profile helper, console font, services,
                      login shell)
  -l, --low-spec      Skip the extra browsers (Firefox, its profiles and add-ons,
                      Waterfox); qutebrowser is still installed
  -w, --windows       Add the Windows chainload entry to grub (system/grub/29_windows)
  -a, --os-age EPOCH  Pin the fastfetch "OS Age" counter to EPOCH (unix seconds)
                      from a previous install on THIS device. Off by default, so
                      other machines count from their own filesystem birth time
  -h, --help          Show this help

  PACKAGE...          Stow only these packages from home/ (default: all of them)

Existing files that would conflict with a symlink are moved into
~/.dotfiles-backup/<timestamp>/ before stowing.
USAGE
}

packages=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--no-packages) install_pkgs=false; shift ;;
        -L|--no-lang) install_lang=false; shift ;;
        -S|--no-system) install_system=false; shift ;;
        -l|--low-spec) install_browsers=false; shift ;;
        -w|--windows) windows_entry=true; shift ;;
        -a|--os-age) pin_os_age=true; os_age_epoch="${2-}"; shift; [[ $# -gt 0 ]] && shift ;;
        --os-age=*) pin_os_age=true; os_age_epoch="${1#*=}"; shift ;;
        -h|--help) usage; exit 0 ;;
        -*) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
        *) packages+=("${1%/}"); shift ;;
    esac
done

if [[ "$pin_os_age" == true && ! "$os_age_epoch" =~ ^[0-9]+$ ]]; then
    echo "--os-age takes a unix epoch, e.g. --os-age 1752856201" >&2
    exit 1
fi

if [[ $EUID -eq 0 ]]; then
    echo "run as your user, not root (it uses sudo where needed)" >&2
    exit 1
fi

if [[ ${#packages[@]} -eq 0 ]]; then
    for d in home/*/; do
        d=${d%/}; d=${d#home/}
        [[ "$d" == browsers && "$install_browsers" == false ]] && continue
        packages+=("$d")
    done
fi

# Ask for the password once and keep sudo alive: the Haskell toolchain alone
# outlasts sudo's timeout.
if [[ "$install_pkgs" == true || "$install_system" == true ]]; then
    sudo -v
    while kill -0 $$ 2>/dev/null; do sudo -n true; sleep 60; done 2>/dev/null &
fi

# PACKAGES
if [[ "$install_pkgs" == true ]]; then
    ucode=()
    case "$(grep -m1 '^vendor_id' /proc/cpuinfo)" in
        *GenuineIntel*) ucode=(intel-ucode) ;;
        *AuthenticAMD*) ucode=(amd-ucode) ;;
    esac

    mapfile -t pkgs < pkglist.txt
    sudo pacman -Syu --needed --noconfirm "${pkgs[@]}" "${ucode[@]}"

    if ! command -v yay >/dev/null; then
        tmp=$(mktemp -d)
        git clone https://aur.archlinux.org/yay.git "$tmp/yay"
        (cd "$tmp/yay" && makepkg -si --noconfirm)
        rm -rf "$tmp"
    fi

    mapfile -t aur < aurlist.txt
    yay -S --needed --noconfirm "${aur[@]}"

    # BROWSERS (qutebrowser is in pkglist.txt; these are the heavy extras)
    if [[ "$install_browsers" == true ]]; then
        sudo pacman -S --needed --noconfirm firefox
        yay -S --needed --noconfirm waterfox-bin
    fi
fi

# LANGUAGES
# clangd (clang), verible, stylua and texlive come from the package lists;
# lua_ls, basedpyright and ruff are installed through Mason further down.
export PATH="$HOME/.ghcup/bin:$HOME/.cargo/bin:$HOME/.local/bin:$PATH"

if [[ "$install_pkgs" == true && "$install_lang" == true ]]; then
    # RUST (rust-analyzer here, not the pacman one, so it matches the toolchain)
    rustup toolchain install stable --profile default
    rustup default stable
    rustup component add rust-analyzer rust-src rust-docs clippy rustfmt

    # HASKELL (ghcup-hs-bin is in aurlist.txt)
    ghcup install ghc recommended
    ghcup install cabal recommended
    ghcup install hls recommended
    ghcup set ghc recommended
    ghcup set cabal recommended
    ghcup set hls recommended

    # hlint and stylish-haskell for nvim-lint/conform, cabal-gild for .cabal files
    cabal update
    cabal install --installdir="$HOME/.local/bin" --overwrite-policy=always \
        ghcid hlint stylish-haskell cabal-gild
fi

command -v stow >/dev/null || { echo "stow is not installed" >&2; exit 1; }

# FOLDERS (the ones the configs write into)
mkdir -p ~/Downloads ~/Videos ~/Pictures/Screenshots

# BACKUP
# Move aside anything in $HOME that isn't already a link into this repo.
backup() {
    local pkg=$1 src rel target
    while IFS= read -r -d '' src; do
        rel=${src#"home/$pkg"/}
        target="$HOME/$rel"
        [[ -e "$target" || -L "$target" ]] || continue
        [[ "$(readlink -f "$target")" == "$dots/$src" ]] && continue
        mkdir -p "$backup_dir/$(dirname "$rel")"
        mv "$target" "$backup_dir/$rel"
        echo "backed up ~/$rel"
    done < <(find "home/$pkg" \( -type f -o -type l \) -print0)
}

# STOW
for pkg in "${packages[@]}"; do
    [[ -d "home/$pkg" ]] || { echo "no such package: $pkg" >&2; exit 1; }
    backup "$pkg"
    stow -R "$pkg"
    echo "stowed $pkg"
done

[[ -d "$backup_dir" ]] && echo "backups in $backup_dir"

# OS AGE
# fastfetch's "OS Age" reads this file and falls back to `stat -c %W /`, so
# only pin it when reinstalling a machine that should keep its old count.
if [[ "$pin_os_age" == true ]]; then
    f="${XDG_STATE_HOME:-$HOME/.local/state}/fastfetch/install_date"
    mkdir -p "${f%/*}"
    echo "$os_age_epoch" > "$f"
    echo "os-age: pinned to $(date -d "@$os_age_epoch" '+%Y-%m-%d')"
fi

# FIRST RUN
if [[ "$install_pkgs" == true ]]; then
    # nvim: plugins pinned to lazy-lock.json, then the Mason servers. Both
    # block when headless. Treesitter parsers compile on the first real start.
    nvim --headless "+Lazy! restore" +qa
    nvim --headless "+MasonInstall lua-language-server basedpyright ruff" +qa

    # qutebrowser: spellcheck dictionary for c.spellcheck.languages
    python /usr/share/qutebrowser/scripts/dictcli.py install en-GB
fi

# BROWSERS
# The launchers come from the browsers package; this is the part stow can't do.
stowed_browsers=false
[[ " ${packages[*]} " == *" browsers "* ]] && stowed_browsers=true
if [[ "$stowed_browsers" == true ]] && command -v firefox >/dev/null; then
    ff="$HOME/.config/mozilla/firefox"
    has_profile() {
        grep -qsx "Name=$1" "$ff/profiles.ini" "$HOME/.mozilla/firefox/profiles.ini"
    }
    # default-release only exists once Firefox has started. Start it headless
    # first so it's there, and so the first real launch can't adopt one of the
    # profiles below as the default instead.
    if ! has_profile default-release; then
        shot=$(mktemp -d)
        timeout 60 firefox --headless --screenshot "$shot/s.png" about:blank >/dev/null 2>&1 || true
        rm -rf "$shot"
    fi
    # "Firefox (Other)" gets the dotfiles config; "Firefox (Basic)" stays stock.
    for p in firefox-clone firefox-basic; do
        has_profile "$p" && continue
        env MOZ_APP_REMOTINGNAME="$p-setup" /usr/lib/firefox/firefox \
            --no-remote -CreateProfile "$p $ff/$p"
    done
    # user.js, userChrome/userContent.css and extensions.txt into profiles.txt
    ~/.local/bin/firefox-profile-setup || echo "firefox-profile-setup failed; rerun it by hand" >&2
fi
if [[ "$stowed_browsers" == true ]]; then
    # waterfox.desktop claims the http/https MIME types; keep qutebrowser default.
    xdg-settings set default-web-browser org.qutebrowser.qutebrowser.desktop
    command -v update-desktop-database >/dev/null &&
        update-desktop-database ~/.local/share/applications
    # tofi-drun caches each entry's source path; drop it so the waterfox.desktop
    # override is picked up instead of the system one.
    rm -f ~/.cache/tofi-drun
fi

[[ "$install_system" == true ]] || exit 0

# GRUB
[[ -f /etc/default/grub.orig ]] || sudo cp /etc/default/grub /etc/default/grub.orig
sudo mkdir -p /boot/grub/themes
sudo cp -r system/grub/minimal /boot/grub/themes/
sudo install -Dm644 system/grub/grub /etc/default/grub
if [[ "$windows_entry" == true ]]; then
    sudo install -Dm755 system/grub/29_windows /etc/grub.d/29_windows
fi
# Drop the "Loading Linux ..." / "Loading initial ramdisk ..." echoes. pacman
# replaces 10_linux on grub updates, so rerun `install.sh` afterwards.
sudo sed -i "/^\techo\t'\$(echo \"\$message\" | grub_quote)'\$/d" /etc/grub.d/10_linux
sudo grub-mkconfig -o /boot/grub/grub.cfg

# SYSTEMD (no "watchdog failed" hang on reboot)
sudo install -Dm644 system/systemd/99-no-reboot-watchdog.conf \
    /etc/systemd/system.conf.d/99-no-reboot-watchdog.conf
sudo systemctl daemon-reexec

# TUIGREET
# The fork pins a nightly in rust-toolchain.toml; stable builds it fine.
rustup toolchain list | grep -q '^stable' || rustup toolchain install stable --profile default
RUSTUP_TOOLCHAIN=stable cargo build --release --manifest-path system/tuigreet/Cargo.toml

# GREETD
sudo install -Dm755 system/tuigreet/target/release/tuigreet /usr/local/bin/tuigreet
sudo install -Dm755 system/greetd/sway-session /usr/local/bin/sway-session
sudo install -Dm644 system/greetd/tuigreet.toml /etc/tuigreet/config.toml
sudo install -Dm644 system/greetd/vtrgb /etc/greetd/vtrgb
sudo install -Dm755 system/greetd/greeter /etc/greetd/greeter
sudo install -Dm644 system/greetd/config.toml /etc/greetd/config.toml

# POWER PROFILES (root half of sway's power-profile-menu, passwordless)
sudo install -m 755 -o root -g root home/sway/.config/sway/scripts/power-profile-helper \
    /usr/local/bin/power-profile
rule=$(mktemp)
echo "$USER ALL=(root) NOPASSWD: /usr/local/bin/power-profile" > "$rule"
sudo visudo -cf "$rule" >/dev/null
sudo install -m 440 -o root -g root "$rule" /etc/sudoers.d/power-profile
rm -f "$rule"

# CONSOLE FONT (the greeter is unreadable at the stock 8x16)
if grep -q '^FONT=' /etc/vconsole.conf 2>/dev/null; then
    sudo sed -i 's|^FONT=.*|FONT=ter-v32n|' /etc/vconsole.conf
else
    echo 'FONT=ter-v32n' | sudo tee -a /etc/vconsole.conf >/dev/null
fi

# SERVICES
sudo systemctl enable --now NetworkManager bluetooth
sudo systemctl enable greetd

# SHELL (nu stays installed; run `nu` to drop into it)
[[ "$(getent passwd "$USER" | cut -d: -f7)" == /usr/bin/zsh ]] || sudo chsh -s /usr/bin/zsh "$USER"

cat <<'EOF'

Done. The steps a script can't do are in INSTALL.md -- in particular, test the
greeter on a spare VT before rebooting:
    setvtrgb /etc/greetd/vtrgb && /usr/local/bin/tuigreet --mock
EOF
