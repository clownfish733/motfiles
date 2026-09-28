# newtex [dir] [tmpl]       scaffold dir/main.tex from tmpl (default: article)
# newtex -l                 list templates
# newtex -s <name> [file]   save file (default main.tex) as template <name>

const tdir = ("~/.config/tex/templates" | path expand)

def templates [] {
    glob ($tdir | path join "*.tex") | each { path parse | get stem } | sort
}

# Scaffold a LaTeX project from a template in ~/.config/tex/templates
export def --env main [
    dir?: directory                   # target dir (with -s: the file to save)
    tmpl?: string@templates           # template name
    --list (-l)                       # list available templates
    --save (-s): string               # save a file as a new template with this name
] {
    if $list {
        let t = templates
        if ($t | is-empty) { error make -u {msg: $"no templates in ($tdir)"} }
        return $t
    }

    if $save != null {
        let src = $dir | default main.tex
        if not ($src | path exists) { error make -u {msg: $"no such file: ($src)"} }
        mkdir $tdir
        cp -i $src ($tdir | path join $"($save).tex")
        print $"saved template: ($save)"
        return
    }

    let dir = $dir | default .
    let tmpl = $tmpl | default article
    let src = $tdir | path join $"($tmpl).tex"
    if not ($src | path exists) {
        let avail = templates | str join " " | default -e none
        error make -u {msg: $"no template: ($tmpl)\navailable: ($avail)"}
    }
    mkdir $dir
    cp -n $src ($dir | path join main.tex)
    try { cp -n ~/.config/tex/gitignore ($dir | path join .gitignore) }
    cd $dir
    nvim main.tex
}
