# Adding a new AI tool to dotfiles

`dots sync` doesn't auto-discover new `~/.newtool/` directories — blind
capture would risk pulling secrets, multi-MB caches, or runtime sqlite
DBs into the repo. Onboarding is a ~5 minute review.

## 1. Inventory and classify

```bash
ls -la ~/.newtool/
du -sh ~/.newtool/*
```

For each path, decide:

- **Config, skills, agents, plugins, commands** → SYNC
- **Logs, caches, sessions, sqlite DBs, telemetry** → IGNORE
- **Auth tokens, API keys, session cookies** → SECRET (1Password)

Defaults that should always trigger IGNORE: files >1 MB, `*.sqlite`/`*.db`,
names containing `cache`, `history`, `session`, `log`, `telemetry`, `state`.

## 2. Extend `.chezmoiignore`

Add scoped patterns (use `.newtool/cache/**`, not `cache/**`):

```text
# --- ~/.newtool ---
.newtool/cache/**
.newtool/logs/**
.newtool/sessions.db
```

## 3. Extend `dots`

`home/bin/executable_dots` references `~/.claude`, `~/.codex`, `~/.cursor`
in two places — the `re_add_targets` array in `cmd_sync` and the directory
check loop in `cmd_doctor`. Add `"$HOME/.newtool"` to both.

## 4. Migrate any secrets to 1Password

For each auth/token file:

1. Create a Secure Note in `Personal` named e.g. `NewTool auth`. Paste the
   plaintext file contents into `notesPlain`.
2. Replace the captured file with a `.tmpl` calling `onepasswordRead`:

   ```go-template
   {{ onepasswordRead "op://Personal/NewTool auth/notesPlain" }}
   ```

3. Delete the plaintext file from `home/dot_newtool/` before committing.

## 5. Capture and verify

```bash
dots sync --dry-run                 # preview
dots sync                           # capture into source repo
git diff                            # review

# Sanity check: no obvious secret patterns leaked
grep -rE 'sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{30,}|AKIA[A-Z0-9]{16}|Bearer [A-Za-z0-9]{20,}' \
  home/dot_newtool/
```

If anything matches, fix it before committing — or if already pushed,
rotate the secret and rewrite history (`git filter-repo`).
