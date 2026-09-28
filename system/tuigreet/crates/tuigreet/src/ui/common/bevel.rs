//! Container chrome: the block, the bevel shaded onto its edges, and the
//! shadow it casts on whatever is behind it.
//!
//! ratatui paints a block's border in one flat colour, which on a black
//! ground reads as a wireframe rather than as a surface sitting on top of
//! one. So the block is drawn normally and its edges are then repainted in
//! two tints of the border colour — light where the light source hits, dark
//! where it does not — leaving the two corners where the tints meet on the
//! base colour, which is what makes the join read as a mitre rather than a
//! step.
//!
//! Only box-drawing glyphs are repainted, so a block's title keeps its own
//! colour despite sharing a row with the top border.

use tui::{
  buffer::Buffer,
  layout::Rect,
  style::Color,
  widgets::{Block, Borders, Clear},
};
use tuigreet_theme::{Bevel, Theme};

use crate::{
  Greeter,
  ui::{Frame, common::style::Themed},
};

/// The Unicode box-drawing block, which covers every [`BorderType`] ratatui
/// can draw.
///
/// [`BorderType`]: tui::widgets::BorderType
const BOX_DRAWING: std::ops::RangeInclusive<char> = '\u{2500}'..='\u{257F}';

/// A themed container, ready for a title and a render.
pub fn block<'a>(theme: &Theme) -> Block<'a> {
  Block::default()
    .title_style(theme.of(&[Themed::Title]))
    .style(theme.of(&[Themed::Container]))
    .borders(Borders::ALL)
    .border_type(theme.border_type())
    .border_style(theme.of(&[Themed::Border]))
}

/// Draw a container into `area`: shadow underneath, then the block, then the
/// bevel over its edges.
///
/// Call this before drawing the container's contents — the block paints its
/// background across the whole area and would otherwise flatten anything
/// already there.
pub fn render(greeter: &Greeter, f: &mut Frame, area: Rect, block: Block<'_>) {
  // Wipe any animation pixels from the container area first; ratatui's Block
  // patches style only and would leave the fire glyphs visible underneath.
  if greeter.animation.is_some() {
    f.render_widget(Clear, area);
  }

  shadow(f, area, &greeter.theme);
  f.render_widget(block, area);
  shade(f.buffer_mut(), area, &greeter.theme);
}

/// Lay a one-cell shadow down the right flank and along the bottom, offset a
/// cell towards the light source's opposite corner.
fn shadow(f: &mut Frame, area: Rect, theme: &Theme) {
  let Some(color) = theme.shadow() else {
    return;
  };

  if area.is_empty() {
    return;
  }

  let screen = f.area();
  let buf = f.buffer_mut();

  let flank = (area.top() + 1..=area.bottom()).map(|y| (area.right(), y));
  let foot = (area.left() + 1..area.right()).map(|x| (x, area.bottom()));

  for (x, y) in flank.chain(foot) {
    if x < screen.right()
      && y < screen.bottom()
      && let Some(cell) = buf.cell_mut((x, y))
    {
      cell.set_symbol(" ").set_bg(color);
    }
  }
}

/// Repaint the block's edges into a lit side and a shaded side.
fn shade(buf: &mut Buffer, area: Rect, theme: &Theme) {
  let (light, dark) = match theme.bevel() {
    Bevel::None => return,
    Bevel::Raised => (theme.bevel_light(), theme.bevel_dark()),
    Bevel::Sunken => (theme.bevel_dark(), theme.bevel_light()),
  };

  if area.width < 2 || area.height < 2 {
    return;
  }

  let (left, top) = (area.left(), area.top());
  let (right, bottom) = (area.right() - 1, area.bottom() - 1);

  for x in left..=right {
    tint(buf, (x, top), light);
    tint(buf, (x, bottom), dark);
  }

  for y in top..=bottom {
    tint(buf, (left, y), light);
    tint(buf, (right, y), dark);
  }

  // Where the lit and shaded edges meet, the base colour reads as the mitre
  // between them.
  let base = theme.of(&[Themed::Border]).fg;

  tint(buf, (right, top), base);
  tint(buf, (left, bottom), base);
}

/// Recolour one border glyph, leaving titles and other content alone.
fn tint(buf: &mut Buffer, position: (u16, u16), color: Option<Color>) {
  let Some(color) = color else {
    return;
  };

  if let Some(cell) = buf.cell_mut(position)
    && is_border_glyph(cell.symbol())
  {
    cell.set_fg(color);
  }
}

fn is_border_glyph(symbol: &str) -> bool {
  let mut chars = symbol.chars();

  matches!(
    (chars.next(), chars.next()),
    (Some(glyph), None) if BOX_DRAWING.contains(&glyph)
  )
}
