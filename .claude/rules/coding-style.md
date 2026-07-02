# Coding Style Rules

## File Organization

**MANY SMALL FILES > FEW LARGE FILES**

- High cohesion, low coupling
- 200-400 lines typical
- 800 lines maximum per file
- Extract complex logic to dedicated classes
- Organize by concern (core/config, registry, components, controller, generators)

## Ruby Style

Lint with **RuboCop** (`bundle exec rubocop`). RuboCop owns formatting —
don't hand-fight it; run `rubocop -A` and review.

### Classes & Methods

```ruby
# Good: small, focused methods
def render_page(view)
  render html: view.call.html_safe, layout: false
end

# Bad: one giant method doing config lookup, rendering, layout selection, and error handling
```

### Everything is a Phlex component

```ruby
# Good: the docs chrome is composed from DocsUI:: Phlex components
render DocsUI::Section.new("Add the gem") do
  render DocsUI::Code.new(source, filename: "Gemfile")
end

# Bad: raw daisyUI markup hand-written in an ERB partial (defeats the shared kit)
```

### Configuration flows one direction

```ruby
# Good: read site-specific settings from DocsKit.configuration
themes = DocsKit.configuration.themes
render DocsUI::ThemeSwitcher.new(themes:)

# Bad: hardcode the theme list inside a component (each site can't override it)
```

### Progressive enhancement — the server renders a working page

```ruby
# Good: the sidebar renders every section `open`; docs-nav JS only *persists*
# collapse state. With JS off, the sidebar is simply fully expanded.
details(open: true) { ... }

# Bad: rely on JS to expand the nav — a no-JS reader sees a collapsed, unusable sidebar
```

### One Stimulus controller, auto-pinned

```ruby
# Good: docs-kit ships ONE controller (docs-nav), pinned by the engine. Client-only
# UX polish (collapse persistence, auto-TOC) — no per-feature JS, no server round-trip.

# Bad: a new Stimulus controller per page/feature, or server-side knowledge of headings
```

### Themes must match the CSS build

```ruby
# Good: DocsKit.configuration.themes matches @plugin "daisyui" { themes: ... }
# in application.tailwind.css — the switcher only offers themes the CSS ships.

# Bad: add a theme to config the Tailwind build never generated (dead switcher entry)
```

## Code Quality Checklist

Before marking work complete:
- [ ] Code is readable and well-named
- [ ] Methods are small (<30 lines ideal, <50 max)
- [ ] Files are focused (<800 lines)
- [ ] No deep nesting (>4 levels)
- [ ] Chrome is composed from `DocsUI::` Phlex components — no raw daisyUI markup
- [ ] Site-specific values come from `DocsKit.configuration`, not hardcoded
- [ ] The page works with JavaScript off (progressive enhancement)
- [ ] Themes offered by the switcher exist in the Tailwind build
- [ ] `bundle exec rubocop` passes
