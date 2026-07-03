# AGENTS.md

Guidance for AI coding agents working in the **docs-kit** repository. This is the
cross-tool convention file (Claude Code, Cursor, Copilot, Aider, …). Claude Code
users also have `.claude/commands/` and `.claude/rules/`; see `CLAUDE.md` for the
full project brief. This file is the fast orientation.

docs-kit is a Rails engine that ships the shared Phlex/daisyUI **chrome** for
documentation sites — the shell, sidebar, code blocks, theme switcher, page kit —
so many docs sites look identical and are maintained in one place. The gem also
**dogfoods itself**: its own docs site lives under `docs/`.

## The two things you'll be asked to do

### A. Change the gem (a component, config knob, generator, the engine)

Read `CLAUDE.md` first — it has the layer map and the critical rules. The
non-negotiables:

- **Compose from `DocsUI::` Phlex components** — never hand-write raw daisyUI markup.
- **Site-specific values come from `DocsKit.configuration`**, never hardcoded in a
  component. A new knob lands on `DocsKit::Configuration` with a sensible default
  (backwards compatible).
- **The page works with JavaScript off.** The server renders it fully; the one
  `docs-nav` Stimulus controller only *enhances* (collapse persistence, auto-TOC).
- **Themes offered must exist in the CSS build** — `config.themes` must match the
  `@plugin "daisyui" { themes: … }` block.
- **Required setup wires into BOTH** the install generator
  (`lib/generators/docs_kit/install/`) **and** the `docs-kit new` template
  (`lib/docs_kit/templates/new_site.rb`) — never the README alone.
- **TDD**: write the failing spec first (`spec/docs_kit`, `spec/docs_ui`,
  `spec/generators`), then the minimum code. Assert on semantics, not HTML snapshots.

### B. Write a docs page for docs-kit's own docs site (under `docs/`)

The dogfood site is itself a docs-kit site. Its registry is
`docs/app/models/doc.rb`; its pages are `docs/app/views/docs/pages/`. To document
a feature of the gem:

**1. Scaffold** (from the `docs/` app):

```bash
cd docs && bin/rails g docs_kit:page "Getting Started" --group=Guide
```

That writes `docs/app/views/docs/pages/getting_started.rb` **and** injects the
required `page "Getting Started", group: "Guide"` line into `Doc`. Overrides:
`--slug`, `--view`, `--eyebrow`, `--registry`. The registry line is **required** —
no line, no page.

**2. Write `#content` — Markdown first.** Prose is `md` with a **single-quoted**
heredoc (`<<~'MD'`) so `#{…}` stays literal (Phlex escapes author text — never
`html_safe` or interpolate). `DocsUI::Section` owns page structure and the TOC;
never use a Markdown `##` for structure. The primary arg is positional, modifiers
are keywords: `Section("Title", description:)`, `Code(source, filename:)`. For no
positional arg use the lowercase helpers `md` / `prose` / `example`. Reference
material has dedicated helpers: `DocsUI::PropTable`, `DocsUI::FieldTable`,
`DocsUI::RequestExample`, `DocsUI::Callout(:note | :tip | :warning)`.

The always-current, worked example of the whole contract is
`docs/app/views/docs/pages/authoring.rb` (rendered at `/docs/authoring`). Read it
before writing a page.

## Verify before you finish (every change)

```bash
bundle exec rspec        # the suite (SimpleCov enforces 80% minimum)
bundle exec rubocop      # lint — no offenses (rubocop -A to autocorrect)
bundle exec rake         # both, together
```

For CSS-affecting changes (a new emitted class), rebuild in the `docs/` app:
`bun run build:css`. Never `gem push` by hand — release via `rake release[X.Y.Z]`.
