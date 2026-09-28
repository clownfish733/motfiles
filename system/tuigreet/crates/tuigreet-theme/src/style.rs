use std::str::FromStr;

use tui::{
  style::{Color, Modifier, Style},
  widgets::BorderType,
};

use crate::palette;

/// Color component (foreground or background)
#[derive(Clone)]
enum Component {
  Bg,
  Fg,
}

/// UI element that can be themed
pub enum Themed {
  Container,
  Time,
  Text,
  Border,
  Title,
  Greet,
  Prompt,
  Input,
  Action,
  ActionButton,
  Selection,
}

/// How a container's edges are shaded.
///
/// The light source sits off the top-left, so a `Raised` panel catches the
/// light on its top and left edges and pools shade along the bottom and
/// right. `Sunken` swaps the two, which reads as a well pressed into the
/// screen.
#[derive(Clone, Copy, Default, PartialEq, Eq, Debug)]
pub enum Bevel {
  /// Flat, single-colour border — how ratatui draws a block by default.
  None,
  /// Lit from the top-left; the panel sits on top of the screen.
  #[default]
  Raised,
  /// Lit from the bottom-right; the panel is cut into the screen.
  Sunken,
}

impl FromStr for Bevel {
  type Err = ();

  fn from_str(value: &str) -> Result<Self, Self::Err> {
    match value.trim().to_lowercase().as_str() {
      "none" | "off" | "flat" | "false" => Ok(Self::None),
      "raised" | "on" | "true" => Ok(Self::Raised),
      "sunken" | "inset" => Ok(Self::Sunken),
      _ => Err(()),
    }
  }
}

/// Which glyph set the container borders are drawn with.
///
/// The default is deliberately the plain one. The greeter's real home is the
/// Linux virtual console, and no console font on the system carries the
/// rounded corners at U+256D-256F — they come out blank. Rounded matches the
/// shell's radius better, so it stays available for anyone previewing under a
/// terminal emulator with a real font.
#[derive(Clone, Copy, Default, PartialEq, Eq, Debug)]
pub enum BorderKind {
  #[default]
  Plain,
  Rounded,
  Thick,
  Double,
}

impl BorderKind {
  #[must_use]
  pub const fn border_type(self) -> BorderType {
    match self {
      Self::Plain => BorderType::Plain,
      Self::Rounded => BorderType::Rounded,
      Self::Thick => BorderType::Thick,
      Self::Double => BorderType::Double,
    }
  }
}

impl FromStr for BorderKind {
  type Err = ();

  fn from_str(value: &str) -> Result<Self, Self::Err> {
    match value.trim().to_lowercase().as_str() {
      "plain" | "square" | "sharp" => Ok(Self::Plain),
      "rounded" | "round" => Ok(Self::Rounded),
      "thick" | "bold" => Ok(Self::Thick),
      "double" => Ok(Self::Double),
      _ => Err(()),
    }
  }
}

/// Color theme for all UI elements
pub struct Theme {
  container: Option<(Component, Color)>,
  time:      Option<(Component, Color)>,
  text:      Option<(Component, Color)>,
  border:    Option<(Component, Color)>,
  title:     Option<(Component, Color)>,
  greet:     Option<(Component, Color)>,
  prompt:    Option<(Component, Color)>,
  input:     Option<(Component, Color)>,
  action:    Option<(Component, Color)>,
  button:    Option<(Component, Color)>,
  selection: Option<(Component, Color)>,

  bevel_light: Option<Color>,
  bevel_dark:  Option<Color>,
  shadow:      Option<Color>,

  bevel:       Bevel,
  border_kind: BorderKind,
}

impl Default for Theme {
  /// The desktop palette, so an unconfigured greeter already matches the
  /// shell it hands off to. See [`crate::palette`].
  fn default() -> Self {
    use Component::{Bg, Fg};

    Self {
      container: Some((Bg, palette::BACKGROUND)),
      time:      Some((Fg, palette::FG_DIM)),
      text:      Some((Fg, palette::FG)),
      border:    Some((Fg, palette::OUTLINE)),
      title:     Some((Fg, palette::ACCENT)),
      greet:     Some((Fg, palette::FG)),
      prompt:    Some((Fg, palette::FG_DIM)),
      input:     Some((Fg, palette::FG)),
      action:    Some((Fg, palette::FG_DIM)),
      button:    Some((Fg, palette::OUTLINE)),
      selection: Some((Bg, palette::OUTLINE)),

      bevel_light: Some(palette::OUTLINE_LIGHT),
      bevel_dark:  Some(palette::OUTLINE_DARK),
      shadow:      Some(palette::SHADOW),

      bevel:       Bevel::default(),
      border_kind: BorderKind::default(),
    }
  }
}

impl Theme {
  /// Parse theme from CLI format string.
  ///
  /// # Format
  ///
  /// Semicolon-separated key=value pairs:
  /// "container=black;text=white;border=blue"
  ///
  /// Most keys take a colour. `bevel` takes `raised`, `sunken` or `none`,
  /// `borders` takes `plain`, `rounded`, `thick` or `double`, and `shadow`
  /// additionally accepts `none`.
  ///
  /// # Arguments
  ///
  /// * `spec` - Theme specification string
  ///
  /// # Returns
  ///
  /// Theme with parsed colors, falling back to the stock palette for
  /// anything the spec does not mention
  #[must_use]
  pub fn parse(spec: &str) -> Self {
    use Component::{Bg, Fg};

    let directives = spec
      .split(';')
      .filter_map(|directive| directive.split_once('='));
    let mut style = Self::default();

    // A caller who recolours the border but says nothing about the bevel
    // wants the bevel to follow it, not to keep the stock wine tints.
    let mut border_given = false;
    let mut light_given = false;
    let mut dark_given = false;

    for (key, value) in directives {
      let key = key.trim();
      let value = value.trim();

      match key {
        "bevel" => {
          if let Ok(bevel) = Bevel::from_str(value) {
            style.bevel = bevel;
          }
          continue;
        },

        "borders" | "border_style" | "border-style" => {
          if let Ok(kind) = BorderKind::from_str(value) {
            style.border_kind = kind;
          }
          continue;
        },

        "shadow" if Bevel::from_str(value) == Ok(Bevel::None) => {
          style.shadow = None;
          continue;
        },

        _ => {},
      }

      if let Ok(color) = Color::from_str(value) {
        match key {
          "container" => style.container = Some((Bg, color)),
          "time" => style.time = Some((Fg, color)),
          "text" => style.text = Some((Fg, color)),
          "border" => {
            style.border = Some((Fg, color));
            border_given = true;
          },
          "title" => style.title = Some((Fg, color)),
          "greet" => style.greet = Some((Fg, color)),
          "prompt" => style.prompt = Some((Fg, color)),
          "input" => style.input = Some((Fg, color)),
          "action" => style.action = Some((Fg, color)),
          "button" => style.button = Some((Fg, color)),
          "selection" => style.selection = Some((Bg, color)),
          "bevel_light" | "bevel-light" => {
            style.bevel_light = Some(color);
            light_given = true;
          },
          "bevel_dark" | "bevel-dark" => {
            style.bevel_dark = Some(color);
            dark_given = true;
          },
          "shadow" => style.shadow = Some(color),
          _ => {},
        }
      }
    }

    style.derive_bevel(border_given, light_given, dark_given);
    style
  }

  /// Re-derive the bevel tints from the border colour when the caller moved
  /// the border but left the tints alone.
  fn derive_bevel(
    &mut self,
    border_given: bool,
    light_given: bool,
    dark_given: bool,
  ) {
    let Some((_, border)) = self.border else {
      return;
    };

    if border_given && !light_given {
      self.bevel_light = Some(lighten(border));
    }
    if border_given && !dark_given {
      self.bevel_dark = Some(darken(border));
    }
  }

  /// Builds a style by applying each target's configured color in order.
  ///
  /// Later targets override earlier targets when they affect the same style
  /// property.
  #[must_use]
  pub fn of(&self, targets: &[Themed]) -> Style {
    targets
      .iter()
      .fold(Style::default(), |style, target| self.apply(style, target))
  }

  /// How a selected menu row or a pressed status-bar key is painted: the
  /// accent as a bar with the body text on top, or plain reverse video when
  /// the theme names no selection colour.
  #[must_use]
  pub fn selection(&self) -> Style {
    match self.selection {
      Some(_) => self.of(&[Themed::Text, Themed::Selection]),
      None => Style::default().add_modifier(Modifier::REVERSED),
    }
  }

  /// The status bar's key caps — `ESC`, `F2` — drawn as a filled pill in the
  /// button colour, which is what `button` has always meant even when it was
  /// spelled as reverse video.
  #[must_use]
  pub fn pill(&self) -> Style {
    match self.button {
      Some((_, color)) => self.of(&[Themed::Text]).bg(color),
      None => Style::default().add_modifier(Modifier::REVERSED),
    }
  }

  /// Which glyph set container borders are drawn with.
  #[must_use]
  pub const fn border_type(&self) -> BorderType {
    self.border_kind.border_type()
  }

  /// Whether and which way containers are bevelled.
  #[must_use]
  pub const fn bevel(&self) -> Bevel {
    self.bevel
  }

  /// The lit edge of a bevel.
  #[must_use]
  pub const fn bevel_light(&self) -> Option<Color> {
    self.bevel_light
  }

  /// The shaded edge of a bevel.
  #[must_use]
  pub const fn bevel_dark(&self) -> Option<Color> {
    self.bevel_dark
  }

  /// The drop shadow cast under a container, if any.
  #[must_use]
  pub const fn shadow(&self) -> Option<Color> {
    self.shadow
  }

  const fn apply(&self, style: Style, target: &Themed) -> Style {
    use Themed::{
      Action,
      ActionButton,
      Border,
      Container,
      Greet,
      Input,
      Prompt,
      Selection,
      Text,
      Time,
      Title,
    };

    let color = match target {
      Container => &self.container,
      Time => &self.time,
      Text => &self.text,
      Border => &self.border,
      Title => &self.title,
      Greet => &self.greet,
      Prompt => &self.prompt,
      Input => &self.input,
      Action => &self.action,
      ActionButton => &self.button,
      Selection => &self.selection,
    };

    match color {
      Some((component, color)) => {
        match component {
          Component::Fg => style.fg(*color),
          Component::Bg => style.bg(*color),
        }
      },

      None => style,
    }
  }
}

/// Scale a channel, saturating at full brightness.
const fn scale(channel: u8, percent: u16) -> u8 {
  let scaled = channel as u16 * percent / 100;

  if scaled > 255 { 255 } else { scaled as u8 }
}

/// The same hue turned up towards the light. Terminal colours outside the
/// truecolour range have no arithmetic, so they step to their bright
/// counterpart instead.
const fn lighten(color: Color) -> Color {
  match color {
    Color::Rgb(r, g, b) => {
      Color::Rgb(scale(r, 135), scale(g, 135), scale(b, 135))
    },
    Color::Black => Color::DarkGray,
    Color::DarkGray => Color::Gray,
    Color::Gray => Color::White,
    Color::Red => Color::LightRed,
    Color::Green => Color::LightGreen,
    Color::Yellow => Color::LightYellow,
    Color::Blue => Color::LightBlue,
    Color::Magenta => Color::LightMagenta,
    Color::Cyan => Color::LightCyan,
    other => other,
  }
}

/// The same hue turned down into shade. The eight base ANSI colours have
/// nothing below them, so they stay put rather than collapsing to black.
const fn darken(color: Color) -> Color {
  match color {
    Color::Rgb(r, g, b) => Color::Rgb(scale(r, 50), scale(g, 50), scale(b, 50)),
    Color::White => Color::Gray,
    Color::Gray => Color::DarkGray,
    Color::DarkGray => Color::Black,
    Color::LightRed => Color::Red,
    Color::LightGreen => Color::Green,
    Color::LightYellow => Color::Yellow,
    Color::LightBlue => Color::Blue,
    Color::LightMagenta => Color::Magenta,
    Color::LightCyan => Color::Cyan,
    other => other,
  }
}

#[cfg(test)]
mod test {
  use tui::style::Color;

  use super::{Bevel, BorderKind, Theme};
  use crate::palette;

  #[test]
  fn unspecified_components_keep_the_stock_palette() {
    let theme = Theme::parse("text=white");

    assert_eq!(theme.of(&[super::Themed::Text]).fg, Some(Color::White));
    assert_eq!(theme.bevel_light(), Some(palette::OUTLINE_LIGHT));
    assert_eq!(theme.bevel(), Bevel::Raised);
    assert_eq!(theme.border_type(), BorderKind::Plain.border_type());
  }

  #[test]
  fn a_new_border_drags_the_bevel_tints_with_it() {
    let theme = Theme::parse("border=#00AAFF");

    assert_eq!(theme.bevel_light(), Some(Color::Rgb(0x00, 0xE5, 0xFF)));
    assert_eq!(theme.bevel_dark(), Some(Color::Rgb(0x00, 0x55, 0x7F)));
  }

  #[test]
  fn explicit_tints_survive_a_new_border() {
    let theme = Theme::parse("border=#00AAFF;bevel_light=red;bevel_dark=blue");

    assert_eq!(theme.bevel_light(), Some(Color::Red));
    assert_eq!(theme.bevel_dark(), Some(Color::Blue));
  }

  #[test]
  fn ansi_borders_step_to_their_bright_counterpart() {
    // The eight base colours have nothing below them, so the shaded edge
    // stays on the border colour rather than collapsing to black.
    let theme = Theme::parse("border=red");

    assert_eq!(theme.bevel_light(), Some(Color::LightRed));
    assert_eq!(theme.bevel_dark(), Some(Color::Red));
  }

  #[test]
  fn bevel_and_borders_take_words_rather_than_colors() {
    let theme = Theme::parse("bevel=sunken;borders=double;shadow=none");

    assert_eq!(theme.bevel(), Bevel::Sunken);
    assert_eq!(theme.border_type(), BorderKind::Double.border_type());
    assert_eq!(theme.shadow(), None);
  }

  #[test]
  fn unparseable_values_leave_the_default_alone() {
    let theme = Theme::parse("bevel=sideways;borders=squiggly;border=mauve");

    assert_eq!(theme.bevel(), Bevel::Raised);
    assert_eq!(theme.border_type(), BorderKind::Plain.border_type());
    assert_eq!(
      theme.of(&[super::Themed::Border]).fg,
      Some(palette::OUTLINE)
    );
  }

  #[test]
  fn selection_falls_back_to_reverse_video() {
    let mut theme = Theme::default();

    assert_eq!(theme.selection().bg, Some(palette::OUTLINE));

    theme.selection = None;
    assert!(
      theme
        .selection()
        .add_modifier
        .contains(tui::style::Modifier::REVERSED)
    );
  }
}
