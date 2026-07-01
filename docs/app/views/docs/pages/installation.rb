# frozen_string_literal: true

module Views
  module Docs
    module Pages
      # A sample guide page. Subclass DocsUI::Page, set the title (+ optional
      # eyebrow/lead), and build the body from the DocsUI kit (Section/Prose/Code).
      # The "On this page" TOC + scroll-spy are automatic (config default).
      class Installation < DocsUI::Page
        title "Installation"
        eyebrow "Guide"

        def lead = "Add the gem and render your first page."

        def content
          DocsUI::Section("Add the gem", description: "One line in your Gemfile.") do
            DocsUI::Prose() { p { "docs-kit ships the shared Phlex chrome — configure it once." } }
            DocsUI::Code(<<~RUBY, filename: "Gemfile")
              gem "docs-kit"
            RUBY
          end

          DocsUI::Section("Configure") do
            DocsUI::Prose() { p { "Set your brand, themes, and nav:" } }
            DocsUI::Code(<<~RUBY, filename: "config/initializers/docs_kit.rb")
              DocsKit.configure do |c|
                c.brand  = "Docs"
                c.themes = %w[dark light]
              end
            RUBY
          end
        end
      end
    end
  end
end
