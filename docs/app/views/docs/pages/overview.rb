# frozen_string_literal: true

module Views
  module Docs
    module Pages
      # The introduction page: what docs-kit is and the mental model behind it.
      class Overview < DocsUI::Page
        title "Overview"
        eyebrow "Getting started"

        def lead = "The shared Phlex chrome for a Rails docs site — you write page bodies, docs-kit renders the rest."

        def content
          what_is_section
          mental_model_section
          what_you_get_section
          next_steps_section
        end

        private

        def what_is_section
          DocsUI::Section("What is docs-kit", description: "A gem, not a template.") do
            prose do
              p do
                strong { "docs-kit" }
                plain " is a Ruby gem that gives you the shared chrome for a Rails "
                plain "documentation site: the topbar, the responsive sidebar, the theme "
                plain "switcher, the content column, an automatic "
                plain %("On this page" TOC, and syntax-highlighted code blocks.)
              end
              p do
                plain "It's built on "
                code { "phlex-rails" }
                plain " and "
                code { "daisyUI" }
                plain ". You write page bodies as Phlex components — docs-kit renders everything around them."
              end
            end
          end
        end

        def mental_model_section
          DocsUI::Section("The mental model", description: "Configure the chrome; don't re-author it.") do
            prose do
              p do
                plain "The chrome — "
                code { "Shell" }
                plain ", "
                code { "Sidebar" }
                plain ", "
                code { "Page" }
                plain " — is byte-identical across every site that uses docs-kit. The only thing "
                plain "that differs is "
                code { "DocsKit.configure" }
                plain "."
              end
              p do
                plain "That's the whole point: two sites built with docs-kit look and behave "
                plain "consistently for free, because they share the same components. You change "
                plain "the brand, the themes, and the nav — never the layout code."
              end
            end

            DocsUI::Code(<<~RUBY, filename: "config/initializers/docs_kit.rb")
              DocsKit.configure do |c|
                c.brand  = "My Project"     # only this differs per site
                c.themes = %w[dark light]   # the chrome itself is identical
              end
            RUBY

            DocsUI::Callout(:tip) do
              "This very site is built with docs-kit — the topbar, sidebar, and TOC " \
                "you're looking at are the exact chrome your site will get."
            end
          end
        end

        def what_you_get_section
          DocsUI::Section("What you get", description: "Everything below ships in the box.") do
            prose do
              ul do
                li do
                  strong { "Shared shell + responsive sidebar" }
                  plain " — the same layout and navigation on every screen size."
                end
                li do
                  strong { "A theme switcher" }
                  plain " with sticky themes remembered in "
                  code { "localStorage" }
                  plain "."
                end
                li do
                  strong { "Syntax highlighting for ~200 languages" }
                  plain " via Rouge — no allowlist."
                end
                li do
                  strong { "Multi-language code examples" }
                  plain " with a sticky, global language choice."
                end
                li do
                  plain "An automatic "
                  strong { %("On this page" TOC) }
                  plain " with three placement options."
                end
                li do
                  strong { "A one-command generator" }
                  plain " — "
                  code { "docs-kit new" }
                  plain " scaffolds a site."
                end
                li do
                  strong { "A single reusable deploy workflow" }
                  plain " — Kamal + GHCR."
                end
              end
            end
          end
        end

        def next_steps_section
          DocsUI::Section("Next steps") do
            prose do
              p do
                plain "Start with "
                strong { "Installation" }
                plain " to add the gem and render your first page. Then read "
                strong { "Configuration" }
                plain " to set your brand, themes, and nav, and "
                strong { "Authoring" }
                plain " to learn the DocsUI kit — the building blocks for every page body."
              end
            end
          end
        end
      end
    end
  end
end
