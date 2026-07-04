# frozen_string_literal: true

# docs-kit configuration — everything that makes this site look like YOUR docs.
# The shared chrome (Shell/Sidebar/ThemeSwitcher/Code/Page) comes from the gem;
# only this config differs per site. The `themes` MUST match the
# @plugin "daisyui" { themes: ... } block in
# app/assets/stylesheets/application.tailwind.css.
Rails.application.config.to_prepare do
  DocsKit.configure do |c|
    c.brand        = "docs-kit"
    c.title_suffix = "docs-kit"
    # The one-line summary in /llms.txt (the llmstxt.org blockquote). Default nil
    # omits the line; set it so AI agents get a crisp description of the site.
    c.tagline      = "Shared Phlex/daisyUI chrome for documentation sites — one shell, sidebar, code kit, and page kit across every docs site."
    c.themes       = %w[dark light synthwave retro cyberpunk dracula night nord sunset]

    # A link to the source repo in the topbar (next to the theme switcher),
    # rendered with the shipped GitHub brand mark. Dogfoods c.topbar_links.
    c.topbar_links = [
      { href: "https://github.com/mhenrixon/docs-kit", label: "GitHub", icon: :github }
    ]

    # SEO + social sharing, dogfooded. docs-kit emits the full <head> (description,
    # Open Graph, Twitter Card, canonical) from these knobs. og_image points at an
    # image in THIS site's own pipeline (app/assets/images/og/og.png) — resolved
    # to its digested /assets URL — regenerate it with `bin/rails docs_kit:og`.
    c.seo.description  = "Shared Phlex/daisyUI chrome for documentation sites — one shell, sidebar, code kit, and page kit."
    c.seo.og_image     = "og/og.png"
    c.seo.twitter_site = "@mhenrixon"
    c.seo.site_url     = "https://docs-kit.zoolutions.llc"

    # Code blocks carry a light theme by default and swap to a dark theme when the
    # switcher lands on a dark daisyUI theme (dark/synthwave/dracula/night/sunset
    # here). Dogfooded so the light↔dark restyle is visible across all 9 themes;
    # it's CSS-only ([data-theme=X] scoping), so there's no JS and no flash.
    c.code_theme      = "Rouge::Themes::Github"  # light themes
    c.code_theme_dark = "Rouge::Themes::Monokai" # dark themes (see c.dark_themes)

    # Any language Rouge knows works in code blocks out of the box. Add friendly
    # aliases/labels here if you use custom names:
    # c.code_lexer_aliases  = { curl: "console" }
    # c.code_language_labels = { elixir: "Elixir" }

    # The OpenAPI bridge, dogfooded: the "OpenAPI bridge" page renders a whole
    # endpoint with `operation "createInvoice"` derived from this spec — badge,
    # field/error tables, request tabs, and response, with zero hand-restatement.
    c.openapi = Rails.root.join("openapi.yaml")

    # The sidebar nav derives from the registry — one heading → one registry.
    # Each registry's authored pages become NavItems automatically (an unwritten
    # page is skipped, so no dead links); the page `group:` values render as the
    # collapsible sub-groups (Getting started / Authoring / Reference / AI &
    # tooling / Deploy). For bespoke nav (interleaved registries) set a `c.nav`
    # lambda instead; it wins.
    c.nav_registries = { "Docs" => Doc }

    # The landing page (DocsUI::Landing), dogfooded — a hero + feature grid + a
    # registry-grouped doc index, all from config. A **run** in the title renders
    # in the primary color. See LandingsController#show (render_page).
    c.landing.eyebrow  = "docs-kit"
    c.landing.title    = "Shared docs chrome for **Rails**, in Phlex."
    c.landing.lead     = "The shell, sidebar, theme switcher, syntax highlighting, " \
                         "multi-language examples, and an automatic table of contents — " \
                         "configure it once, write your pages, deploy with one workflow. " \
                         "This site is built with docs-kit."
    c.landing.install  = { code: 'gem "docs-kit"', filename: "Gemfile", lexer: :ruby }
    c.landing.ctas = [
      { label: "Get started",      href: "/docs/installation", style: :primary },
      { label: "Browse components", href: "/docs/components",   style: :ghost },
      { label: "GitHub", href: "https://github.com/mhenrixon/docs-kit", style: :ghost, icon: :github }
    ]
    c.landing.features = [
      { icon: "layout-template", title: "One shared shell",
        body: "The topbar, drawer sidebar, theme switcher, and content column — identical across every site, driven by config." },
      { icon: "code", title: "Syntax + multi-language examples",
        body: "Rouge highlighting with a light/dark theme pair, and tabbed code with a sticky global language choice." },
      { icon: "list-tree", title: "Registry-driven nav & search",
        body: "One `page` declaration feeds the sidebar, the search index, and llms.txt — they never drift from your pages." },
      { icon: "file-text", title: "Markdown twins + llms.txt",
        body: "Every page has a .md twin and an llms.txt index for free, derived from the same render your readers see." },
      { icon: "plug", title: "API-reference kit",
        body: "DocsUI::Endpoint / FieldTable / RequestExample turn one declaration into a badge, tables, and a tab per client." },
      { icon: "rocket", title: "Deploy with one workflow",
        body: "Scaffold a deployable site with `docs-kit new`, or add it to an existing Rails app with the install generator." }
    ]
  end
end
