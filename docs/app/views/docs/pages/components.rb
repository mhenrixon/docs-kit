# frozen_string_literal: true

module Views
  module Docs
    module Pages
      # Documents AND demonstrates the DocsUI kit — each section renders the real
      # component live (where sensible), next to the code that produced it and a
      # table of its args.
      class Components < DocsUI::Page
        title "Components"
        eyebrow "Reference"

        def lead = "Every DocsUI component — shown live where it makes sense, with its calling code and args."

        def content
          shell_section
          page_section
          header_section
          section_section
          prose_section
          code_section
          example_section
          callout_section
          icon_section
          on_this_page_section
          sidebar_section
          theme_switcher_section
        end

        private

        # --- Document-level components (described, not rendered live) ---------

        def shell_section
          DocsUI::Section("Shell", description: "The whole HTML document you're looking at right now.") do
            DocsUI::Prose() do
              p do
                code { "DocsUI::Shell" }
                plain " is the top-level page: the topbar (brand + "
                code { "ThemeSwitcher" }
                plain "), the "
                code { "Sidebar" }
                plain ", the content column, and the auto TOC. It yields the page body. "
                code { "Page" }
                plain " renders it for you — you rarely construct it directly."
              end
            end
            DocsUI::Code(<<~RUBY)
              DocsUI::Shell(title: "My guide", on_page: :panel) do
                # page body
              end
            RUBY
            render PropTable.new(
              [ "Arg", "Type", "Default", "Description" ],
              [
                [ "title", "String, nil", "nil", "Document + topbar title. Falls back to the site brand." ],
                [ "on_page", "Symbol, false", "false", "TOC placement — :panel / :toggle / :sidebar / false." ]
              ]
            )
          end
        end

        def page_section
          DocsUI::Section("Page", description: "The base class you subclass for every docs page — including this one.") do
            DocsUI::Prose() do
              p do
                plain "Subclass "
                code { "DocsUI::Page" }
                plain ", set "
                code { "title" }
                plain "/"
                code { "eyebrow" }
                plain " with the class-level DSL, and implement "
                code { "#content" }
                plain " (and optionally "
                code { "#lead" }
                plain "). The page wraps your content in the "
                code { "Shell" }
                plain " with a "
                code { "Header" }
                plain " masthead and auto TOC."
              end
            end
            DocsUI::Code(<<~RUBY)
              class Views::Docs::Pages::Guide < DocsUI::Page
                title   "My guide"
                eyebrow "Reference"
                on_page :toggle          # :panel | :toggle | :sidebar | false

                def lead = "One-sentence summary."
                def content = DocsUI::Section("Hello") { DocsUI::Prose() { p { "..." } } }
              end
            RUBY
            render PropTable.new(
              [ "Arg", "Type", "Default", "Description" ],
              [
                [ "title", "String (class DSL)", "—", "Sets the document + masthead title." ],
                [ "eyebrow", "String (class DSL)", "nil", "Small kicker above the h1 (e.g. the group)." ],
                [ "on_page", "Symbol (class DSL)", "config default", "TOC placement — :panel / :toggle / :sidebar / false." ],
                [ "#lead", "instance method", "nil", "Muted summary paragraph under the h1." ],
                [ "#content", "instance method", "—", "The page body — call kit components here." ]
              ]
            )
          end
        end

        def header_section
          DocsUI::Section("Header", description: "The masthead: eyebrow + h1 + optional lead.") do
            DocsUI::Prose() do
              p do
                plain "The block at the top of this page — kicker, heading, summary — is a "
                code { "DocsUI::Header" }
                plain ". "
                code { "Page" }
                plain " builds it from your "
                code { "title" }
                plain "/"
                code { "eyebrow" }
                plain "/"
                code { "#lead" }
                plain ", so you seldom render it yourself."
              end
            end
            DocsUI::Code(<<~RUBY)
              DocsUI::Header(title: "My guide", eyebrow: "Reference") do
                plain "An optional lead paragraph."
              end
            RUBY
            render PropTable.new(
              [ "Arg", "Type", "Default", "Description" ],
              [
                [ "title", "String", "—", "The h1 text." ],
                [ "eyebrow", "String, nil", "nil", "Small kicker above the h1." ],
                [ "block", "Phlex block", "nil", "Optional lead paragraph rendered under the h1." ]
              ]
            )
          end
        end

        # --- Content components (rendered live) -------------------------------

        def section_section
          DocsUI::Section("Section", description: "An anchored section wrapper — this description is its description: arg.") do
            DocsUI::Prose() do
              p do
                plain "Every block on this page is a "
                code { "DocsUI::Section" }
                plain ". It renders a "
                code { "<section id>" }
                plain " with an "
                code { "<h2>" }
                plain ", an optional muted "
                code { "description:" }
                plain " lead, then your block. The "
                code { "id" }
                plain " auto-slugs from the title (feeding the TOC), or pass "
                code { "id:" }
                plain " to override it."
              end
            end
            DocsUI::Code(<<~RUBY)
              DocsUI::Section("Getting started", id: "start", description: "Read me first.") do
                DocsUI::Prose() { p { "Section body." } }
              end
            RUBY
            render PropTable.new(
              [ "Arg", "Type", "Default", "Description" ],
              [
                [ "title", "String", "—", "The h2 text; auto-slugs into the anchor id." ],
                [ "id", "String, nil", "slug of title", "Override the section anchor." ],
                [ "description", "String, callable, nil", "nil", "Muted lead paragraph under the h2." ]
              ]
            )
          end
        end

        def prose_section
          DocsUI::Section("Prose", description: "A typographic wrapper for hand-authored HTML.") do
            DocsUI::Prose() do
              p { "Prose gives hand-authored text a consistent reading rhythm without a typography plugin." }
              ul do
                li { "lists," }
                li { "inline code," }
                li { "links — all styled." }
              end
            end
            DocsUI::Prose() { p { "The call that produced the block above:" } }
            DocsUI::Code(<<~RUBY)
              DocsUI::Prose() do
                p { "Prose gives hand-authored text a consistent reading rhythm." }
                ul { li { "lists," }; li { "inline code," }; li { "links." } }
              end
            RUBY
            DocsUI::Callout(:warning) do
              plain "A kit call with a block needs parens: "
              code { "DocsUI::Prose() do" }
              plain ". Bare "
              code { "DocsUI::Prose do" }
              plain " is a Ruby SyntaxError."
            end
            render PropTable.new(
              [ "Arg", "Type", "Default", "Description" ],
              [
                [ "block", "Phlex block", "—", "Hand-authored HTML — p, ul/li, code, strong, a, plain text." ]
              ]
            )
          end
        end

        def code_section
          DocsUI::Section("Code", description: "A Rouge-highlighted code block with an optional filename bar.") do
            DocsUI::Code(<<~RUBY, filename: "app/models/user.rb")
              class User < ApplicationRecord
                has_many :posts
              end
            RUBY
            DocsUI::Prose() { p { "The call that produced the block above:" } }
            DocsUI::Code(%(DocsUI::Code(source, lexer: :ruby, filename: "app/models/user.rb")))
            render PropTable.new(
              [ "Arg", "Type", "Default", "Description" ],
              [
                [ "source", "String", "—", "The code to highlight." ],
                [ "lexer", "Symbol", ":ruby", "Any Rouge language — :shell, :yaml, :erb, :python, :go, etc." ],
                [ "filename", "String, nil", "nil", "Optional filename bar above the block." ]
              ]
            )
          end
        end

        def example_section
          DocsUI::Section("Example", description: "Multi-language tabbed code with a sticky, global language choice.") do
            DocsUI::Example() do |ex|
              ex.code(:ruby, filename: "client.rb") do
                %(Anthropic::Client.new.messages.create(model: "claude-opus-4-8", messages: msgs))
              end
              ex.code(:python, filename: "client.py") do
                %(anthropic.Anthropic().messages.create(model="claude-opus-4-8", messages=msgs))
              end
            end
            DocsUI::Prose() { p { "The call that produced the tabs above:" } }
            DocsUI::Code(<<~RUBY)
              DocsUI::Example() do |ex|
                ex.code(:ruby, filename: "client.rb")   { ruby_source }
                ex.code(:python, filename: "client.py") { python_source }
              end
            RUBY
            render PropTable.new(
              [ "Arg", "Type", "Default", "Description" ],
              [
                [ "block", "Phlex block", "—", "Yields an object with #code — one call per language." ],
                [ "ex.code lang", "Symbol", "—", "The Rouge language for this tab." ],
                [ "ex.code filename:", "String, nil", "nil", "Optional filename bar for this tab." ],
                [ "ex.code lexer:", "Symbol", "lang", "Override the Rouge lexer if it differs from the tab label." ]
              ]
            )
          end
        end

        def callout_section
          DocsUI::Section("Callout", description: "note / tip / warning — a daisyUI alert with a lucide icon.") do
            DocsUI::Callout(:note) { "This is a note callout." }
            DocsUI::Callout(:tip) { "A tip callout — for handy asides." }
            DocsUI::Callout(:warning) { "A warning callout — for gotchas." }
            DocsUI::Prose() { p { "The calls that produced the boxes above:" } }
            DocsUI::Code(<<~RUBY)
              DocsUI::Callout(:note)    { "This is a note callout." }
              DocsUI::Callout(:tip)     { "A tip callout." }
              DocsUI::Callout(:warning) { "A warning callout." }
            RUBY
            render PropTable.new(
              [ "Arg", "Type", "Default", "Description" ],
              [
                [ "level", "Symbol", ":note", "Alert style — :note / :tip / :warning." ],
                [ "title", "String, nil", "nil", "Optional heading above the body." ],
                [ "block", "Phlex block", "—", "The callout body." ]
              ]
            )
          end
        end

        def icon_section
          DocsUI::Section("Icon", description: "A lucide icon by name; extra attributes pass through.") do
            div(class: "flex gap-4 not-prose") do
              DocsUI::Icon("rocket", class: "size-6")
              DocsUI::Icon("book-open", class: "size-6")
              DocsUI::Icon("paintbrush", class: "size-6")
            end
            DocsUI::Prose() { p { "The calls that produced the icons above:" } }
            DocsUI::Code(<<~RUBY)
              DocsUI::Icon("rocket", class: "size-6")
              DocsUI::Icon("book-open", class: "size-6")
              DocsUI::Icon("paintbrush", class: "size-6")
            RUBY
            DocsUI::Callout(:note) do
              plain "Icons no-op gracefully if "
              code { "rails_icons" }
              plain " isn't configured — nothing renders, no error."
            end
            render PropTable.new(
              [ "Arg", "Type", "Default", "Description" ],
              [
                [ "name", "String", "—", "The lucide icon name, e.g. \"rocket\"." ],
                [ "**attributes", "Hash", "{}", "Extra HTML attributes (class:, etc.) passed to the icon." ]
              ]
            )
          end
        end

        def on_this_page_section
          DocsUI::Section("OnThisPage", description: "The auto-TOC — the panel Shell renders from your on_page setting.") do
            DocsUI::Prose() do
              p do
                plain "The TOC is built from the page's "
                code { "Section" }
                plain " anchors. You don't construct it — "
                code { "Shell" }
                plain " renders it based on the page's "
                code { "on_page" }
                plain " setting. Set the mode per page or as a config default."
              end
            end
            DocsUI::Code(<<~RUBY)
              class Views::Docs::Pages::Api < DocsUI::Page
                on_page :toggle   # :panel | :toggle | :sidebar | false
              end
            RUBY
            render PropTable.new(
              [ "Arg", "Type", "Default", "Description" ],
              [
                [ "mode", "Symbol", ":panel", "Placement — :panel (aside) / :toggle (button) / :sidebar." ],
                [ "title", "String", '"On this page"', "The TOC heading." ]
              ]
            )
          end
        end

        def sidebar_section
          DocsUI::Section("Sidebar", description: "The left nav — built from your config, rendered by Shell.") do
            DocsUI::Prose() do
              p do
                plain "The sidebar is driven entirely by "
                code { "DocsKit.configuration.nav" }
                plain " — a callable returning grouped "
                code { "DocsKit::NavItem" }
                plain "s. "
                code { "Shell" }
                plain " renders it, so you configure it rather than construct it."
              end
            end
            DocsUI::Code(<<~RUBY, filename: "config/initializers/docs_kit.rb")
              DocsKit.configure do |c|
                c.nav = -> { { "Docs" => Doc.grouped } }
              end
            RUBY
            render PropTable.new(
              [ "Arg", "Type", "Default", "Description" ],
              [
                [ "(none)", "—", "—", "No args — reads DocsKit.configuration.nav." ]
              ]
            )
          end
        end

        def theme_switcher_section
          DocsUI::Section("ThemeSwitcher", description: "The theme dropdown — built from your config, rendered by Shell.") do
            DocsUI::Prose() do
              p do
                plain "The dropdown in the topbar is a "
                code { "DocsUI::ThemeSwitcher" }
                plain ". It lists "
                code { "DocsKit.configuration.themes" }
                plain " — which must match the daisyUI "
                code { "@plugin" }
                plain " block in your Tailwind entry. "
                code { "Shell" }
                plain " renders it for you."
              end
            end
            DocsUI::Code(<<~RUBY, filename: "config/initializers/docs_kit.rb")
              DocsKit.configure do |c|
                c.themes = %w[dark light synthwave dracula night]
              end
            RUBY
            render PropTable.new(
              [ "Arg", "Type", "Default", "Description" ],
              [
                [ "(none)", "—", "—", "No args — reads DocsKit.configuration.themes." ]
              ]
            )
          end
        end
      end
    end
  end
end
