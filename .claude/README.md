# `.claude/` — docs-kit engineering toolkit

Slash commands and rules that drive autonomous and semi-autonomous work on
docs-kit. `/lfg` runs the full loop; the others are focused specialists.

## Commands

| Command | Tier | Purpose |
|---------|------|---------|
| `/plan` | `fable` | Read-only planning → a self-contained GitHub issue or `docs/plans/` markdown that `/lfg` executes |
| `/lfg` | `opus` | Full workflow: branch → understand → explore → plan → TDD → verify → PR |
| `/tdd` | `sonnet` | Enforce RED → GREEN → REFACTOR |
| `/architect` | `opus` | Coordinate a change across config → registry → components → client → generator → CSS |
| `/security` | `opus` | Security audit (HTML escaping, config trust, render path, generated files, deploy secrets) |
| `/review-pr` | `opus` | Review a PR for pattern compliance |
| `/github-review-pr` | `opus` | Full PR pass: CI failures first, then review comments |
| `/github-review-failures` | `sonnet` | Fix failing CI checks until green |
| `/github-review-comments` | `sonnet` | Process unresolved PR review comments |

## Rules

`rules/` holds the project conventions the commands lean on:

- `coding-style.md` — many small files, compose from `DocsUI::` components, read config, progressive enhancement
- `git-workflow.md` — conventional commits, branch naming, PR flow, `rake release`
- `testing.md` — the test layers (config / component render / generator), coverage bars
- `agents.md` — when to delegate, parallel exploration, cheaper models for mechanical subagents

## Model-tier convention

Every command (and agent) pins a model **tier alias** in its frontmatter, never a
full model ID:

```markdown
---
description: "..."
model: sonnet   # haiku | sonnet | opus | fable
argument-hint: "..."
---
```

- `haiku` — mechanical/config work, diff pattern-scans
- `sonnet` — layer specialists / pattern-following implementation (the default)
- `opus` — orchestration, security, PR/production review
- `fable` — read-only planning that hands execution to cheaper models (`/plan`); otherwise pick it per-session with `/model`

Aliases track the latest model in each tier, so a pin never goes stale the way a
literal `claude-opus-4-8` does. When you author a new command, pick the tier by
the work it does, and pass a cheaper `model:` explicitly to any subagent doing
mechanical work rather than letting it inherit the session model.
