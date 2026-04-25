---
description: Set up Claude Code configuration for a project (run after planning)
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Task
---

Set up the Claude Code configuration for this project. If a planning session just occurred, use those decisions — don't re-ask what's already been decided.

1. Confirm stack/framework decisions (or reference what was just planned)
2. Research the project structure if code exists
3. Create the project-level CLAUDE.md with:
   - Build/test/lint commands
   - Architecture overview
   - Key file paths
   - Stack-specific conventions
4. Create `.mcp.json` with relevant MCP servers for the stack
5. Create `.claude/settings.json` with appropriate hooks for the stack's formatter/linter
6. Create `tasks/lessons.md` with initial structure:
   - Project-specific lessons header
   - Sections for: patterns, gotchas, corrections
   - Empty but ready for self-improvement loop entries
7. Create `tasks/todo.md` as the project task tracking file
8. Suggest skills and agents that would benefit this project
9. Set up .gitignore entries for `.claude.local.md`
