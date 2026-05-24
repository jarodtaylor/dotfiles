# RCA / Investigation Brief — 1Password SSH commit-signing fails when unattended

**Status:** Resolved 2026-05-24 (see §10). Originally an open handoff to a dedicated investigation session.
**Owner machine:** Jarod's Mac (darwin). The fix lands in **dotfiles / 1Password settings**, NOT in any project repo — this issue reproduces across every repo on the machine.
**Written:** 2026-05-24, by the agenthq session that kept hitting it during GSD plan-phase work.
**Scope of this doc:** give the investigating agent enough grounded detail to characterize the trigger precisely and choose a fix. The investigation brief (§§1–9) was written before the fix and is NOT a prescription; the chosen solution and verification are recorded in §10 (Resolution).

---

## 1. Problem statement

`git commit` (and any local git op that signs) intermittently fails with a 1Password SSH-agent error. It happens **when Jarod is away from the keyboard and doesn't approve the 1Password prompt / provide Touch ID in time** — but the exact mechanism (auto-lock vs per-use approval timeout vs app auto-update) is **not yet confirmed**. It recurs repeatedly within a single work session, even after a 1Password relaunch temporarily fixes it.

**Impact:** Blocks autonomous / "Jarod-away" agent workflows. A multi-hour GSD session on 2026-05-24 hit it ~3 times; each time the deliverable was safe on disk but the commit couldn't be created until 1P was relaunched. One subagent worked around it by committing with `--no-gpg-sign` (left an unsigned commit on `main`).

---

## 2. Exact symptom (verbatim)

```
$ git commit -m "..."
error: Signing file /var/folders/.../.git_signing_buffer_tmpXXXX
Couldn't sign message (signer): communication with agent failed?
Signing /var/folders/.../.git_signing_buffer_tmpXXXX failed: communication with agent failed?
fatal: failed to write commit object
```

**Key tell:** `ssh-add -l` **succeeds** (lists keys) at the same moment signing **fails**. Listing public keys requires no authorization from 1Password; *signing* does. That asymmetry is the heart of the issue.

**Unaffected:** `gh` CLI API operations (PR create/merge, issue comments) — those use a stored token, not the SSH agent. So merges land even when local signing is dead. (Separately: `git push` over SSH *would* also fail, because it uses the same 1P agent for auth — but auth and signing are different agent operations; confirm both during the investigation.)

---

## 3. Grounded environment (captured live 2026-05-24, this machine)

| Fact | Value |
|------|-------|
| `commit.gpgsign` | `true` |
| `tag.gpgsign` | (unset) |
| `gpg.format` | `ssh` |
| `gpg.ssh.program` | **unset** → git uses the built-in `ssh-keygen -Y sign` path |
| `user.signingkey` | inline SSH pubkey `ssh-ed25519 AAAA…VGs` → fingerprint `SHA256:Zz1/DSR5R7c/5jcBh+QFv8qzR8wWrs2fWvV1zTa42B4`, agent comment `ssh_key` |
| `gpg.ssh.allowedSignersFile` | **unset** (so `git log --show-signature` can't *verify* SSH sigs — separate minor gap, see §7) |
| `SSH_AUTH_SOCK` | `~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock` (the 1Password SSH agent) |
| `~/.ssh/config` | contains `IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"` — **chezmoi-managed** |
| 1Password app | `/Applications/1Password.app` **v8.12.21** |
| `~/.config/1Password/ssh/agent.toml` | **absent** → 1P SSH agent runs with default behavior (no per-key config) |
| Agent keys (`ssh-add -l`) | `ssh_key` (the signing key) + `work_ssh_key`, both ED25519 |

**Signing call chain:** `git commit` → `ssh-keygen -Y sign` → talks to `SSH_AUTH_SOCK` → **1Password SSH agent** → 1P decides whether to authorize the signature (this is the step that fails).

**Where the real config lives:** `.ssh/config` is chezmoi-managed (so the `IdentityAgent` line is a dotfile). The git signing block (`commit.gpgsign`, `gpg.format`, `user.signingkey`) is in git config — confirm whether it's `~/.gitconfig` (chezmoi-managed) or repo-local during the investigation. **Any durable fix should be made in the chezmoi source, not as a one-off local edit.**

---

## 4. Root-cause hypothesis (confidence: mechanism HIGH, exact trigger MEDIUM)

**Mechanism (HIGH):** Commit signing requires the 1Password SSH agent to *authorize* a signing operation. Unlike key *listing* (always allowed), *signing* is gated by 1Password's authorization policy. When 1P cannot get that authorization in time, the agent returns "communication with agent failed" and git aborts.

**Trigger — three candidates, NOT yet disambiguated (this is the main thing to confirm):**
1. **Auto-lock.** 1Password locks after an inactivity timeout. A locked vault can still expose cached public keys to the agent (so `ssh-add -l` works) but cannot sign. When Jarod is away long enough, 1P locks → signing dies → relaunch/unlock fixes it → it re-locks later → recurs. *This best fits the "recurs even after relaunch" observation.*
2. **Per-use approval prompt timeout.** If the SSH key is set to "ask for approval every time it's used," each signing op pops a 1P prompt (Touch ID / approve). Unattended, the prompt times out → failure.
3. **App auto-update.** 1P 8.x auto-updates restart the agent process mid-operation; an in-flight sign during a restart fails. (Likely a minor/occasional contributor, not the main cause.)

The investigation must determine **which** (or which combination) — the fix differs per trigger.

---

## 5. Diagnostic plan (run these to characterize the trigger)

> All read-only / safe except where noted. Goal: turn the MEDIUM-confidence trigger into HIGH.

**A. Confirm the signing path + isolate sign-vs-list:**
```bash
echo "$SSH_AUTH_SOCK"
ssh-add -l                     # should succeed (lists keys)
# Direct sign test (mimics what git does) — succeeds only if the agent will authorize:
printf 'test' | ssh-keygen -Y sign -n git -f <(ssh-add -L | grep 'ssh_key$' || ssh-add -L | head -1) 2>&1 | head
# ^ if this prompts/touches and succeeds when present, but fails when 1P is locked → confirms the gate.
```

**B. Reproduce each candidate trigger deliberately:**
- **Auto-lock:** Lock 1Password (manually or wait out the timeout) → attempt `git commit --allow-empty -m "signing probe"` in a throwaway repo. If it fails locked and succeeds unlocked → auto-lock is the trigger.
- **Per-use approval:** Open 1Password → **Settings → Developer → SSH Agent** (and per-item: the SSH key item's "ask for approval" / authorization setting). Note whether keys require approval per use. Toggle and re-test.
- **Timeout window:** Time how long after the last unlock signing keeps working — that's the auto-lock interval. (1P **Settings → Security → Auto-lock**.)

**C. Capture the settings that govern it (the investigating agent should record these — they're GUI-only, not CLI-readable):**
- Settings → Security → **Auto-lock** (after N minutes of inactivity / on screensaver / on sleep).
- Settings → Developer → **Use the SSH agent** (on?) and any **key authorization** policy.
- Per-SSH-key item → whether "**Authorize with Touch ID/approval each time**" is set.
- Whether **"Keep 1Password unlocked"** / system-auth integration is enabled.

**D. Confirm push vs sign independence:** test an SSH `git ls-remote` (auth) while 1P is locked — does auth also fail, or only signing? Informs whether the HTTPS-via-gh todo (§6E) is still needed.

---

## 6. Solution space (evaluate + recommend — tradeoffs noted; Jarod decides)

**A. Tune 1Password authorization for unattended signing.**
- If auto-lock is the trigger: lengthen the auto-lock interval, or enable "keep unlocked" for the session, or exclude the agent from locking. Tradeoff: weaker security posture (vault stays unlocked longer).
- If per-use approval is the trigger: change the signing key from "approve every time" to "approve once / don't require approval." Tradeoff: any process on the machine can then sign with that key.
- Lowest-effort if it maps to a single setting; preserves the all-in-1P model.

**B. Dedicated non-1P signing key for automation.** Generate a plain `~/.ssh/` ED25519 key (not in 1P), point `user.signingkey` (+ optionally a repo/condition-scoped git config) at it, so signing never touches the 1P agent. Tradeoff: that key isn't 1P-protected (mitigate with file perms / passphrase-less is the point). Cleanest separation of "interactive auth" (1P) from "unattended signing" (local key). **Likely the strongest fix for the "Jarod away" use case.**

**C. Graceful-degradation signing.** Don't hard-fail commits when the agent won't sign. Options: a commit wrapper / git hook that retries unsigned on signer failure; or a `gsd`/agent convention to `--no-gpg-sign` on doc-only commits. Tradeoff: produces unsigned commits (acceptable here — see §7; the repo doesn't enforce signing). Band-aid, not a root fix, but useful as a fallback layer.

**D. Reconsider whether signing is required at all** for these repos / commit types. If the answer is "signing is nice-to-have, not enforced," then `commit.gpgsign=false` (globally or per-repo) removes the dependency entirely. Tradeoff: loses commit provenance. (Jarod set signing up deliberately — confirm intent before choosing this.)

**E. HTTPS-via-gh for the git *remote* (already a tracked todo).** Routes push/fetch auth through the `gh` token instead of the 1P SSH agent. **Clarification: this fixes PUSH (transport auth), NOT SIGNING** (signing is local + transport-independent). So E is complementary to A–D, not a substitute. Worth doing for the push half of unattended git, but it won't stop the `failed to write commit object` signing error.

**Recommended evaluation order:** confirm the trigger (§5) → if it's a clean 1P setting, try **A**; if "Jarod away" is a recurring first-class requirement, **B** is the durable answer; layer **C** as a safety net; do **E** separately for pushes.

---

## 7. Constraints & things to preserve

- **Keep 1Password as the interactive SSH auth path** for `work_ssh_key` and normal `ssh_key` usage — don't break GitHub auth.
- **Durable fixes belong in the chezmoi dotfiles source** (`.ssh/config` is already chezmoi-managed; check `.gitconfig`), not as untracked local edits — otherwise the fix evaporates on the next `chezmoi apply`.
- The repo (`agenthq`) and apparently the user's other repos **do not enforce signed commits** — historical `main` has a mix of signed and unsigned commits, and unsigned commits push fine. So unsigned fallback (option C) is genuinely safe, and the urgency is about *not blocking commits*, not about *signing being mandatory*.
- Minor adjacent gap: `gpg.ssh.allowedSignersFile` is unset, so `git log --show-signature` reports "No signature" / can't verify even on signed commits. If signing is kept, configuring an allowed-signers file makes signatures verifiable. (Out of scope for the blocking issue, but cheap to fix alongside.)

---

## 8. Acceptance criteria for the fix

- [ ] A `git commit` succeeds **with Jarod away from the keyboard** (no Touch ID / approval needed in the moment) — either signed via a non-interactive path, or gracefully unsigned, per the chosen option.
- [ ] Interactive signing (when Jarod *is* present) still works and stays attributable.
- [x] SSH **auth** (clone/fetch/push) works headless: GitHub via the on-disk key (1Password bypassed for github.com per §10); all other hosts still use the 1Password agent.
- [ ] The fix is captured in the **chezmoi source** so it survives `chezmoi apply`.
- [ ] The exact trigger (auto-lock vs per-use approval vs update) is documented so the behavior is understood, not just patched.

---

## 9. References

- Memories (this project's `~/.claude/.../memory/`): `feedback_1password_ssh_agent_signing_fails_unattended.md` (the recurring-symptom note + "fix = quit+relaunch 1P"), `feedback_gh_pr_merge_delete_branch_needs_ssh.md` (push-vs-API split), `feedback_gsd_subagent_socket_drop_recovery.md` (a subagent used `--no-gpg-sign` around it).
- Prior todo: "route this repo's git via HTTPS-via-gh so unattended Remote-Control merges/pushes don't depend on the 1P SSH agent" (this is option §6E — push only).
- 1Password docs to consult: "1Password SSH agent" (agent.toml `[[ssh-keys]]` + `vault`/auth options), "Sign Git commits with SSH" (1P's own guide), and Settings → Developer / Security (auto-lock, key approval).
- Git docs: `git config gpg.ssh.program` (1P ships `op-ssh-sign` as an alternative signer — note it's currently UNSET here, so the default `ssh-keygen -Y sign` is in use; switching to `op-ssh-sign` is itself a variable worth testing).

---

*This brief was generated from live config on Jarod's machine on 2026-05-24. The config snapshot in §3 is the ground truth to start from; re-capture it if time has passed.*

---

## 10. Resolution (2026-05-24)

**Fixed at the chezmoi source and applied as a live stopgap. Verified end-to-end with the 1Password agent removed (`SSH_AUTH_SOCK=` / `IdentityAgent none`).**

**Key discovery that simplified the fix:** the keys do *not* live only in 1Password. chezmoi already materializes both private keys from 1Password to **passphrase-less files** on disk — `~/.ssh/id` (signing) and `~/.ssh/work_id` (work) — via `onepasswordRead` in `home/private_dot_ssh/private_*_id.tmpl` (same key material / fingerprints the agent serves). So RCA **option B (generate a new automation key) was unnecessary.** The true root cause: `user.signingkey` was set to the inline **public key**, which forces `ssh-keygen -Y sign` to find the private half **in the 1Password agent** — the gated, fail-when-away path. (`config.tmpl` even had a file-based fallback in its `else` branch; it only fired on machines not signed into 1Password at init.)

**The fix — route the two headless-critical git ops through the on-disk files; 1Password stays vault + source-of-truth + interactive agent for everything else:**

| Change | chezmoi source file | Effect |
|---|---|---|
| `user.signingkey` → `~/.ssh/id` (removed the agent-pubkey branch) | `home/dot_config/git/config.tmpl` | commit signing never touches the agent |
| work signing → `~/.ssh/work_id` | `home/dot_config/git/encrypted_private_config-work` | work-dir commits sign headless |
| `IdentityAgent none` + `IdentityFile` on the github host blocks (moved **above** `Host *`, since ssh uses the first value per option) | `home/private_dot_ssh/config.tmpl` | clone/fetch/push auth via file, not agent |
| add `gpg.ssh.allowedSignersFile` + allow-list | `home/dot_config/git/config.tmpl`, `home/dot_config/git/allowed_signers.tmpl` | `git log --show-signature` now verifies locally |

Same keys/fingerprints → GitHub "Verified" status and commit attribution unchanged; no key re-registration.

**Verification (all with 1Password bypassed):** `git commit` with `SSH_AUTH_SOCK=` removed → signed commit, `show-signature` = `Good "git" signature for jarodrtaylor@gmail.com`; `ssh -T git@github.com` and `git fetch` with `SSH_AUTH_SOCK=` blanked → `Hi jarodtaylor!` / exit 0; non-github hosts still resolve to the 1Password agent (constraint §7 preserved).

**Deltas from the brief:**
- **Trigger (§4) was not disambiguated — and didn't need to be.** The file path bypasses *all three* candidate triggers (auto-lock, per-use approval, app-update) at once; the fix is trigger-agnostic.
- **§8 bullet 3 evolved:** github SSH auth now bypasses 1Password (to the file) per the approved push fix; 1Password remains the agent for all *other* SSH.
- **Pre-existing no-op left in place:** `[gpg] program = …` sets `gpg.program` (openpgp), not `gpg.ssh.program`; SSH signing uses the built-in `ssh-keygen` (proven). Untouched to keep scope tight — flagged for a future cleanup pass.
- **Work signing not exercised end-to-end here** (`~/Code/work` absent on this machine); components proven individually — first real run is Jarod's next commit in a work repo.

**Activation:** live stopgap (rendered targets written directly to the live files — **no `chezmoi apply`**, per the M1 freeze) **and** committed to source. A normal `chezmoi apply` at the M5 cutover reconciles cleanly (`chezmoi diff` is currently empty). Note: `chezmoi apply`/`diff` themselves prompt for 1Password because they render the `onepasswordRead` key templates — expected, and unrelated to git signing/auth.
