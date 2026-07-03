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
      { href: "https://github.com/mhenrixon/docs-kit", label: "GitHub", icon: :github },
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
  end
end
