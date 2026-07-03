# Changelog

## [Unreleased]

### Added

- **SEO + social sharing.** Every page now emits a complete SEO `<head>` —
  meta description, Open Graph, Twitter Card, canonical, favicon, robots, and
  theme-color — via the new `DocsUI::MetaTags` component, driven entirely by a
  new `c.seo` config block (`DocsKit::SeoConfig`). Pages carry an authorable
  `description "..."` (falling back to the page's `#lead`). docs-kit ships a
  neutral 1200×630 default OG image, and installs a `docs_kit:og` rake task that
  screenshots a site's OWN landing page into `app/assets/images/og/` (host-side
  headless browser; never a gem runtime dependency). A guard spec keeps the
  shipped default present. Backwards-compatible: a site that sets no `c.seo`
  renders a valid minimal card and its `<head>` is a strict superset of before.
  The install generator documents `c.seo` and installs the task + default image;
  `docs-kit new` reminds the owner to run it. (#48)
- Release tooling matching the sibling gems (daisyui/phlex-reactive/pgbus): a
  `rake release[X.Y.Z]` task (version bump → lockfile update → build-verify →
  commit → push → GitHub Release; `pre`/`force` supported, `main`-only, clean-tree
  guard) and `.github/workflows/release.yml`, which on `release: published` runs
  the suite, content-checks the built gem, signs it with Sigstore, and publishes
  to RubyGems over **OIDC trusted publishing** (no stored API token). See the
  README "Releasing (maintainers)" section for the one-time trusted-publisher +
  `rubygems` environment setup.
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
- `rails g docs_kit:install --sync`: the sanctioned upgrade path for an existing
  site. Runs only the additive/wiring steps (routes, initializer hint,
  importmap/Stimulus registration, AGENTS.md, `.rubocop.yml`) — never
  re-scaffolds site-owned content (the `Doc` registry, pages, the themed CSS
  build) — and prints a conservative drift checklist (a hand-written
  `render_page`, a dead `IconHelper`) it warns about but never auto-deletes. See
  the README "Keeping a site in sync" section.

### Fixed

- `rails g docs_kit:install` is now fully idempotent, making re-running it the
  safe upgrade path: `create_initializer` no longer clobbers a site's edited
  `config/initializers/docs_kit.rb` (it skips + hints at the template for a
  diff), and `add_routes` no longer duplicates a route the site already drew when
  it was written in a different style (single vs double quotes, `to:` vs `=>`).
