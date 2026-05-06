# zsh functions

Shell functions organized by purpose. Auto-sourced from `../dot_zshrc`.

## cli/

Interactive tools for daily development. Each file defines a single
function named after the file. Most are fuzzy-finder (`fzf`) wrappers.

- `ffe` — find file, edit. Lists files, previews with bat, opens in `$EDITOR`.
- `fgc` — find git commit. Fuzzy-browse `git log`; pressing enter shows the diff.
- `fif` — find in files. `rg` + `fzf` for live-preview grep.
- `fkp` — find + kill process by port.
- `glg` — `git log` grep. Search commit messages interactively.
- `gbd` — git branch delete (with confirmation).
- `yazi` — wrapper around the yazi file manager that cd's into the directory yazi was in on exit.

## config/

Shell setup loaded first during zsh init. Not meant to be called directly.

- `fzf-opts.zsh` — FZF default opts + color theme
- `starship.zsh.tmpl` — starship prompt init
- `prompt-newline.zsh.tmpl` — prompt formatting helpers

## Adding a function

Drop a file in `cli/` or `config/`. Use the filename as the function name
(matches existing convention). No explicit `autoload` needed — zshrc
sources `**/*.zsh` on startup.
