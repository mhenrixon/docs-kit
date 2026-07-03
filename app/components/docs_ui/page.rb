# frozen_string_literal: true

module DocsUI
  # The base class for a hand-authored doc page. Subclasses set the title (and
  # optional eyebrow/lead) and implement #content with the page body, composing
  # the doc kit (Section/Prose/Code/Callout). Page renders it inside DocsUI::Shell
  # with a consistent masthead.
  #
  #   class Views::Docs::Pages::Installation < DocsUI::Page
  #     title "Installation"
  #     eyebrow "Guide"
  #     def lead = "Add the gem and render your first component."
  #     def content
  #       render DocsUI::Section.new("Add the gem") { … }
  #     end
  #   end
  class Page < Phlex::HTML
    include Phlex::Rails::Helpers::Routes
    # Authored pages subclass this, so include the kit here: a page body can call
    # DocsUI::Section(...) / DocsUI::Code(...) directly, no render ... .new.
    include DocsUI

    class << self
      def title(value = nil)
        @title = value if value
        @title
      end

      def eyebrow(value = nil)
        @eyebrow = value if value
        @eyebrow
      end

      # The "On this page" auto-TOC placement for this page. Defaults to the
      # configured DocsKit.configuration.on_page_default; set false to opt out,
      # or :panel/:toggle/:sidebar to override per page.
      def on_page(value = :__unset__)
        @on_page = value unless value == :__unset__
        defined?(@on_page) ? @on_page : true
      end
    end

    def view_template
      render DocsUI::Shell.new(title: self.class.title, on_page: self.class.on_page) do
        nav(class: "mb-6") do
          a(href: root_path, class: "link link-hover text-sm opacity-70") { "← Home" }
        end

        render DocsUI::Header.new(title: self.class.title, eyebrow: self.class.eyebrow) do
          plain lead if lead
        end

        content
      end
    end

    # Render a block of GFM Markdown as Prose-styled prose (see DocsUI::Markdown).
    # A lowercase method + heredoc sidesteps the parens-with-blocks gotcha:
    #   md <<~'MD'
    #     Write **prose** as Markdown. Single-quoted heredoc so #{} stays literal.
    #   MD
    def md(source)
      render DocsUI::Markdown.new(source)
    end

    # Override in subclasses for the lead paragraph (optional).
    def lead = nil

    # Override in subclasses with the page body.
    def content
      raise NotImplementedError, "#{self.class} must implement #content"
    end
  end
end
