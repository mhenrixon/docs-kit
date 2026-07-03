# frozen_string_literal: true

module Views
  module Docs
    module Pages
# How to write a documentation page: a Phlex class, a registry entry, and
      # the DocsUI building blocks, plus the automatic "On this page" TOC.
      class Authoring < DocsUI::Page
        title "Authoring pages"
        eyebrow "Getting started"

        def lead = "Write a page as a Phlex class, register it, and the shell, masthead, and TOC come free."

        def content
          page_is_a_class_section
          register_section
          building_blocks_section
          toc_section
        end

        private

        def page_is_a_class_section
          DocsUI::Section("A page is a Phlex class",
                          description: "Subclass DocsUI::Page, declare its metadata, fill in #content.") do
            DocsUI::Code(<<~RUBY, filename: "app/views/docs/pages/guide.rb")
              # frozen_string_literal: true

              module Views
                module Docs
                  module Pages
                    class Guide < DocsUI::Page
                      title "Guide"
                      eyebrow "Getting started"

                      def lead = "One sentence that sits under the page title."

                      def content
                        DocsUI::Section("First steps", description: "What this section covers.") do
                          prose do
                            p { "Hand-authored prose with consistent reading rhythm." }
                          end

                          DocsUI::Code(<<~SOURCE, filename: "config/routes.rb")
                            Rails.application.routes.draw do
                              mount DocsKit::Engine, at: "/docs"
                            end
                          SOURCE
                        end
                      end
                    end
                  end
                end
              end
            RUBY

            prose do
              p do
                code { "title" }
                plain " names the page, "
                code { "eyebrow" }
                plain " groups it above the title, and "
                code { "lead" }
                plain " is the summary sentence under it. Everything you render lives in "
                code { "content" }
                plain "."
              end
              p do
                plain "The shell (topbar, sidebar, theme switcher), the page masthead, and the "
                strong { "On this page" }
                plain " TOC are added automatically — you only write the body."
              end
            end
          end
        end

        def register_section
          DocsUI::Section("Register the page",
                          description: "Add an entry so it appears in the nav and resolves at /docs/<slug>.") do
            prose do
              p do
                plain "A page shows up once it has a row in the "
                code { "Doc" }
                plain " registry. The "
                code { "view:" }
                plain " maps to your class name under "
                code { "Views::Docs::Pages" }
                plain "; the "
                code { "group:" }
                plain " sets its sidebar heading."
              end
            end

            DocsUI::Code(<<~RUBY, filename: "app/models/doc.rb")
              class Doc
                extend DocsKit::Registry

                entries [
                  { slug: "overview", title: "Overview", group: "Getting started", view: "Overview" },
                  { slug: "guide",    title: "Guide",    group: "Getting started", view: "Guide" }
                ]
              end
            RUBY

            DocsUI::Callout(:note) do
              "The sidebar only links a page whose class exists, so an entry without its class yet is a no-op — no dead links."
            end
          end
        end

        def building_blocks_section
          DocsUI::Section("The building blocks",
                          description: "The DocsUI kit you compose inside #content.") do
            render DocsUI::PropTable.new(
              [
                [ "DocsUI::Section(title)", "an anchored subsection with a heading (+ optional description)" ],
                [ "md(source)", "a block of GFM Markdown, styled like Prose" ],
                [ "prose { … }", "hand-authored prose (p/ul/code) in a reading-rhythm wrapper" ],
                [ "DocsUI::Code(source)", "a syntax-highlighted code block" ],
                [ "example { |ex| … }", "multi-language tabbed code" ],
                [ "DocsUI::Callout(level)", "note / tip / warning boxes" ]
              ],
              headers: [ "Helper", "Use for" ]
            )

            prose do
              p do
                plain "The primary argument is always positional — "
                code { "Section(\"Title\")" }
                plain ", "
                code { "Code(source)" }
                plain ", "
                code { "Header(\"Title\")" }
                plain " — with modifiers as keywords ("
                code { "description:" }
                plain ", "
                code { "eyebrow:" }
                plain ")."
              end
              p do
                plain "For the wrappers that take no argument, use the lowercase page helpers "
                code { "prose" }
                plain " / "
                code { "example" }
                plain " (and "
                code { "md" }
                plain " for Markdown). A lowercase method takes a block without parens, so "
                code { "prose do … end" }
                plain " just works. The kit forms "
                code { "DocsUI::Prose()" }
                plain " / "
                code { "DocsUI::Example()" }
                plain " stay valid — they only need the empty "
                code { "()" }
                plain " because a bare "
                code { "DocsUI::Prose do" }
                plain " parses as a constant reference (a SyntaxError)."
              end
            end
          end
        end

        def toc_section
          DocsUI::Section("The \"On this page\" TOC",
                          description: "Built for you from your section headings.") do
            prose do
              p do
                plain "Every "
                code { "DocsUI::Section" }
                plain " heading becomes an entry in the automatic "
                strong { "On this page" }
                plain " table of contents — you never list them by hand."
              end
              p do
                plain "Override its placement per page with "
                code { "on_page" }
                plain "."
              end
            end

            DocsUI::Code(<<~RUBY)
              class Views::Docs::Pages::Guide < DocsUI::Page
                on_page :toggle   # :toggle | :panel | :sidebar | false
              end
            RUBY

            prose do
              p do
                plain "See the "
                a(href: "/docs/on-this-page") { "On this page" }
                plain " reference for every mode and the site-wide default."
              end
            end
          end
        end
      end
    end
  end
end
