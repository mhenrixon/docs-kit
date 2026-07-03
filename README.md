# docs-kit

[![CI](https://github.com/mhenrixon/docs-kit/actions/workflows/ci.yml/badge.svg)](https://github.com/mhenrixon/docs-kit/actions/workflows/ci.yml)

Shared [Phlex](https://www.phlex.fun) chrome for documentation sites built on
[daisyUI](https://daisyui.com). Extract the shell, sidebar, code blocks, theme
switcher, and page kit into one gem so multiple docs sites look identical and are
maintained in one place.

Reactive demos ([phlex-reactive](https://github.com/mhenrixon/phlex-reactive))
and Postgres-SSE transport ([pgbus](https://github.com/mhenrixon/pgbus)) are
**optional, runtime-detected** add-ons — docs-kit does not depend on them.

## What you get

A `DocsUI::` Phlex kit, configured once per site:

| Component | Role |
|-----------|------|
| `DocsUI::Shell` | The full HTML document: daisyUI Drawer shell, sticky topbar, sidebar, scrollable main. |
| `DocsUI::Sidebar` | Config-driven grouped nav with active-link highlighting + an optional version badge. |
| `DocsUI::ThemeSwitcher` | Zero-JS daisyUI theme dropdown (themes come from config). |
| `DocsUI::Icon` | Inline lucide SVG via `rails_icons`. |
| `DocsUI::Code` | Rouge-highlighted code block (any of Rouge's ~200 languages) with an inline theme. |
| `DocsUI::Page` | Base class for a hand-authored doc page; renders inside `DocsUI::Shell`. |
| `DocsUI::Header` / `Section` / `Prose` / `Callout` | The page-authoring kit. |
| `DocsUI::Markdown` | GFM Markdown island — prose as Markdown, styled like `Prose`, fenced code through Rouge. |
| `DocsUI::Table` / `PropTable` | Reference tables — generic headers+rows, and a name/type/default/description preset. |
| `DocsUI::Endpoint` | HTTP method badge (coloured per verb) + monospace path; renders inline (drops into a `Section` description). |
| `DocsUI::FieldTable` / `ErrorTable` | API-reference presets over `Table` — an object's fields, and an endpoint's errors (Param column auto-hidden when unused). |
| `DocsUI::Example` | Base for a live example with `method_source`-extracted source. |

Plus `DocsKit::Registry` (in-memory docs registry mixin), `DocsKit::NavItem`
(sidebar link value object), and `DocsKit::Controller#render_page`.

## Install

```ruby
# Gemfile
gem "docs-kit"
gem "daisyui", require: "daisy_ui"   # the daisyUI Phlex components
gem "phlex-rails"
gem "rails_icons", "~> 1.1"
gem "rouge"
# Optional, for reactive demos:
# gem "phlex-reactive"
```

## Configure (per site)

```ruby
# config/initializers/docs_kit.rb
DocsKit.configure do |c|
  c.brand        = "phlex-reactive"
  c.title_suffix = "phlex-reactive"
  c.themes       = %w[dark light synthwave retro cyberpunk dracula night nord sunset]
  c.version_badge = -> { "v#{Phlex::Reactive::VERSION}" }   # optional

  # The sidebar derives from your registries — one heading → one registry.
  c.nav_registries = { "Docs" => Doc }
end
```

The nav is **derived from the registry**, so you never hand-write it. Each
registry maps a heading to its authored pages (`Doc.nav_items`); a page that
isn't written yet is skipped, so there are no dead links. Register a page with
one line (see [Add a page](#add-a-page)) and it appears in the sidebar.

### Custom nav (advanced)

Sites that interleave several registries under a heading, or need custom
subgroups, set an explicit `c.nav` lambda instead — it wins over
`nav_registries`:

```ruby
c.nav = lambda do
  {
    "Demos" => Demo.grouped.transform_values { |demos|
      demos.map { |d| DocsKit::NavItem.new(href: "/demos/#{d.slug}", label: d.title, icon: d.icon) }
    },
    "Docs" => Doc.nav_items
  }
end
```

## Render

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include DocsKit::Controller   # adds #render_page
end

# any page controller
def show = render_page(Views::Docs::Pages::Installation.new)
```

`render_page(view)` renders the Phlex page with `layout: false`, because
`DocsUI::Shell` IS the full HTML document. phlex-rails still renders through a real
view context, so CSRF, `dom_id`, url helpers, and the reactive token signer all
work inside components.

### Add a page

One command scaffolds the page class **and** its registry line, both derived
from the title:

```bash
rails g docs_kit:page "Getting Started" --group=Guide
```

That writes `app/views/docs/pages/getting_started.rb` (a `DocsUI::Page` subclass
with a starter Markdown section) and injects `page "Getting Started", group:
"Guide"` into your `Doc` registry — so the page is routed and in the sidebar the
moment you write its content. Every derivation is overridable:

```bash
rails g docs_kit:page "OAuth" --group=Guide --slug=auth --view=OauthGuide
rails g docs_kit:page "Metrics" --group=Reference --eyebrow="Advanced"
rails g docs_kit:page "Guides Intro" --group=Guide --registry=Guide  # a differently-named registry
```

Re-running is idempotent (no duplicate registry line, no clobbered file). If your
registry still uses the legacy hash `entries [...]` form, the generator writes
the page but prints the entry for you to add by hand instead of corrupting it.

#### Under the hood

A page is a `DocsUI::Page` subclass — the generator just writes this for you:

```ruby
# app/views/docs/pages/getting_started.rb — Zeitwerk resolves the compact
# reference through the directory-implied namespaces (no nested modules).
class Views::Docs::Pages::GettingStarted < DocsUI::Page
  title "Getting Started"
  eyebrow "Guide"
  def lead = "Add the gem and render your first component."

  def content
    DocsUI::Section("Add the gem") do
      md <<~'MD'
        Components are plain Ruby classes.
      MD
      DocsUI::Code(<<~RUBY, filename: "Gemfile")
        gem "docs-kit"
      RUBY
    end
  end
end
```

…plus one line in the registry (`view_namespace` lets it derive the class):

```ruby
# app/models/doc.rb
class Doc
  extend DocsKit::Registry
  path_prefix    "/docs"
  view_namespace "Views::Docs::Pages"

  page "Getting Started", group: "Guide"   # slug "getting-started", view "GettingStarted"
end
```

`DocsUI::Page` includes the kit, so inside `#content` you call the components
directly — `DocsUI::Section(...)`, `DocsUI::Code(...)` — no `render … .new`.

### The authoring convention

One rule covers the whole kit: **the primary argument is positional; modifiers
are keyword arguments.**

```ruby
DocsUI::Header("Installation", eyebrow: "Guide")      # title positional
DocsUI::Section("Add the gem", id: "add", description: …)  # title positional
DocsUI::Code(source, lexer: :ruby, filename: "Gemfile")   # source positional
```

For the two wrappers that take **no** positional argument — prose and a
multi-language example — `DocsUI::Page` gives you lowercase helpers so a block
needs no parens:

```ruby
prose   { p { "Hand-authored prose." } }          # → DocsUI::Prose
example { |ex| ex.code(:ruby) { source } }         # → DocsUI::Example
md(<<~'MD')                                         # → DocsUI::Markdown
  A block of **Markdown**.
MD
```

The kit forms `DocsUI::Prose() { … }` / `DocsUI::Example() { … }` still work —
they just need the empty `()`, because a bare `DocsUI::Prose do … end` parses as
a constant reference (a Ruby `SyntaxError`). The lowercase helpers sidestep that
entirely, so they're the everyday path.

## Authoring with Markdown

Prose is the most-written content type — and the noisiest to hand-build from
`p`/`code`/`plain` calls. `DocsUI::Page` gives you `md(source)`: write a block of
GitHub-Flavored Markdown and it renders styled identically to `DocsUI::Prose`,
with fenced code routed through `DocsUI::Code` (Rouge).

```ruby
def content
  DocsUI::Section("Configure") do
    md <<~'MD'
      Set `brand` and `themes` in the initializer. Everything that differs
      between two sites is **configuration**, not markup:

      - `brand` — the topbar/sidebar heading,
      - `themes` — the ThemeSwitcher options.

      ```ruby
      DocsKit.configure { |c| c.brand = "My Docs" }
      ```

      | Option | Type   |
      |--------|--------|
      | brand  | String |
      | themes | Array  |
    MD
  end
end
```

That renders paragraphs, **bold**/*italic*, inline `code`, links, bullet/ordered
lists, block quotes, GFM tables (with the kit's table classes), and
strikethrough. A fenced ` ```ruby ` block is highlighted by Rouge exactly like a
hand-written `DocsUI::Code`; an unknown fence language falls back to plaintext.

Two things to know:

- **`md` is a lowercase page helper (like `prose`/`example`), so `md <<~MD … MD`
  needs no parens** — see [the authoring convention](#the-authoring-convention).
- **Use a single-quoted heredoc, `<<~'MD'`.** Then `#{…}` in your prose is
  literal text (Phlex escapes author text — no `html_safe`, no interpolation).

Markdown headings render as styled `h3`/`h4`. Document **structure and the "On
this page" TOC still come from `DocsUI::Section`** — keep section titles as
`Section`, and use Markdown headings only for sub-headings inside a section. Raw
HTML in the Markdown source is dropped (no `<script>`, no passthrough).

## Scaffold a new docs site in one command

```bash
docs-kit new my-docs                       # → a complete, deployable docs app
docs-kit new my-docs --image mhenrixon/my-repo --service my-repo
```

`docs-kit new` runs `rails new` (propshaft + importmap + turbo/stimulus, no DB)
and applies docs-kit's application template, which:

- adds docs-kit + its deps to the Gemfile,
- runs `rails g docs_kit:install` (initializers, controllers, a Doc registry, a
  sample guide page, the Bun/Tailwind build, the docs-nav Stimulus wiring),
- syncs the lucide icons and builds the CSS,
- scaffolds Kamal (`config/deploy.yml`, `.kamal/secrets`, `Dockerfile`) and a
  thin `.github/workflows/deploy-docs.yml` that calls the reusable workflow.

Then `cd my-docs && bin/dev`. Already have a Rails app? Run the install generator
instead:

```bash
rails g docs_kit:install
rails g rails_icons:sync --library=lucide
bun install && bun run build:css
```

Then add pages one command at a time — `rails g docs_kit:page "Title"
--group=Guide` (see [Add a page](#add-a-page)).

## Deploy a new docs site

The build + deploy is defined **once** in this gem's reusable workflow
(`.github/workflows/deploy.yml`). `docs-kit new` scaffolds the caller for you; to
wire it by hand a site adds five small things and it deploys to the
oss-infrastructure server (Kamal + GHCR + Cloudflare Tunnel).

**1. A thin caller** — `.github/workflows/deploy-docs.yml`:

```yaml
name: Deploy docs
on:
  release: { types: [published] }
  workflow_dispatch:
jobs:
  deploy:
    uses: mhenrixon/docs-kit/.github/workflows/deploy.yml@main
    with:
      image: mhenrixon/<repo>     # OWNER/REPO — see naming note below
      service: <repo>
    secrets: inherit
```

**2. `docs/config/deploy.yml`** — `service:` and `image:` MUST match the caller:

```yaml
service: <repo>
image: mhenrixon/<repo>
registry: { server: ghcr.io, username: mhenrixon, password: [KAMAL_REGISTRY_PASSWORD] }
builder: { arch: amd64, context: .., dockerfile: Dockerfile }   # repo root = build context
proxy:   { host: <%= ENV["DEPLOY_DOMAIN"] %>, app_port: 3000, ssl: false, healthcheck: { path: /up } }
servers: { web: { hosts: [<%= ENV["DEPLOY_HOST"] %>] } }
ssh:     { user: oss }
```

**3. `docs/Dockerfile`** — end the final stage with the matching label:

```dockerfile
LABEL service="<repo>"
```

**4. `docs/.kamal/secrets`** — `KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD`.

**5. GitHub** — a `docs` environment with secrets `SSH_PRIVATE_KEY`,
`DEPLOY_HOST`, `DEPLOY_DOMAIN`. (The registry password is the auto-provided
`GITHUB_TOKEN` — no PAT.)

> **Naming — use the repo name, not `<repo>-docs`.** `image`/`service` must be
> the calling repo's `OWNER/REPO`. Pushing `ghcr.io/mhenrixon/<repo>` from the
> repo's own Actions run auto-links the package to the repo, so `GITHUB_TOKEN`
> can both push (build job) and pull (deploy) it. A different name becomes an
> unlinked user-scoped package `GITHUB_TOKEN` can't pull → the deploy fails.

**First deploy per host:** run `kamal setup` (or `bin/deploy setup`) once to boot
any accessories (e.g. a Postgres accessory); the release workflow runs plain
`kamal deploy`, which doesn't boot accessories.

## CSS — the canonical build

daisyUI (and docs-kit) ship **no CSS** — your app builds Tailwind. To keep sites
identical, docs-kit standardizes on **Tailwind CSS v4 via the standalone CLI
(Bun)**.

`app/assets/stylesheets/application.tailwind.css`:

```css
@import "tailwindcss";
@plugin "daisyui" {
  themes: dark --default, light, synthwave, retro, cyberpunk, dracula, night, nord, sunset;
}

/* Tailwind must scan the Ruby that emits classes — the daisyUI gem, docs-kit,
   and your own views. */
@source "../../../app/views/**/*.rb";
@source "../../../../.bundle/gems/daisyui*/**/*.rb";
@source "../../../../.bundle/gems/docs-kit*/**/*.rb";
/* daisyUI Drawer classes are generated at render time, never literal — force them: */
@source inline("drawer drawer-content drawer-side drawer-toggle drawer-overlay {lg:}drawer-open drawer-end");
```

`package.json`:

```json
{
  "scripts": {
    "build:css": "bunx @tailwindcss/cli -i app/assets/stylesheets/application.tailwind.css -o app/assets/builds/application.css --minify",
    "watch:css": "bunx @tailwindcss/cli -i app/assets/stylesheets/application.tailwind.css -o app/assets/builds/application.css --watch"
  }
}
```

The themes in `@plugin "daisyui" { themes: ... }` **must** match
`DocsKit.configuration.themes`, or the switcher offers a theme the CSS doesn't
ship.

## JavaScript

docs-kit ships **one** Stimulus controller, `docs-nav`, auto-pinned by the engine
(like the daisyUI gem's dropdown controller). It's client-only UX polish — no
server round-trip:

- **Collapse persistence** — remembers which sidebar `<details>` the reader
  opened/closed (localStorage, namespaced by `config.nav_storage_key`), so the
  sidebar stays how they left it across navigations. The server always renders
  every section `open`, so with JS off the sidebar is simply fully expanded
  (progressive enhancement).
- **"On this page" auto-TOC** — collects the current page's `DocsUI::Section`
  anchors from the DOM and renders a live, scroll-spied table of contents in one
  of three placements, auto-hiding on short pages. No server-side knowledge of
  the headings, no per-page wiring.

### On this page (auto-TOC)

`DocsUI::Page` renders it automatically. The placement is a strategy — set the
site-wide default, override per page:

```ruby
DocsKit.configure { |c| c.on_page_default = :panel }   # :panel | :toggle | :sidebar | false

class Views::Docs::Pages::Installation < DocsUI::Page
  on_page :toggle   # override just this page; `false` opts out
end
```

| Mode | Placement |
|------|-----------|
| `:panel` (default) | A sticky card floating top-right of the content column. |
| `:toggle` | A sticky floating button (top-right) that opens a dropdown. |
| `:sidebar` | Nested under the active nav item in the left sidebar (GitBook-style). |

All three are driven by the same `docs-nav` controller reading the page's
headings, so they need zero per-page data. A page with fewer than 2 sections
hides the TOC. Scroll-spy highlights the section you're reading.

`DocsUI::Sidebar` already carries `data-controller="docs-nav"`. Register the
controller in the host app:

```js
// app/javascript/controllers/index.js
import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
lazyLoadControllersFrom("docs_kit/controllers", application)
```

The **active nav item** needs no JS — it's server-rendered from the request path.

Reactive sites also load the auto-pinned `phlex/reactive/reactive_controller`
(from phlex-reactive) and register it eagerly:

```js
import ReactiveController from "phlex/reactive/reactive_controller"
application.register("reactive", ReactiveController)
```

## License

MIT.
