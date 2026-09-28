FILE_LOCATION: this dir -> ~/.config/qutebrowser (not stowed yet)

    config.py   options, search engines, aliases
    theme.py    Monokai Pro base + rose accents
    keys.py     bindings

`config.load_autoconfig(False)` is set, so `:set` is session-only -- edit the
files, then `:config-source`.

Setup not covered by the files:

    :adblock-update                                    # first run, fetches the lists
    python /usr/share/qutebrowser/scripts/dictcli.py list
    python /usr/share/qutebrowser/scripts/dictcli.py install en-GB

`,r` (readability-js) needs three global node modules:

    sudo npm install -g @mozilla/readability jsdom qutejs

`qt.environ` in config.py already points NODE_PATH at /usr/lib/node_modules
(`npm root -g`), so nothing else is needed.

To move into Dots: `Dots/qutebrowser/.config/qutebrowser/`, add `qutebrowser`
to `stow.txt`, and point `apps.browser` in `hypr/.config/hypr/apps.lua` at it.
