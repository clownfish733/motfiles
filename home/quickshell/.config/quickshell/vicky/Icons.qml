pragma Singleton

import Quickshell
import QtQuick

// Nerd Font (Material Design range) glyphs, kept as codepoints so the source
// stays greppable and does not depend on the editor rendering private-use
// characters. Every glyph below is present in Hack Nerd Font.
Singleton {
    id: root

    function cp(code) { return String.fromCodePoint(code) }

    // The clapperboard is the picker's own mark; rows get the play triangle
    // and the folder, which are the only two things at 16px that cannot be
    // mistaken for each other.
    readonly property string film:   cp(0xf0381)  // movie
    readonly property string video:  cp(0xf040a)  // play
    readonly property string folder: cp(0xf0770)  // folder-open
    readonly property string download: cp(0xf01da)
    readonly property string search:   cp(0xf0349)
    readonly property string trash:    cp(0xf01b4)
    readonly property string link:     cp(0xf0337)
    readonly property string alert:    cp(0xf0026)
    readonly property string check:    cp(0xf012c)
}
