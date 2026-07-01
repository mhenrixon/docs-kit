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
    c.code_theme   = "Rouge::Themes::Monokai"

    # Any language Rouge knows works in code blocks out of the box. Add friendly
    # aliases/labels here if you use custom names:
    # c.code_lexer_aliases  = { curl: "console" }
    # c.code_language_labels = { elixir: "Elixir" }

    # The sidebar nav: an ordered { "Heading" => { "Subgroup" => [NavItem] } }.
    c.nav = lambda do
      docs = Doc.all.select(&:view_class).group_by(&:group).transform_values do |items|
        items.map { |d| DocsKit::NavItem.new(href: "/docs/#{d.slug}", label: d.title) }
      end
      { "Docs" => docs }.reject { |_, v| v.empty? }
    end
  end
end
