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
    c.themes       = %w[dark light synthwave retro cyberpunk dracula night nord sunset]

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

    # The sidebar nav derives from the registry — one heading → one registry.
    # Each registry's authored pages become NavItems automatically (an unwritten
    # page is skipped, so no dead links). For bespoke nav (interleaved
    # registries, custom subgroups) set a `c.nav` lambda instead; it wins.
    c.nav_registries = { "Docs" => Doc }
  end
end
