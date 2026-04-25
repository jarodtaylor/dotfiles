# Chezmoi Ironclad — Session Resumption Notes

**Last updated**: 2026-04-23 — **MAJOR PIVOT: simplify to single-machine declarative model** before M5 bootstrap and merge. See "Phase 5: simplification" below for the new scope. PR #2 is still open but will be rewritten.
**Branch**: `design/chezmoi-ironclad`
**Spec**: `docs/superpowers/specs/2026-04-16-chezmoi-ironclad-design.md` (the hybrid model this spec describes is being pared down — treat spec as *design history*, not current state)
**Plan**: `docs/superpowers/plans/2026-04-16-chezmoi-ironclad.md` (same — design history)

## Why the pivot (read this first)

After CP-4 passed and Copilot's review landed, Jarod clarified the
actual deployment model: **he runs ONE active daily-driver machine**.
M1 Max → M5 Max is a **migration**, not a fleet. After M5 is set up
he'll wipe M1 and repurpose it (possibly give to his brother). Mac
mini runs different workloads (OpenClaw agent) and has different
dotfiles. So the multi-machine hybrid sync machinery (launchd daily
agent, machine-authoritative Brewfile auto-capture, denylist filter,
race-condition mitigation) has no actual customer.

Concurrently, Jarod's preference is that Brewfile be **hand-edited /
declarative** — the friction of manually adding `brew "foo"` is a
*feature* that forces thoughtful curation and prevents sprawl. AI
tool state (`.claude`, `.codex`, `.cursor`) should remain
machine-captured because skills/plugins churn too fast for manual
maintenance.

The spec (§hybrid source-of-truth) was a clever-but-unnecessary
wrinkle for the brew domain. Reverting to chezmoi-native declarative
aligns with Tom Payne's design intent and simplifies ~10% of the
branch.

## Current state

- **Phase 0 (VM baseline)** — complete. Parallels VM has `clean-macos-with-1password` snapshot (fresh macOS + Xcode CLT + 1Password app + CLI signed in).
- **Phase 1 (audit & cleanup)** — complete. CP-1 validated in VM.
- **Phase 2 (sync infrastructure)** — complete. CP-2 validated (`dot sync` round-trip clean).
- **Phase 3 (launchd + bootstrap.sh + docs)** — complete. CP-3 passed in VM (2026-04-21).
- **Phase 4 (final validation + merge)** — complete pending PR review.
  - **4.1 (host `dot doctor`)** — complete. Brewfile drift captured as first host-authoritative sync (+45 entries, 0 removes).
  - **4.2 (VM replay, CP-4)** — complete. Fresh VM bootstrap ran end-to-end from `clean-macos-with-1password`. Only MAS entries fail (Apple blocks App Store sign-in from VMs — expected, documented). Denylist extended mid-replay to cover vscode+go capture artifacts.
  - **4.3 (KNOWN_ISSUES.md)** — complete. Covers post-bootstrap manuals, first-boot gotchas, day-to-day ops, preflight prereqs, VM-specific limitations, MAS-in-VM, on-disk age key rationale.
  - **4.4 (self-review)** — complete. Caught + fixed two merge-blockers:
    1. `private_config-work.tmpl` embedded age ciphertext as template body → renders verbatim, not decrypted. Migrated to `encrypted_private_config-work` (native chezmoi prefix). Two orphaned helper scripts (`setup-work-config`, `re-encrypt-work-config`) removed.
    2. `identityCommand` was not a real chezmoi config key — VM correctly surfaced this; apply failed to decrypt the work config. Replaced with `identity = "~/.config/chezmoi/key.txt"` + bootstrap-time fetch of key from 1Password.
  - **4.5 (merge)** — PR open for review by Copilot/Claude/Codex. Merge after feedback addressed.

## What's on the branch (commits since `main`)

Run `git log --oneline main..design/chezmoi-ironclad` for the real list. Highlights:
- Design spec + plan docs
- Curated Brewfile (replaces hardcoded list)
- `dot` CLI (renamed from `dots` to avoid conflict with user's zsh-abbr)
- `~/.claude`, `~/.codex`, `~/.cursor` captures (~/.gemini intentionally skipped)
- Templates for secrets via 1Password (`Dotfiles Age Key`, `Claude Code env`, `Codex auth`, `GitHub PAT - cursor mcp`)
- Templates for machine-portable paths via `{{ .chezmoi.homeDir }}` / `{{ .chezmoi.username }}`
- Age key migrated from `~/key.txt` to 1Password
- Expanded `.chezmoiignore` (AI tool runtime state, gstack symlink skills, etc.)
- Many fixes discovered in VM testing (see below)

## Known fixes applied during Phase 1/2 VM testing

These are all committed. Don't re-do.
- `brew bundle --no-lock` flag removed (newer Homebrew dropped it)
- Non-core tap casks use tap-qualified names (`nikitabobko/tap/aerospace`)
- `elco` and `expressvpn` dropped from bootstrap Brewfile (see `docs/KNOWN_ISSUES.md` next session)
- `sudo -v` priming in `script_sudo` is non-fatal
- `pam-config` only emits lines for PAM modules that actually exist on the machine
- `pam-config` uses `script_eval_brew` so `brew` is in PATH
- `ONEPASSWORD_AVAILABLE` env var gate replaced with `op whoami` runtime probe
- `.chezmoi.toml.tmpl` uses `identityCommand` via 1Password (no on-disk age key)
- `$HOME/bin` added to PATH (was missing; `~/bin` was unreachable)
- **PATH exports must come BEFORE `mise activate` in zshrc** (mise's precmd hook strips post-activate PATH additions)
- `dot sync` uses `chezmoi re-add` (not `add --recursive`) so template files stay templates and don't prompt every sync

## Phase 3 complete

Tasks 3.1 – 3.10 done. Commits on the branch this phase:
`7f8edb5` → `b4a6d17` → `e52c14b` → `d2e06bf` → `1e757d0` → `17fda41`
→ `2b542a0` → `f3e9564` → `f2568bf` → `7f04e9f` → `1cbf5c0` → `f665b7f`
→ `3a339ea` → `d111ab9`.

### Highlights vs the original plan

- Plist was templated (`.plist.tmpl`) instead of hardcoded paths — now
  portable across M1 Max / M5 Max via `{{ .chezmoi.homeDir }}` and
  `{{ .brew_prefix }}`. Task 3.2's after-apply script was updated to
  `include` the `.plist.tmpl` source and re-run via sha256 change
  detection.
- `bootstrap.sh` pre-installs `age` between Homebrew setup and
  `chezmoi init --apply` (fixes the chicken-and-egg noted below).
  `CHEZMOI_BRANCH` env var overrides default `main` for pre-merge VM
  runs.
- Brewfile was reorganized: 7 prompt-heavy casks (docker-desktop,
  karabiner-elements, microsoft-outlook/teams, adobe-creative-cloud,
  blackhole-2ch, zoom) are grouped into a dedicated "interactive
  installers" section at the end so macOS Auth Services password
  prompts arrive in one back-to-back burst. `dot sync` flattens this
  on first sync — that's expected, value is one-shot for first bootstrap.
- `cmd_new_machine` (Task 3.4) was already implemented during Phase 2
  and needed no code changes.
- CLAUDE.md stale-banner removed; file now describes ironclad
  architecture + secret table + active script inventory.

### CP-3 VM findings (bugs caught and fixed)

- `f665b7f` — `$(chezmoi source-path)` already returns the `home/`
  subdir (since `.chezmoiroot=home`); docs were appending `/home/`
  yielding `.../chezmoi/home/home/Brewfile` → "No Brewfile found".
- `3a339ea` — dropped `cask "1password"` and `cask "1password-cli"`
  from Brewfile. They're preflight prerequisites (SETUP.md §2); having
  them in the Brewfile races the pkg installs and creates two `op`
  binaries on PATH where only one holds the CLI-integration grant.
- `d111ab9` — **`dot sync` was silently reverting updates**. Brewfile
  was tracked by chezmoi (applied to `~/Brewfile`); inside `cmd_sync`,
  `brew bundle dump` would write fresh state to the source Brewfile,
  then `chezmoi re-add` would immediately copy the stale `~/Brewfile`
  back over it. Fix: add `Brewfile` to `.chezmoiignore` — nothing
  reads `~/Brewfile`, every consumer reads
  `$(chezmoi source-path)/Brewfile` directly. Verified in VM: a
  `brew install cowsay` + sync + `brew uninstall cowsay` + sync
  round-trip produced clean 2-line removal diff as expected.

## Phase 4

- **Task 4.1**: `dot doctor` green on primary M1 Max host (NOT the VM — the user's real machine)
- **Task 4.2**: Full Parallels VM end-to-end replay from `clean-macos-with-1password`
- **Task 4.3**: `docs/KNOWN_ISSUES.md` (capture all the rough edges listed below + whatever's left)
- **Task 4.4**: Final self-review
- **Task 4.5**: Merge to `main`

## Known gotchas to fix properly in Phase 3/4

- **Chicken-and-egg**: `.chezmoi.toml.tmpl` needs `age-keygen` to derive recipient, but `age` is installed by Brewfile (after init). First bootstrap skips encryption, requires a second `chezmoi init --apply` to pick it up. Fix in Phase 3 `bootstrap.sh`: install `age` (and `1password-cli` if needed) before first `chezmoi init`.
- **`chezmoi init` standalone doesn't re-render cached `~/.config/chezmoi/chezmoi.toml`** when op signin state changes. Workaround during CP-1 was `cp /tmp/rendered.toml ~/.config/chezmoi/chezmoi.toml`. Phase 3 bootstrap should ensure op is live before init, so this shouldn't bite.
- **Work git config `config-work` decryption**: source uses a pre-existing pattern where age-encrypted ciphertext is embedded as literal text in a `.tmpl`. Chezmoi renders the template but never decrypts the blob. Needs migration to chezmoi's `encrypted_` file-prefix convention (see spec §8). Was deferred from Phase 1.
- **Post-bootstrap manual installs** (to document in `KNOWN_ISSUES.md`):
  - `elco` (private GitHub tap): `brew tap elc-online/tap git@github.com:elc-online/homebrew-tap.git && brew install elco`
  - `expressvpn`: download from expressvpn.com (cask's LaunchDaemon install is flaky)
- **SSH first-connection prompt**: bootstrap.sh should `ssh-keyscan github.com >> ~/.ssh/known_hosts` pre-emptively.
- **Password prompts from cask pkg installers**: unavoidable (karabiner, microsoft-*, adobe, docker-desktop, fonts). Document.
- ~~**CP-2 stray Brewfile** at repo ROOT~~ — verified clean on 2026-04-21; only `home/Brewfile` exists.

## How to resume (next session = Phase 4)

1. Read this file + the spec + the plan.
2. Verify branch state: `git log --oneline main..HEAD`, `git status`,
   `dot doctor` (read-only; safe on host).
3. **Next action is Phase 4 Task 4.1 — `dot doctor` green on host (the
   real M1 Max).** Host hasn't been applied yet; `op` / brew / chezmoi
   should already be there from the pre-refactor setup. Just run
   `dot doctor` and see what's missing. Most likely outcome: brew drift
   (host has many packages not in the curated Brewfile, and vice versa).
   Decide per-case: capture via `dot sync` or prune.
4. Task 4.2 — full VM replay from `clean-macos-with-1password` (again,
   clean baseline) to prove a reviewer could run the one-liner and reach
   working state.
5. Task 4.3 — write `docs/KNOWN_ISSUES.md` covering the CP-3 rough edges
   (list below).
6. Task 4.4 — self-review diff against `main`.
7. Task 4.5 — merge to main.

## Phase 4 punch list (for `docs/KNOWN_ISSUES.md`)

- **Signed commits in VM**: bootstrap machines don't have the user's
  1Password SSH agent available, so signed commits fail on `dot sync`.
  Workaround: `git config --local commit.gpgsign false` in the VM's
  source dir. On host, commits should work normally.
- **`op` session per-terminal in VMs**: macOS Sequoia's App-Data
  privacy gate + no Touch ID passthrough means op prompts every new
  shell. Recommend disabling 1P auto-lock in the VM baseline snapshot.
  On host (Touch ID), this doesn't happen.
- **Interactive installer cask prompt burst**: macOS Authorization
  Services prompts can't be suppressed by sudo priming. Expected;
  Brewfile groups them together so they fire back-to-back at the end.
- **Pkg `op` + brew `1password-cli` conflict**: don't put 1password or
  1password-cli in Brewfile — they're preflight prerequisites. Fixed
  in `3a339ea`; document the failure mode for future reference.
- **First `dot sync` flattens curated Brewfile**: acknowledged B1
  trade-off. After first sync the Brewfile is flat-alphabetized per
  `brew bundle dump` behavior. Grouping value is one-shot for first
  bootstrap (prompt bunching).
- **Age template chicken-and-egg on first apply** (already noted in
  pre-CP-3 gotchas, kept here for completeness): bootstrap.sh
  pre-installs `age` so `.chezmoi.toml.tmpl` can derive recipient on
  first pass. No second `init --apply` required.
- **First-run `op authorization timeout`**: if the user walks away
  during brew bundle (~30 min) and the 1P app locks, the first
  `onepasswordRead` template call times out. Recovery: unlock 1P →
  `chezmoi apply -v` to resume (Brewfile install is content-gated and
  won't re-run).
- **Baseline snapshot needs refresh**: `clean-macos-with-1password`
  predates our "disable 1P auto-lock" recommendation. Consider
  re-snapshotting after the settings tweak so CP-4 is quieter.

## Key files / locations

- Source: `~/.local/share/chezmoi/` (this repo)
- `dot` CLI source: `home/bin/executable_dot`
- Brewfile: `home/Brewfile`
- AI tool captures: `home/dot_claude/`, `home/dot_codex/`, `home/dot_cursor/`
- Chezmoi meta: `home/.chezmoi.toml.tmpl`, `home/.chezmoiignore`
- Scripts: `home/.chezmoiscripts/`
- Script helpers: `home/.chezmoitemplates/scripts/`
- Plan + spec: `docs/superpowers/{specs,plans}/`

## 1Password entries required (all in Personal vault)

- `Dotfiles Age Key` (Secure Note, notesPlain = full `age-keygen` output — 3 lines incl. comments + secret)
- `Claude Code env` (Secure Note, notesPlain = `~/.claude/.env` plaintext)
- `Codex auth` (Secure Note, notesPlain = `~/.codex/auth.json` plaintext)
- `GitHub PAT - cursor mcp` (Secure Note, notesPlain = just the `ghp_...` token)
- Pre-existing: personal SSH key + work SSH key items

---

## Phase 5: simplification (NEXT SESSION STARTS HERE)

### Goal

Pare the branch back to a chezmoi-native single-machine model. Preserve
AI tool capture (the one place machine-authoritative is genuinely
needed); revert everything else to declarative/repo-authoritative.

### Tasks (execute in order)

**5.1 — Rename `dot` → `dots`** (Jarod's preference; `dots` reads
better than `dot sync`. Was originally `dots` pre-refactor; renamed
to avoid zsh-abbr conflict, but Jarod will update the abbr instead).

- `git mv home/bin/executable_dot home/bin/executable_dots`
- Global search+replace `dot ` → `dots ` and `\bdot\b` in: README, SETUP,
  CLAUDE.md, KNOWN_ISSUES, AUDITING, TESTING, spec, plan, all
  `.chezmoiscripts/`, launchd plist template if still present.
- Self-references inside `executable_dots` (log lines, usage text).

**5.2 — Revert Brewfile to hand-edited / declarative**

- Restore `home/Brewfile` to its hand-curated shape (Taps / Core CLI /
  UI / Interactive installers at end — the B1 grouping for prompt
  bunching). The currently-committed file is the flat dump from
  `dot sync`; use it as content source but re-add the section
  headings. Jarod will want to also prune packages he no longer uses
  while he's in there.
- Delete from `home/bin/executable_dots`: `BREWFILE_DENYLIST_BREW/
  CASK/TAP/VSCODE/GO` arrays, `filter_denylist()`, `brewfile_header()`,
  and the dump-filter-write sequence inside `cmd_sync`. `cmd_sync`
  becomes AI-tool-only: `chezmoi re-add ~/.claude ~/.codex ~/.cursor`
  (or similar scoped re-add) + commit + push.

**5.3 — Delete the launchd daily sync agent**

- `git rm home/Library/LaunchAgents/com.jarodtaylor.dots-sync.plist.tmpl`
- `git rm home/.chezmoiscripts/run_onchange_after_20-launchd-reload.sh.tmpl`
- Delete launchd mentions from README, CLAUDE.md, SETUP,
  KNOWN_ISSUES, and the spec (mark as design history).

**5.4 — Trim the `dots` CLI**

Keep: `apply`, `sync` (AI-only), `doctor`, `edit`, `help`.
Delete: `status`, `new-machine` (redundant with `doctor` + `bootstrap.sh`).

**5.5 — Add interactive drift-catcher** (optional, but Jarod asked)

`dots doctor` (or a new `dots drift`) should detect files where the
target has drifted from what chezmoi would render and offer a
multi-select fzf UI to `chezmoi re-add` the selected ones. This is
the classic pain point: some apps silently write to files chezmoi
manages (~/.config/zsh/.zshrc, karabiner, obsidian) and
`chezmoi apply` then refuses with a conflict.

Implementation sketch:

```
drifted=$(chezmoi status | awk '$1 ~ /M$/ { print $2 }')
selected=$(echo "$drifted" | fzf --multi --preview 'chezmoi diff {}')
echo "$selected" | xargs -r chezmoi re-add
```

Real version needs checkbox-style hints, better preview, and a
"commit the updates afterward?" prompt. Nice-to-have; don't block
merge on it.

**5.6 — Rewrite docs to match the simpler model**

- **README.md**: single-machine lifecycle, Brewfile is hand-edited,
  no daily launchd sync. Drop "Hybrid source-of-truth" framing;
  replace with "chezmoi declarative, plus captured AI tool state."
- **CLAUDE.md**: same edits.
- **KNOWN_ISSUES.md**: delete the "First `dot sync` flattens Brewfile"
  (B1) section, the launchd-Touch-ID-at-3am gotcha, and the
  baseline-snapshot-refresh note. Keep MAS-in-VM, post-bootstrap
  manual installs, and the on-disk age key rationale.
- **SETUP.md**: drop references to daily sync; keep bootstrap flow.
- **docs/superpowers/specs/2026-04-16-chezmoi-ironclad-design.md**:
  add a header note marking it as *design history* — it captured
  the hybrid model we scoped out.

**5.7 — Validate in M5 test user**

New M5 Max arrives; Jarod creates a test user. Run the bootstrap
one-liner with the simplified branch:

```
CHEZMOI_BRANCH=design/chezmoi-ironclad bash <(curl -fsSL \
  https://raw.githubusercontent.com/jarodtaylor/dotfiles/design/chezmoi-ironclad/bootstrap.sh)
```

This becomes CP-5. Iterate until clean.

**5.8 — Merge**

Force-push (or add commits to) PR #2. Re-ping Copilot/Claude/Codex
for a fresh review on the simplified branch. Merge.

### Out of scope for Phase 5

- Changing the 1P integration (keep as-is)
- Changing the `encrypted_` prefix work config (keep)
- Changing bootstrap's age-identity fetch (keep)
- Changing the AI tool capture mechanism (keep — it's the only
  thing where machine-authoritative has genuine value)

### Do NOT

- Re-derive the simplification argument — it's captured above.
- Re-audit the Brewfile denylist entries (1password, elco, expressvpn,
  vscode copilot-chat, cmd/go) — they don't exist in this model
  since brew isn't auto-captured.
- Re-open the spec vs plan vs RESUME tension — spec and plan are
  frozen as history; RESUME is the live doc.

### Current state of branch when Phase 5 starts

- PR #2 is open, `design/chezmoi-ironclad` at `cc516a6`.
- Branch includes 4 Phase-4 review-response commits (Copilot triage,
  work-config fix, age-identity fix, cleanup).
- Nothing uncommitted in working tree.
- M1 Max still has the old pre-refactor chezmoi config (not applied
  during refactor — per policy). Will need one `chezmoi init` to pick
  up the new config when cutover time comes, but not urgent.
