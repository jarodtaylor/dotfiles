# Post-merge roadmap

Items deferred from Phase 5 (the simplification refactor) to keep that
PR narrow. None block daily use; pick up in subsequent feature branches
when each earns its scope.

---

## Interactive drift-catcher (`dots drift`)

**Why.** Some apps silently overwrite chezmoi-managed files
(`~/.config/zsh/.zshrc`, Karabiner, Obsidian, etc.). The next
`chezmoi apply` then rejects the change as a conflict, and the user
has to manually inspect `chezmoi diff` and decide whether to
`chezmoi re-add` per file.

**Sketch.**

```bash
drifted=$(chezmoi status | awk '$1 ~ /M$/ { print $2 }')
selected=$(echo "$drifted" | fzf --multi --preview 'chezmoi diff {}')
echo "$selected" | xargs -r chezmoi re-add
```

Polish: checkbox-style preview, "commit captured drift?" prompt at end.
Could land as a new `dots drift` subcommand, or fold into `dots doctor`
behind an `--interactive` flag.

**Today's workaround.** `chezmoi diff` + manual `chezmoi re-add <path>`.
Build the TUI when friction earns it.

---

## macOS defaults capture

**Why.** A fresh Mac requires manually clicking through System Settings
to restore personal prefs (Dock minimalism, secondary-click = right
click, Finder show-extensions, screenshot location, etc.). Hours of
mouse work that should be a one-line apply.

**Sketch.** A new chezmoi script
`home/.chezmoiscripts/run_onchange_after_30-macos-defaults.sh.tmpl`
that runs `defaults write …` for each captured pref + `killall` to
reload affected apps. Re-runs only when the script content changes.

```bash
# Dock — minimalist
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock magnification -bool false
defaults write com.apple.dock minimize-to-application -bool true

# Trackpad — secondary click = right click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true

killall Dock && killall Finder
```

**Caveats.**

- GUI-only prefs (Accessibility, Full Disk Access, Login Items, Touch
  ID enrollment) cannot be scripted — must be done in System Settings.
- macOS version drift can rename keys between releases (Sequoia →
  Tahoe etc.). Test on the target OS.
- Discovery for unknown pref keys: `defaults read > before.txt`,
  change the pref in System Settings, `defaults read > after.txt`,
  `diff` reveals the exact key + value.

**Kickoff.** Dump every pref you change on a fresh Mac into a list,
then map each to its `defaults write` command. Inspiration:
[Mathias Bynens' `.macos`](https://github.com/mathiasbynens/dotfiles/blob/main/.macos).
