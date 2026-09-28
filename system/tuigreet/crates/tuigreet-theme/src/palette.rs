//! The stock palette.
//!
//! These are the same colours the rest of the desktop wears — the quickshell
//! bar and its menus, the wallpaper picker, fuzzel — so the greeter reads as
//! the first screen of that shell rather than as a separate program that
//! happens to run first. Black ground, wine outline, warm off-white text.
//!
//! Mirrors `~/.config/quickshell/quicky/Theme.qml`; if the shell's hue moves,
//! move it here too.

use tui::style::Color;

/// Ground under every container.
pub const BACKGROUND: Color = Color::Rgb(0x00, 0x00, 0x00);

/// The wine outline everything is drawn with.
pub const OUTLINE: Color = Color::Rgb(0x99, 0x39, 0x54);

/// Outline lifted towards the light — the top and left of a raised bevel.
pub const OUTLINE_LIGHT: Color = Color::Rgb(0xC7, 0x4E, 0x6F);

/// Outline dropped into shade — the bottom and right of a raised bevel.
pub const OUTLINE_DARK: Color = Color::Rgb(0x4D, 0x1C, 0x2A);

/// Body text.
pub const FG: Color = Color::Rgb(0xE6, 0xDD, 0xE0);

/// Labels and other second-rank text.
pub const FG_DIM: Color = Color::Rgb(0x8B, 0x70, 0x76);

/// The brighter tint of the outline, used where the wine would disappear.
pub const ACCENT: Color = Color::Rgb(0xD4, 0x4A, 0x6E);

/// Cast under containers, over whatever is behind them.
pub const SHADOW: Color = Color::Rgb(0x0A, 0x07, 0x08);
