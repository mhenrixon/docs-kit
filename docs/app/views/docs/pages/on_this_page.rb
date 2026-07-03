# frozen_string_literal: true

module Views
  module Docs
    module Pages
      # Documents the automatic "On this page" table of contents: the placements,
      # how to set the default, per-page overrides, and how the client-side
      # scroll-spy works.
      class OnThisPage < DocsUI::Page
        title "On this page"
        eyebrow "Reference"

        def lead = "docs-kit builds a scroll-spy table of contents from your Section headings — no config required."

        def content
          automatic_toc_section
          placements_section
          default_section
          override_section
          how_it_works_section
        end

        private

        def automatic_toc_section
          DocsUI::Section("Automatic TOC") do
            prose do
              p do
                plain "docs-kit builds an "
                strong { "On this page" }
                plain " table of contents from your page's "
                code { "DocsUI::Section" }
                plain " headings automatically — no config needed. As you scroll, "
                plain "scroll-spy highlights the section you're currently reading."
              end
              p { "This very page has one — look to the right." }
            end
          end
        end

        def placements_section
          DocsUI::Section("Three placements",
                          description: "The TOC renders in one of three spots, or not at all.") do
            render DocsUI::PropTable.new(
              [
                [ ":panel",   "A sticky card top-right of the content column (default)." ],
                [ ":toggle",  "A floating button top-right that opens a dropdown." ],
                [ ":sidebar", "Nested under the active nav item in the left sidebar." ],
                [ "false",    "No auto-TOC." ]
              ],
              headers: [ "Mode", "Placement" ]
            )
          end
        end

        def default_section
          DocsUI::Section("Setting the default") do
            DocsUI::Code(<<~RUBY, filename: "config/initializers/docs_kit.rb")
              DocsKit.configure do |c|
                c.on_page_default = :panel
              end
            RUBY
            prose do
              p do
                plain "Sets the placement for "
                strong { "every" }
                plain " page unless a page overrides it."
              end
            end
          end
        end

        def override_section
          DocsUI::Section("Per-page override") do
            DocsUI::Code(<<~RUBY)
              class Views::Docs::Pages::Deploy < DocsUI::Page
                title "Deploy"
                on_page :toggle   # :panel | :sidebar | :toggle | false

                def content
                  # ...
                end
              end
            RUBY
            prose do
              p do
                plain "Declare "
                code { "on_page" }
                plain " in a "
                code { "DocsUI::Page" }
                plain " subclass to override the default for that page only. Accepts "
                code { ":panel" }
                plain ", "
                code { ":toggle" }
                plain ", "
                code { ":sidebar" }
                plain ", or "
                code { "false" }
                plain "."
              end
            end
          end
        end

        def how_it_works_section
          DocsUI::Section("How it works") do
            prose do
              p do
                plain "The TOC is pure client-side. The docs-nav Stimulus controller reads "
                code { "section[id]" }
                plain ", "
                code { "h2[id]" }
                plain ", and "
                code { "h3[id]" }
                plain " from the DOM, then an "
                code { "IntersectionObserver" }
                plain " drives the scroll-spy highlight as sections enter the viewport."
              end
              p { "Short pages — fewer than the minimum headings — hide the TOC automatically." }
            end

            DocsUI::Callout(:tip) do
              plain "Headings come from "
              code { "DocsUI::Section" }
              plain " ids, so structure your page with Sections to get a good TOC."
            end
          end
        end
      end
    end
  end
end
