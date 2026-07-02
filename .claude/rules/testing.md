# Testing Rules

## TDD Workflow

Follow RED → GREEN → REFACTOR:

1. **RED**: Write a failing test first
2. **GREEN**: Write minimal code to pass
3. **REFACTOR**: Improve code while keeping tests green

## The test layers

docs-kit is a Phlex/daisyUI chrome gem. Tests exercise the components, the
in-memory registry, and the generators — cheapest first:

| Layer | Path | Boots | Use for |
|-------|------|-------|---------|
| Unit | `spec/docs_kit/**` | nothing | `DocsKit::Registry`, `DocsKit::NavItem`, `Configuration` |
| Component | `spec/docs_ui/**` | Phlex render (no Rails request) | that a component renders the expected HTML/daisyUI classes given props |
| Generator | `spec/generators/**` (if present) | generator harness | `docs_kit:install` writes the right files |

A component spec renders the Phlex class and asserts on the produced markup —
the daisyUI classes emitted, the config-driven values, the active-link state.
Prefer asserting on **behavior/semantics** (a link is active, a theme option is
present) over brittle full-HTML snapshots.

## Coverage Expectations

- **80% minimum** for all code
- **100%** for the config surface (`DocsKit::Configuration`) and the registry
  mixin (`DocsKit::Registry`) — the public API sites depend on.

## RSpec Conventions

```ruby
subject(:component) { described_class.new(themes: %w[dark light]) }

it "renders every configured theme as an option" do
  html = render(component)
  expect(html).to include("dark").and include("light")
end

context "when the current path matches a nav item" do
  it "marks that link active" do
    # ...
  end
end
```

Use a small `render(component)` helper that calls the Phlex component to a
string (through a real view context where url helpers / `dom_id` are needed).

## What to cover

- **Config-driven output** — a component reflects `DocsKit.configuration`
  (themes, brand, version badge, nav) rather than hardcoded values.
- **Active-nav highlighting** — the sidebar marks the link matching the request
  path, with NO JavaScript (server-rendered).
- **Progressive enhancement** — the server renders sections `open`; the page is
  usable with JS off.
- **Registry semantics** — `DocsKit::Registry` (grouping, lookup, ordering).
- **Generator output** — `docs_kit:install` writes the expected files/initializer.

## Test Checklist

- [ ] Tests written BEFORE implementation; RED verified
- [ ] `bundle exec rspec` green
- [ ] Component output asserted on semantics, not brittle full-HTML snapshots
- [ ] Config-driven paths covered (themes, brand, version badge, nav)
- [ ] Active-nav highlighting covered (no-JS, server-rendered)
- [ ] `bundle exec rubocop` passes
