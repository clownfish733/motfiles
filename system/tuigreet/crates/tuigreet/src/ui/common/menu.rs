use std::{borrow::Cow, error::Error};

use tui::{prelude::Rect, text::Span, widgets::Paragraph};

use super::{bevel, style::Theme};
use crate::{
  Greeter,
  ui::{
    Frame,
    util::{get_rect_bounds, titleize},
  },
};

/// Marks the highlighted row. Every row is indented by its width so the
/// names stay in one column whether or not they are selected.
///
/// U+25B6 rather than the daintier U+25B8, which the Linux console fonts
/// do not carry.
const CURSOR: &str = "\u{25B6} ";
const NO_CURSOR: &str = "  ";

/// Item that can be displayed in a menu.
pub trait MenuItem {
  /// Format the item for display.
  fn format(&self) -> Cow<'_, str>;
}

/// Generic menu widget for displaying selectable options.
#[derive(Default)]
pub struct Menu<T>
where
  T: MenuItem,
{
  /// Menu title
  pub title:    String,
  /// List of menu items
  pub options:  Vec<T>,
  /// Currently selected index
  pub selected: usize,
}

impl<T> Menu<T>
where
  T: MenuItem,
{
  /// Draw the menu within a specified area.
  ///
  /// # Returns
  ///
  /// Tuple of `(cursor_x, cursor_y)` for the selected item
  pub fn draw_with_area(
    &self,
    greeter: &Greeter,
    f: &mut Frame,
    area: Rect,
  ) -> Result<(u16, u16), Box<dyn Error>> {
    let theme = &greeter.theme;

    let size = area;
    let (x, y, width, height) =
      get_rect_bounds(greeter, size, self.options.len());

    let container = Rect::new(x, y, width, height);
    let title = Span::from(titleize(&self.title));

    // The block goes down first: it paints the container background across
    // the whole area, which would otherwise flatten the selection bar.
    bevel::render(greeter, f, container, bevel::block(theme).title(title));

    // Rows are inset a column from the border on both sides, so the bar
    // under the selected one reads as a plate rather than as a fill.
    let inner = width.saturating_sub(4);

    for (index, option) in self.options.iter().enumerate() {
      let selected = self.selected == index;
      let cursor = if selected { CURSOR } else { NO_CURSOR };
      let label = format!(
        "{cursor}{:1$}",
        option.format(),
        inner.saturating_sub(2) as usize
      );

      let row = y.saturating_add(2).saturating_add(index as u16);
      let frame = Rect::new(x.saturating_add(2), row, inner, 1);
      let option = Paragraph::new(self.get_option(theme, label, selected));

      f.render_widget(option, frame);
    }

    Ok((1, 1))
  }

  fn get_option<'g, S>(
    &self,
    theme: &Theme,
    name: S,
    selected: bool,
  ) -> Span<'g>
  where
    S: Into<String>,
  {
    if selected {
      Span::styled(name.into(), theme.selection())
    } else {
      Span::from(name.into())
    }
  }
}
