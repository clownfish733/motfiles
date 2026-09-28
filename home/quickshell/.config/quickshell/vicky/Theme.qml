pragma Singleton

import Quickshell
import QtQuick

// Black, outlined in #993954 — the same skin quicky wears, so the picker
// reads as another drawer of the same shell rather than a second program.
Singleton {
    id: root

    // ── palette ─────────────────────────────────────────────────────────
    readonly property color bg:      "#000000"
    readonly property color outline: "#993954"

    readonly property color accent:      outline
    readonly property color accentSoft:  Qt.rgba(outline.r, outline.g, outline.b, 0.28)
    readonly property color accentFaint: Qt.rgba(outline.r, outline.g, outline.b, 0.14)

    // The outline is a dark wine, which disappears on top of a bright poster
    // frame. Marks drawn over an image use this instead.
    readonly property color accentBright: Qt.lighter(outline, 1.7)

    readonly property color fg:      "#e6dde0"
    readonly property color fgDim:   "#8b7076"
    readonly property color fgFaint: "#57444a"

    readonly property color warn: "#d8a05a"
    readonly property color crit: "#d2536a"
    readonly property color good: "#7fb069"

    // The screen behind the card. Dark enough to lift the card off a bright
    // video, light enough that you can still see what you were doing.
    readonly property color scrim: "#a6000000"

    // ── metrics ─────────────────────────────────────────────────────────
    readonly property int border: 1
    readonly property int cardRadius: 15
    readonly property int cardWidth: 700
    readonly property int cardPadding: 12

    // The card is sized by its contents; this is only the ceiling the list
    // stops growing at, after which it scrolls.
    readonly property int listMaxHeight: 520

    // The one number that sets how big a row is: the poster frame is 16:9 off
    // this, and the row is the frame plus air.
    readonly property int thumbHeight: 120
    readonly property int thumbWidth: Math.round(thumbHeight * 16 / 9)
    readonly property int rowHeight: thumbHeight + 12

    readonly property int rowRadius: 8

    // ── type ────────────────────────────────────────────────────────────
    readonly property string font: "Hack Nerd Font"
    readonly property int textSize: 13
    readonly property int iconSize: 16
    readonly property int smallSize: 11

    readonly property int anim: 150
}
