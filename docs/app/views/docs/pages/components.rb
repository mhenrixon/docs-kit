# frozen_string_literal: true

module Views
  module Docs
    module Pages
      # Documents AND demonstrates the DocsUI kit — each section renders the real
      # component live, next to the code that produced it.
      class Components < DocsUI::Page
        title "Components"
        eyebrow "Reference"

        def lead = "The DocsUI kit — shown live, with the code that renders each one."

        def content
          shell_and_page_section
          code_section
          callout_section
          prose_section
        end

        private

        def shell_and_page_section
          DocsUI::Section("Shell & Page", description: "The full document + drawer shell you're looking at now.") do
            DocsUI::Prose() do
              p do
                code { "DocsUI::Shell" }
                plain " is the whole HTML document (topbar, sidebar, theme switcher, this "
                plain "content column). "
                code { "DocsUI::Page" }
                plain " renders your page body inside it with the masthead + auto TOC."
              end
            end
            DocsUI::Code(<<~RUBY)
              class Views::Docs::Pages::Guide < DocsUI::Page
                title "My guide"
                def content = DocsUI::Section("Hello") { DocsUI::Prose() { p { "..." } } }
              end
            RUBY
          end
        end

        def code_section
          DocsUI::Section("Code") do
            DocsUI::Prose() { p { "Rouge-highlighted, any language, with an optional filename bar:" } }
            # Live render:
            DocsUI::Code(<<~RUBY, filename: "app/models/user.rb")
              class User < ApplicationRecord
                has_many :posts
              end
            RUBY
            DocsUI::Prose() { p { "The call that produced the block above:" } }
            DocsUI::Code(%(DocsUI::Code(source, filename: "app/models/user.rb")))
          end
        end

        def callout_section
          DocsUI::Section("Callout", description: "note / tip / warning — daisyUI alert + a lucide icon.") do
            DocsUI::Callout(:note) { "This is a note callout." }
            DocsUI::Callout(:tip) { "A tip callout — for handy asides." }
            DocsUI::Callout(:warning) { "A warning callout — for gotchas." }
            DocsUI::Code(<<~RUBY)
              DocsUI::Callout(:warning) { "A warning callout." }
            RUBY
          end
        end

        def prose_section
          DocsUI::Section("Prose") do
            DocsUI::Prose() do
              p { "Prose gives hand-authored text consistent reading rhythm without a typography plugin." }
              ul do
                li { "lists," }
                li { "inline code," }
                li { "links — all styled." }
              end
            end
            DocsUI::Code(<<~RUBY)
              DocsUI::Prose() { p { "..." }; ul { li { "..." } } }
            RUBY
          end
        end
      end
    end
  end
end
