# Changelog

## [Unreleased]

### Added

- Initial extraction of the shared docs-site chrome into `docs-kit`.
- `Docs::*` Phlex component kit: `Shell` (full-document drawer layout), `Sidebar`
  (config-driven nav), `ThemeSwitcher`, `Icon`, `Code` (Rouge + inline theme),
  `Page`, `Header`, `Section`, `Prose`, `Callout`, `Example` (source extraction).
- `DocsKit.configure` for per-site brand, themes, nav, version badge, stylesheets,
  and code theme.
- `DocsKit::Registry` mixin for in-memory docs registries (slug/title/group +
  `all`/`from_slug`/`grouped` + the "authored" filter).
- `DocsKit::NavItem` value object consumed by the sidebar.
- `DocsKit::Controller#render_page` and a Rails engine that wires it.
- Custom RuboCop cops shipped from the gem (`require: docs_kit/rubocop` +
  `inherit_gem: { docs-kit: config/rubocop/docs_kit.yml }`, wired automatically by
  the install generator): `DocsKit/RenderComponentPreferred` (prefer the Phlex-kit
  helper form `DocsUI::Code(...)` over `render DocsUI::Code.new(...)`) and
  `DocsKit/EscapedInterpolationInHeredoc` (steer `\#{...}` escapes in a
  double-quoted heredoc to a single-quoted delimiter). RuboCop stays a
  development-time dependency of the host — never a runtime dependency.
