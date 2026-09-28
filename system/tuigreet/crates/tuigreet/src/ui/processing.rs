use std::error::Error;

use tui::{
  layout::{Alignment, Constraint, Direction, Layout, Rect},
  text::Span,
  widgets::Paragraph,
};

use crate::{
  Greeter,
  ui::{Frame, common::bevel, util::get_rect_bounds},
};

pub fn draw_with_area(
  greeter: &mut Greeter,
  f: &mut Frame,
  area: Rect,
) -> Result<(u16, u16), Box<dyn Error>> {
  let (x, y, width, height) = get_rect_bounds(greeter, area, 1);

  let container = Rect::new(x, y, width, height);

  bevel::render(greeter, f, container, bevel::block(&greeter.theme));

  let container_padding = greeter.container_padding();
  let frame = Rect::new(
    x.saturating_add(container_padding),
    y.saturating_add(container_padding),
    width.saturating_sub(container_padding.saturating_mul(2)),
    height.saturating_sub(container_padding.saturating_mul(2)),
  );

  let constraints = [Constraint::Length(1)];

  let chunks = Layout::default()
    .direction(Direction::Vertical)
    .constraints(constraints.as_ref())
    .split(frame);
  let text = Span::from(fl!("wait"));
  let paragraph = Paragraph::new(text).alignment(Alignment::Center);

  f.render_widget(paragraph, chunks[0]);

  Ok((1, 1))
}
