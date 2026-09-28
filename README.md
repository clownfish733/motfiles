# motfiles

Dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

Fresh machine: see [INSTALL.md](INSTALL.md).

```
home/     stow packages, each one mirroring $HOME
system/   things installed outside $HOME by install.sh (grub, greetd, tuigreet)
```

```sh
./install.sh                 # packages, toolchains, stow everything, then grub/greetd/tuigreet/shell
./install.sh -w              # same, plus the Windows grub entry (tower)
./install.sh -L              # skip the rustup/ghcup/cabal toolchain setup
./install.sh -a 1752856201   # reinstall: keep fastfetch's "OS Age" counting from this epoch
./install.sh -l              # low-spec machine: no Firefox/Waterfox, browsers package not stowed
./install.sh -n -S           # stow only: no installs, nothing outside $HOME
./install.sh -n -S nvim sway # stow just these packages
```

Conflicting files already in `$HOME` are moved to
`~/.dotfiles-backup/<timestamp>/` first. `.stowrc` sets `--dir=home`,
`--target=~` and `--no-folding`, so plain `stow <pkg>` works from the repo root
and only files are symlinked, never whole directories — runtime state (shell
history, lazy.nvim data, …) stays out of the repo.

## home/

| package | what |
| --- | --- |
| sway | WM config + status/menu scripts, awww wallpaper daemon. `apps.d/*` is included for per-machine overrides |
| quickshell | `wicky` wallpaper picker (`SUPER+W`), `vicky` video picker for `~/Videos` (`SUPER+V`) |
| zsh | login shell: `.zshrc`, completions, fzf presets |
| nushell | kept around; run `nu` to switch into it |
| foot, tmux, starship | terminal, multiplexer, prompt |
| nvim | lazy.nvim config |
| tofi, mako | launcher, notifications |
| qutebrowser | browser (see its README for first-run steps) |
| browsers | Firefox config (`user.js`, toolbars-at-the-bottom `userChrome.css`, add-on list) applied by `firefox-profile-setup`; a sway snippet (`apps.d/browsers`) putting Firefox on `$mod+b` and qutebrowser on `$mod+Ctrl+b`; launchers for `Firefox (Other)` (second configured profile) and `Firefox (Basic)` (stock); a Waterfox wrapper that removes the empty `~/Waterfox` it makes on every start. See `~/.config/firefox-profile/README.md`. Skipped with `-l` |
| btop, fastfetch | system monitors |
| tex, clang-format | latexmk + `newtex` templates, `.clang-format` |
| newt | whiptail/nmtui palette (`NEWT_COLORS_FILE`, set by zsh and nu) |
| git, intellij | `.gitconfig`, `.ideavimrc` |
| wallpapers | `~/Pictures/Wallpapers` (what wicky picks from) |

## Language tooling

| language | what install.sh does | used by nvim as |
| --- | --- | --- |
| Rust | `rustup` stable + rust-analyzer, rust-src, rust-docs, clippy, rustfmt | rustaceanvim |
| Haskell | `ghcup` (AUR) → recommended ghc, cabal, hls; `cabal install` ghcid, hlint, stylish-haskell, cabal-gild into `~/.local/bin` | haskell-tools, nvim-lint, conform |
| C/C++ | `clang` (clangd, clang-format) | `lsp/clangd.lua` |
| SystemVerilog | `verible-bin` (AUR) | `lsp/verible.lua` |
| Lua, Python | `stylua`; lua_ls, basedpyright, ruff via Mason on first nvim start | conform, Mason |
| LaTeX | texlive + latexmk, zathura | vimtex |

## system/

- **grub** — `minimal` theme into `/boot/grub/themes`, `grub` to
  `/etc/default/grub` (the original is kept as `/etc/default/grub.orig`),
  `29_windows` only with `-w`.
- **tuigreet** — vendored fork, built with cargo and installed to
  `/usr/local/bin/tuigreet`. The packaged `greetd-tuigreet` stays installed as
  a fallback.
- **greetd** — greeter wrapper, console palette and config; logs in to
  `sway-session`. See `system/greetd/README.md` for why, and test the greeter
  on a spare VT before rebooting.
