# SketchyBar config

A Lua-driven [SketchyBar](https://felixkratz.github.io/SketchyBar) setup: a
macOS menu bar with system stats, media controls, and space/workspace
indicators. Uses the [SbarLua](https://github.com/FelixKratz/SbarLua)
binding so the whole config is Lua, not shell.

## Prerequisites

- macOS
- [SketchyBar](https://felixkratz.github.io/SketchyBar) (`brew install felixkratz/formulae/sketchybar`)
- [SbarLua](https://github.com/FelixKratz/SbarLua)
- Lua (`brew install lua`)

All three are in the Brewfile; `dot apply` installs them.

## Layout

- `sketchybarrc` — shebang + entry point that SbarLua invokes
- `init.lua` — loads modules in order
- `bar.lua` — top-bar appearance (height, padding, blur, color)
- `colors.lua` — palette (one place to rethemed)
- `settings.lua` — shared constants (font sizes, paddings)
- `icons.lua` — symbol map for SF Symbols / Nerd Font
- `items/` — individual widgets (battery, cpu, media, spaces, etc.)
- `helpers/` — native C event providers + utilities
- `terminal/` — notched terminal integration

## Customizing

Most tweaks live in `colors.lua`, `settings.lua`, and `icons.lua`. Widget
behavior is in `items/*.lua`. Restart the bar after edits:

```bash
brew services restart sketchybar
```

## References

- [SketchyBar docs](https://felixkratz.github.io/SketchyBar/config/getting-started)
- [SbarLua repo](https://github.com/FelixKratz/SbarLua)

## Credits

Both SketchyBar and SbarLua are by Felix Kratz. This directory's license
is in `LICENSE`.
