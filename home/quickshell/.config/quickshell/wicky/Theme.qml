pragma Singleton

import Quickshell
import QtQuick

// Every colour and metric lives here. No raw hex anywhere else.
Singleton {
    // ── accents ─────────────────────────────────────────────────────────
    // The ring around the selected preview, and nothing else — the picker
    // draws no plate, so these are the only chrome colours in the config.
    readonly property color accent:   "#d44a6e"
    readonly property color ringDim:  "#00000000"
    readonly property color shadow:   "#66000000"

    // Previews are opaque, so the ground under one carrying an alpha channel
    // of its own and the black the falloff paints over it are one colour.
    readonly property color previewBase: "#ff000000"

    // ── preview geometry ────────────────────────────────────────────────
    // A cell is sized for the *selected* preview, and the others shrink inside
    // it. Sizing the other way round would let the focused preview overflow
    // into its neighbours.
    readonly property int cellWidth:   300
    readonly property int cellHeight:  188   // 16:10, matching the panel
    readonly property int gap:          18
    readonly property int radius:       14

    // How many previews are on screen at rest. Odd, so one is dead centre:
    // the window is the centre preview plus `visible / 2` either side.
    readonly property int visible:      5

    // Falloff per step away from centre. Scale stops shrinking at the edge of
    // the window so the outermost pair match; the dimming keeps going, which
    // is what darkens a preview out as it leaves.
    readonly property real scaleStep:   0.11
    readonly property real fadeStep:    0.30

    readonly property int ringWidth:    2

    // ── motion ──────────────────────────────────────────────────────────
    readonly property int anim:      190   // per-preview scale/fade
    readonly property int scroll:    260   // strip slide between previews
    readonly property int openAnim:  220
    readonly property int closeAnim: 140
}
