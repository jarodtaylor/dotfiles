---
description: Run a comprehensive pre-PR review
allowed-tools: Read, Glob, Grep, Bash, Task
---

Before creating a PR, run a thorough review:

1. **Diff analysis**: Review all changes since branching from main
2. **Test coverage**: Are new/changed paths tested?
3. **Lint/type check**: Run project linters and type checkers
4. **Security scan**: Check for secrets, injection vectors, OWASP concerns
5. **Breaking changes**: Could this break existing functionality?
6. **Documentation**: Does CLAUDE.md or README need updates?

Use subagents in parallel for steps 2-5 to speed this up.

Present a summary with:
- Changes overview (files touched, lines changed)
- Issues found (blocking vs advisory)
- Confidence level (ship it / needs attention / needs rework)
