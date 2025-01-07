local wezterm = require("wezterm")

config = wezterm.config_builder()

config = {
  automatically_reload_config = true,
  enable_tab_bar = false,
  window_close_confirmation = "NeverPrompt",
  window_decorations = "RESIZE",
  default_cursor_style = "BlinkingBar",
  color_scheme = "Catppuccin Mocha",
  font_size = 14.0,
  font = wezterm.font("JetBrains Mono", { weight = "Medium" }),
}

return config
