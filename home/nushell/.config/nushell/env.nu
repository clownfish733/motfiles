# env.nu — loaded before config.nu

use std/util "path add"

path add ($env.HOME | path join .ghcup/bin)
path add ($env.HOME | path join .local/bin)
path add ($env.HOME | path join .cargo/bin)

$env.EDITOR = "nvim"
$env.NEWT_COLORS_FILE = ($env.HOME | path join .config/newt/colors)

# Pink bold dirs, same as the old EZA_COLORS. Nu's builtin `ls` reads LS_COLORS.
$env.EZA_COLORS = "di=1;38;2;240;150;170"
$env.LS_COLORS = "di=1;38;2;240;150;170:ln=1;36:ex=1;32:so=1;35:pi=33:bd=1;33:cd=1;33:or=31"

$env.LANG = "en_GB.UTF-8"

# Generate prompt/completer init scripts into the vendor autoload dir, which
# nu sources automatically after config.nu. Skipped if the tool isn't installed.
let autoload = ($nu.data-dir | path join vendor/autoload)
mkdir $autoload

if (which starship | is-not-empty) {
    starship init nu | save -f ($autoload | path join starship.nu)
}
if (which carapace | is-not-empty) {
    carapace _carapace nushell | save -f ($autoload | path join carapace.nu)
}
