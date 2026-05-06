---
name: openclaw-docs
description: >-
  Retrieves current OpenClaw platform documentation using a tiered strategy.
  OpenClaw releases daily and third-party indexes lag behind, so this skill
  prioritizes live official docs over cached sources.

  Use this skill whenever working with OpenClaw configuration, APIs, agent
  architecture, plugins, cron/scheduling, memory systems, gateway setup,
  channel integrations, or any OpenClaw platform behavior.

  Common scenarios:
  - Looking up gateway config options or openclaw.json schema
  - Checking ACP/ACPX agent architecture and lifecycle
  - Verifying plugin SDK interfaces or breaking changes
  - Understanding memory/compaction APIs and settings
  - Configuring cron jobs, heartbeats, or scheduling
  - Setting up channel integrations (Discord, Slack, Telegram, etc.)
  - Debugging unexpected behavior after an OpenClaw update
  - Checking what changed in recent OpenClaw releases

  Always use this skill instead of relying on training data for OpenClaw.
  OpenClaw evolves rapidly — assumptions based on stale knowledge cause
  hard-to-diagnose bugs.
---

# OpenClaw Documentation Lookup

OpenClaw releases daily. Third-party indexes (like Context7) re-index every 10–15 days and may be weeks behind. This skill uses a tiered strategy to ensure you're working with current documentation.

## Tiered Strategy

### Tier 1 — Live docs (always current, use by default)

The official docs site publishes LLM-optimized files that are always in sync with the latest release.

**Full documentation** — use for most lookups:
```
WebFetch https://docs.openclaw.ai/llms-full.txt
```
This returns the complete OpenClaw documentation. It is large — scan for sections relevant to your query rather than trying to process everything.

**Doc index** — use to discover what pages exist, then fetch specific pages:
```
WebFetch https://docs.openclaw.ai/llms.txt
```
Returns a structured index of all documentation pages with titles and URLs. Useful when you need to find the right page before fetching its content.

**Changelog** — use when touching config, plugins, cron, or debugging post-update issues:
```
WebFetch https://raw.githubusercontent.com/openclaw/openclaw/main/CHANGELOG.md
```
Version-by-version record of all changes, including breaking changes. Check this FIRST when something that previously worked stops working.

### Tier 2 — Context7 CLI (may lag up to 2 weeks)

Good for general patterns, stable architectural concepts, and broad exploration. Not reliable for latest API surfaces, config options, or recent breaking changes.

Use the `find-docs` skill with these library IDs:

| Library ID | Use For |
|---|---|
| `/openclaw/openclaw` | Official source — gateway config, agent architecture, memory/compaction APIs |
| `/websites/openclaw_ai` | Broader coverage — multi-agent routing, scheduling, media handling |

## Decision Guide

Use this to pick the right tier:

| Task | Tier |
|---|---|
| Implementing or modifying `openclaw.json` config | Tier 1 — live docs |
| Writing or updating plugins | Tier 1 — live docs + changelog |
| Configuring cron jobs or heartbeats | Tier 1 — live docs + changelog |
| Debugging behavior after an OpenClaw update | Tier 1 — changelog first |
| Checking channel integration setup | Tier 1 — live docs |
| Understanding ACP/ACPX agent lifecycle (stable concepts) | Tier 2 is fine |
| General memory system architecture | Tier 2 is fine |
| Exploring what OpenClaw can do (broad discovery) | Tier 2, then Tier 1 for specifics |

**When in doubt, use Tier 1.** The cost of fetching live docs is a few seconds. The cost of implementing against stale docs is hours of debugging.

## Workflow

### For most queries (Tier 1):

1. Fetch the full docs:
   ```
   WebFetch https://docs.openclaw.ai/llms-full.txt
   ```
2. Search the returned content for sections relevant to your query.
3. If the query involves config/plugins/cron, also check the changelog:
   ```
   WebFetch https://raw.githubusercontent.com/openclaw/openclaw/main/CHANGELOG.md
   ```
4. Report what you found with a note that it came from live docs.

### For stable/conceptual queries (Tier 2):

1. Use the `find-docs` skill:
   ```bash
   npx ctx7@latest docs /openclaw/openclaw "your query here"
   ```
2. Note in your response that Context7 may not reflect the latest release.

### For targeted page lookups:

1. Fetch the doc index:
   ```
   WebFetch https://docs.openclaw.ai/llms.txt
   ```
2. Find the relevant page URL from the index.
3. Fetch that specific page:
   ```
   WebFetch <page-url>
   ```

## Important Rules

- **Never assume OpenClaw behavior from training data.** Always verify against docs. OpenClaw ships breaking changes frequently.
- **Always note the source** in your response — "per live docs" or "per Context7 (may not reflect latest release)."
- **Check the changelog** before telling a user something "isn't supported" — it may have been added in a recent release.
- **Do not over-fetch.** One WebFetch of `llms-full.txt` per conversation is usually sufficient. Scan the cached result for subsequent queries in the same conversation.
- **If WebFetch fails** (network error, timeout), fall back to Tier 2 (Context7) and note the fallback to the user.
