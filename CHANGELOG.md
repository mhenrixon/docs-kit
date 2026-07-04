# Changelog

## [Unreleased]

### Fixed

- **SEO `og:image` 404.** The og:image tag pointed at the raw config path
  (`https://site/og/og.png`), which isn't a served URL — Propshaft serves the
  digested asset under `/assets`. A relative `og_image` is now resolved through
  the site's asset pipeline (`image_url`) to the digested `/assets/og/og-<digest>.png`
  URL, and the image is treated as **site content**: the gem ships none,
  `c.seo.og_image` defaults to **nil** (unset → no og:image tag, never a 404), and
  the `docs_kit:og` task writes into the *site's* `app/assets/images/`. Added a
  booted-app integration test in the dogfood site
  (`docs/test/integration/seo_meta_tags_test.rb`) that asserts og:image resolves
  to a `/assets` URL that actually returns 200 — the coverage isolated component
  specs can't provide.

### Added

- **`DocsUI::Landing` — a config-driven marketing landing page.** Every consuming
  site (and this dogfood site) was hand-rolling a home page; now render
  `DocsUI::Landing` and drive it from a new `c.landing` config block
  (`DocsKit::LandingConfig`): a hero (`eyebrow`, `title` — wrap a run in
  `**double asterisks**` to accent it in the primary color, `lead`, an optional
  `install` code snippet, and `ctas`), a `features` card grid, and a
  registry-grouped documentation index built from `nav_groups` (so it never drifts
  from the authored pages). Every field is optional — with an empty `c.landing` it
  still renders a minimal hero (brand + doc index), never a broken page — and its
  `.md`/`.text` twin works like any page. The install generator's `landings#show`
  now renders it and the initializer documents `c.landing`. This is the first
  landing pattern proven on a **mounted** docs app (a docs section inside a larger
  Rails app whose `/` is already taken), contributed back from that use case.
- **SEO + social sharing.** Every page now emits a complete SEO `<head>` —
  meta description, Open Graph, Twitter Card, canonical, favicon, robots, and
  theme-color — via the new `DocsUI::MetaTags` component, driven entirely by a
  new `c.seo` config block (`DocsKit::SeoConfig`). Pages carry an authorable
  `description "..."` (falling back to the page's `#lead`). The social-share image
  is site content (not shipped by the gem): the `docs_kit:og` rake task screenshots
  a site's OWN landing page into its `app/assets/images/og/` (host-side headless
  browser; never a gem runtime dependency), and `c.seo.og_image` points at it.
  Backwards-compatible: a site that sets no `c.seo` renders a valid minimal card
  and its `<head>` is a strict superset of before. The install generator documents
  `c.seo` and installs the task; `docs-kit new` reminds the owner to run it. (#48)
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
