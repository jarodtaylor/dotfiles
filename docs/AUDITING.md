# Auditing a New AI Tool

When a new AI tool lands on the machine (a new `~/.newtool/` directory),
`dots sync` does **not** automatically pick it up. This is deliberate: a
blind capture would risk pulling secrets into the repo, committing
multi-megabyte caches, or shipping runtime-only state like sqlite session
DBs.

Onboarding a new tool is a ~5-minute review. This doc is the checklist.

## Step 1: Inventory what's there

```bash
ls -la ~/.newtool/
du -sh ~/.newtool/*
```

Classify each path:

- **Config files** (hand-edited or tool-written settings) → SYNC
- **Skills / agents / plugins / commands** → SYNC
- **Logs, caches, sessions, sqlite DBs** → IGNORE
- **Auth tokens, API keys, session cookies** → SECRET (1Password)

## Step 2: Decide the taxonomy

Fill in a mental (or literal) table:

| Path | Classification |
|---|---|
| `~/.newtool/config.toml` | SYNC |
| `~/.newtool/skills/` | SYNC |
| `~/.newtool/cache/` | IGNORE |
| `~/.newtool/sessions.db` | IGNORE |
| `~/.newtool/auth.json` | SECRET (1Password) |

## Step 3: Extend `.chezmoiignore`

Add patterns for the IGNORE entries. Pattern scope matters — use
`.newtool/cache/**`, not `cache/**`.

```text
# --- ~/.newtool ---
.newtool/cache/**
.newtool/logs/**
.newtool/sessions.db
```

## Step 4: Extend the `dots sync` capture loop

Open `home/bin/executable_dots` and find the AI tool capture loop
(currently around line 246):

```bash
for tool_dir in "$HOME/.claude" "$HOME/.codex" "$HOME/.cursor"; do
```

Add `"$HOME/.newtool"` to the list.

## Step 5: Handle secrets

If there are auth/token files, migrate them to 1Password:

1. Create a Secure Note in the `Personal` vault named `NewTool auth`.
   Paste the plaintext file contents into `notesPlain`.
2. Replace the captured file with a `.tmpl` that calls `onepasswordRead`:

   ```go-template
   {{ onepasswordRead "op://Personal/NewTool auth/notesPlain" }}
   ```

3. Delete the plaintext file from `home/dot_newtool/` before committing.

## Step 6: First capture

```bash
dots sync --dry-run   # preview what would land in the commit
dots sync             # commit
```

## Step 7: Verify no secrets leaked

```bash
cd $(chezmoi source-path)
grep -rE 'sk-[A-Za-z0-9]{20,}|ey[A-Za-z0-9_-]{30,}|ghp_[A-Za-z0-9]{30,}|AKIA[A-Z0-9]{16}' home/dot_newtool/
```

Expected: no output. If anything matches, a secret leaked — fix it and
`git commit --amend` (if you haven't pushed) or follow the leaked-secret
remediation runbook (rotate + force-push via `git filter-repo` — not yet
documented; add here if it happens).

## Red flags

- File > 1 MB → almost certainly a cache, DB, or model weight. IGNORE.
- SQLite files (`.sqlite`, `.db`) → IGNORE.
- Names containing `*cache*`, `*history*`, `*session*`, `*log*`,
  `*telemetry*`, `*state*` → IGNORE.
- Content containing `sk-`, `ey…`, `ghp_`, `AKIA`, `Bearer ` → SECRET.
