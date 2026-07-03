# frozen_string_literal: true

module Views
  module Docs
    module Pages
      class Configuration < DocsUI::Page
        title "Configuration"
        eyebrow "Getting started"

        def lead = "One initializer drives the shared chrome — brand, themes, and sidebar nav differ per site; the shell does not."

        def content
          configure_section
          all_options_section
          sidebar_nav_section
          themes_section
        end

        private

        def configure_section
          DocsUI::Section("DocsKit.configure", description: "Set it once; the shared chrome reads it everywhere.") do
            prose do
              p do
                plain "Everything that differs between sites lives here — "
                code { "brand" }
                plain ", "
                code { "themes" }
                plain ", the sidebar "
                code { "nav" }
                plain ". The Shell, Sidebar, and ThemeSwitcher are identical across every site that uses docs-kit; only this config changes."
              end
              p do
                plain "Configure inside "
                code { "config.to_prepare" }
                plain " so the block re-runs on every code reload and the "
                code { "nav" }
                plain " callable always sees the current Doc registry in development."
              end
            end
            DocsUI::Code(<<~RUBY, filename: "config/initializers/docs_kit.rb")
              Rails.application.config.to_prepare do
                DocsKit.configure do |c|
                  c.brand           = "Acme Docs"
                  c.title_suffix    = "Acme"                      # "Installation · Acme"
                  c.themes          = %w[dark light dracula night]
                  c.default_theme   = "dark"
                  c.code_theme      = "Rouge::Themes::Monokai"
                  c.version_badge   = -> { "v\#{Acme::VERSION}" }
                  c.on_page_default = :panel                      # :panel | :toggle | :sidebar | false

                  c.nav = lambda do
                    docs = Doc.all.group_by(&:group).transform_values do |items|
                      items.map { |d| DocsKit::NavItem.new(href: "/docs/\#{d.slug}", label: d.title) }
                    end
                    { "Docs" => docs }
                  end
                end
              end
            RUBY
          end
        end

        def all_options_section
          DocsUI::Section("All options", description: "Every setting on the config object, with its default.") do
            render PropTable.new(
              [ "Option", "Type", "Default", "Description" ],
              [
                [ "brand", "String", '"Docs"', "Topbar + sidebar heading." ],
                [ "title_suffix", "String", "= brand", %(Appended to <title> ("Installation · brand").) ],
                [ "themes", "Array", "%w[dark light]", "ThemeSwitcher options; must match the daisyUI @plugin themes: block." ],
                [ "default_theme", "String", "= themes.first", "data-theme applied on first paint." ],
                [ "nav", "callable", "-> {}", %(Returns the sidebar nav Hash { "Heading" => { "Subgroup" => [items] } }; items respond to #href, #label, optional #icon.) ],
                [ "version_badge", "callable", "nil", %(Returns a short badge string for the sidebar header, e.g. -> { "v1.2.3" }.) ],
                [ "stylesheets", "Array", "%w[application]", "Stylesheet logical names linked in <head>, in order." ],
                [ "code_theme", "String", '"Rouge::Themes::Monokai"', "Rouge theme class for inline highlight CSS." ],
                [ "default_group_icon", "String", '"file-text"', "lucide icon for a nav group with no explicit icon." ],
                [ "nav_storage_key", "String", "= brand slug", "Namespaces localStorage keys so two sites on one origin don't collide." ],
                [ "on_page_default", ":panel | :toggle | :sidebar | false", ":panel", "Default auto-TOC placement." ],
                [ "code_lexer_aliases", "Hash", "{}", %(Friendly-name→Rouge lexer aliases, merged over built-ins ({ curl: "console" }).) ],
                [ "code_lexer_fallback", "String", '"plaintext"', "Lexer when a language can't be resolved." ],
                [ "code_language_labels", "Hash", "{}", %(Human labels for Example language tabs, merged over built-ins ({ elixir: "Elixir" }).) ]
              ]
            )
          end
        end

        def sidebar_nav_section
          DocsUI::Section("The sidebar nav", description: "A callable that maps your registry into the shared sidebar shape.") do
            prose do
              p do
                plain "Set "
                code { "c.nav" }
                plain " to a callable returning a two-level Hash: "
                code { '{ "Heading" => { "Subgroup" => [items] } }' }
                plain ". Each item must respond to "
                code { "#href" }
                plain " and "
                code { "#label" }
                plain ", and may respond to "
                code { "#icon" }
                plain " (a lucide name)."
              end
              p do
                plain "Wrap your own registry rows in "
                code { "DocsKit::NavItem" }
                plain " so the sidebar stays registry-agnostic — it never touches your models directly."
              end
            end
            DocsUI::Code(<<~RUBY)
              c.nav = lambda do
                grouped = Doc.all.group_by(&:group).transform_values do |docs|
                  docs.map do |doc|
                    DocsKit::NavItem.new(href: "/docs/\#{doc.slug}", label: doc.title)
                  end
                end

                {
                  "Getting started" => { "Basics" => grouped.fetch("basics", []) },
                  "Reference"       => { "API" => grouped.fetch("api", []) }
                }
              end
            RUBY
          end
        end

        def themes_section
          DocsUI::Section("Themes", description: "The theme list is the contract between config and CSS.") do
            prose do
              p do
                plain "The values in "
                code { "c.themes" }
                plain " must match the daisyUI "
                code { "@plugin \"daisyui\" { themes: ... }" }
                plain " block in your Tailwind entry. The first entry is the default unless you set "
                code { "c.default_theme" }
                plain " explicitly."
              end
              p do
                plain "See the "
                a(href: "/docs/styling") { "Styling" }
                plain " page for wiring up the daisyUI plugin and the Rouge highlight CSS."
              end
            end
            DocsUI::Callout(:warning) do
              "A theme listed in c.themes but not enabled in the CSS @plugin themes: block won't apply — the ThemeSwitcher shows it, but daisyUI has no tokens for it. Keep the two lists in sync."
            end
          end
        end
      end
    end
  end
end
