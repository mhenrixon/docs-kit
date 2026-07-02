---
description: "Coordinates a change across the docs-kit layers. Use when planning a feature that spans the components, the config surface, and the install generator."
model: opus
argument-hint: "feature or task to coordinate"
---

# docs-kit Architect Mode

You are in **Architect Mode** — coordinating a change across all docs-kit layers.

## Why this exists

A docs-kit feature usually touches several layers in a specific order. Tackle
them out of order and you miss integration points (e.g. add a component that
reads a config value before the config knob exists) or ship a feature the CSS
build never learns to scan, or that new sites don't get because the install
generator wasn't updated.

## The layers

```
Layer 4: Client runtime   app/javascript/docs_kit/controllers/docs_nav_controller.js (ONE controller: collapse persistence + auto-TOC)
Layer 3: Components        app/components/docs_ui/ (Shell, Sidebar, ThemeSwitcher, Code, Page, Section, Header, Prose, Callout, Example, Icon, OnThisPage)
Layer 2: Registry + values lib/docs_kit/registry.rb, lib/docs_kit/nav_item.rb (in-memory docs registry, sidebar link value object)
Layer 1: Config + controller lib/docs_kit/configuration.rb (per-site knobs), lib/docs_kit/controller.rb (#render_page)
Layer 0: Core + engine     lib/docs_kit.rb, lib/docs_kit/engine.rb (auto-pins docs-nav, mounts assets)
         Install path       lib/generators/docs_kit/install/, lib/docs_kit/templates/new_site.rb, exe/docs-kit
         CSS contract       the consuming site's application.tailwind.css @source + @plugin themes
```

## Typical implementation flow (bottom-up)

1. **Config** — add the per-site knob (with a sensible default) if the feature is tunable
2. **Registry/values** — extend the in-memory registry or nav value object if the data shape changes
3. **Components** — the `DocsUI::` component that renders the feature from config
4. **Client runtime** — only if the feature needs client enhancement (add to the ONE `docs-nav` controller; never a new controller)
5. **Engine** — pin/mount anything new (usually already handled)
6. **Install path** — wire required setup into the generator templates AND the `docs-kit new` template so new sites get it
7. **CSS contract** — if new daisyUI/utility classes are emitted, update `@source` / `@source inline(...)` guidance
8. **Specs + docs** — tests at every touched layer; update README/docs pages

## Delegate vs. do directly

**Delegate** (Explore/Plan agents; pass `model: haiku`/`sonnet` for mechanical
reads) when: multiple files change, you need to sweep how a consuming site wires
docs-kit, or the work is cleanly scoped to one layer.

**Directly** when: a single-file change, or a cross-cutting concern (the config
contract, the CSS scan contract, progressive-enhancement) you must hold in your
head.

## Decision guide

| Decision | Use When |
|----------|----------|
| New config option | Feature needs per-site-configurable behavior |
| New `DocsUI::` component | A new piece of chrome / page-kit element is needed |
| Extend the registry | The docs/nav data shape changes |
| Client runtime change | The feature needs client-only enhancement (collapse, TOC, spy) |
| Install generator change | New sites need setup the feature requires |
| CSS `@source` update | The feature emits classes Tailwind must scan |

## Integration points

| When working on... | Also consider... |
|--------------------|------------------|
| A component reading new config | the `Configuration` default; backwards compat for sites that don't set it |
| The sidebar / nav | the registry data it consumes; the active-link server render; the `docs-nav` collapse persistence |
| The theme switcher | `config.themes` MUST match the Tailwind `@plugin "daisyui" { themes: ... }` list |
| The `docs-nav` controller | what DOM the components must emit for it to read (section anchors, `<details>`) |
| A required setup step | the install generator templates AND `docs-kit new` — both, or new sites break |
| New emitted classes | the CSS `@source` scan; Drawer/render-time classes need `@source inline(...)` |
| Config or a public API | the README + docs; backwards compatibility |

## Common mistakes

| Wrong | Right |
|-------|-------|
| Start with the component | Start with the config knob it reads |
| Hardcode a site value | Read from `DocsKit.configuration` |
| Add a per-feature Stimulus controller | Extend the ONE `docs-nav` controller |
| Require JS for the page to work | Server-render working; JS enhances |
| Document setup in README only | Also wire the install generator + `docs-kit new` |
| Emit new classes, forget the scan | Update `@source` so Tailwind generates them |
| Add a theme to config, not the CSS | Keep `config.themes` and the `@plugin` list in sync |

## Verification checklist

- [ ] Implementation order planned (bottom-up)
- [ ] Config default set; existing sites unaffected (backwards compatible)
- [ ] New setup wired into the install generator AND `docs-kit new`
- [ ] CSS scan updated if new classes are emitted
- [ ] Page works with JS off (progressive enhancement)
- [ ] Tests cover every touched layer
- [ ] `bundle exec rubocop` + `bundle exec rspec` pass

## Handoff

Summarize: the layer-ordered plan, files per layer, integration points, the
install-path story (how new sites get it), the CSS contract, and the
architectural decisions made.

Now coordinate the change with this architectural perspective.
