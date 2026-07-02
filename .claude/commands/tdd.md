---
description: "Use when implementing any feature or fixing any bug — enforces RED-GREEN-REFACTOR: write failing test first, implement minimum code to pass, then refactor."
model: sonnet
---

# TDD Command

Enforce test-driven development with RED → GREEN → REFACTOR.

## The TDD Cycle

```text
RED:      Write a failing test (it MUST fail first)
GREEN:    Write MINIMAL code to pass (nothing more)
REFACTOR: Improve code while keeping tests green
REPEAT:   Next scenario
```

## When to Use

- Implementing a new `DocsUI::` component or extending an existing one
- Adding a config knob to `DocsKit::Configuration`
- Changing the registry (`DocsKit::Registry` / `DocsKit::NavItem`)
- Extending the install generator
- Fixing a bug (write the reproducing test FIRST)

## Workflow

### Step 1: Write Failing Tests (RED)

Pick the cheapest layer that proves the behavior:

```ruby
# Config (no Rails): a new configuration knob
RSpec.describe DocsKit::Configuration do
  it "defaults on_page_default to :panel" do
    expect(described_class.new.on_page_default).to eq(:panel)
  end
end

# Component render: the produced markup given props
RSpec.describe DocsUI::ThemeSwitcher do
  it "renders every configured theme" do
    html = render(described_class.new(themes: %w[dark light]))
    expect(html).to include("dark").and include("light")
  end
end

# Registry: grouping / lookup
RSpec.describe DocsKit::Registry do
  it "groups docs by their declared group" do
    # ...
  end
end

# Generator: install writes the expected files
RSpec.describe "docs_kit:install" do
  it "creates the docs_kit initializer" do
    # ...
  end
end
```

### Step 2: Run — Verify FAIL

```bash
bundle exec rspec <spec_file>
# FAIL — confirms the test runs, tests the right thing, and the code doesn't already exist
```

### Step 3: Implement Minimal Code (GREEN)

### Step 4: Run — Verify PASS

```bash
bundle exec rspec <spec_file>
# N examples, 0 failures
```

### Step 5: Refactor

Improve while staying green: extract methods, improve names, reduce duplication.

### Step 6: Run Full Suite + Lint

```bash
bundle exec rspec
bundle exec rubocop
```

## Coverage Expectations

| Code | Minimum |
|------|---------|
| All code | 80% |
| `DocsKit::Configuration` (every knob + its default + override) | 100% |
| `DocsKit::Registry` (grouping, lookup, ordering) | 100% |

## Best Practices

**DO:** test FIRST; verify RED; minimal GREEN; refactor green; assert on
component **semantics** (an active link, a present theme option, a config-driven
value) via a real render; render through a real view context when url helpers /
`dom_id` are involved.

**DON'T:** implement before testing; assert brittle full-HTML snapshots; test
implementation details; hardcode a value a component should read from config.

## Checklist

- [ ] Tests written BEFORE implementation; RED verified
- [ ] Minimal GREEN; refactored green
- [ ] Coverage meets the bar (100% on config + registry)
- [ ] Edge cases covered (empty nav group, no version badge, JS-off render)
- [ ] `bundle exec rubocop` passes
