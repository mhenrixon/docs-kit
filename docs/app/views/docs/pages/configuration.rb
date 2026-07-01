# frozen_string_literal: true

module Views
  module Docs
    module Pages
      class Configuration < DocsUI::Page
        title "Configuration"
        eyebrow "Guide"

        def lead = "Everything that makes a site distinct lives in one initializer."

        def content
          DocsUI::Section("DocsKit.configure", description: "Set it once; the shared chrome reads it everywhere.") do
            DocsUI::Prose() do
              p do
                plain "The shell, sidebar, and theme switcher are shared across sites — only "
                code { "DocsKit.configure" }
                plain " differs. The "
                code { "themes" }
                plain " list must match the daisyUI @plugin block in your Tailwind entry."
              end
            end
            DocsUI::Code(<<~RUBY, filename: "config/initializers/docs_kit.rb")
              DocsKit.configure do |c|
                c.brand        = "docs-kit"
                c.themes       = %w[dark light synthwave dracula night]
                c.code_theme   = "Rouge::Themes::Monokai"
                c.on_page_default = :panel   # :panel | :toggle | :sidebar | false
                c.nav = -> { { "Docs" => Doc.grouped } }
              end
            RUBY
          end

          DocsUI::Section("Sidebar nav") do
            DocsUI::Prose() do
              p do
                plain "The nav is a callable returning "
                code { '{ "Heading" => { "Subgroup" => [NavItem] } }' }
                plain ". Map your registry to "
                code { "DocsKit::NavItem" }
                plain "s so the sidebar stays registry-agnostic."
              end
            end
            DocsUI::Code(<<~RUBY)
              c.nav = lambda do
                docs = Doc.all.select(&:view_class).group_by(&:group).transform_values do |items|
                  items.map { |d| DocsKit::NavItem.new(href: "/docs/\#{d.slug}", label: d.title) }
                end
                { "Docs" => docs }
              end
            RUBY
          end

          DocsUI::Section("On this page") do
            DocsUI::Prose() do
              p { "The auto-TOC placement is a strategy — set the default, override per page:" }
            end
            DocsUI::Code(<<~RUBY)
              class Views::Docs::Pages::Api < DocsUI::Page
                on_page :toggle   # or :panel / :sidebar / false
              end
            RUBY
          end
        end
      end
    end
  end
end
