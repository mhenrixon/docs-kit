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
    # #request drives the "Markdown" masthead action's href (request.path + .md).
    include Phlex::Rails::Helpers::Request
    # Authored pages subclass this, so include the kit here: a page body can call
    # DocsUI::Section(...) / DocsUI::Code(...) directly, no render ... .new.
    include DocsUI
    # The lowercase, block-friendly authoring helpers (md/prose/example) — the
    # friction-free path that never trips the parens-with-blocks gotcha.
    include DocsUI::PageHelpers

    class << self
      def title(value = nil)
        @title = value if value
        @title
      end

      def eyebrow(value = nil)
        @eyebrow = value if value
        @eyebrow
      end

      # The per-page SEO/social description → DocsUI::MetaTags (via Shell). Set it
      # for a hand-tuned description; when unset, Page derives one from #lead, so
      # an existing page gets a sensible description for free. nil (no
      # description, no lead) falls back to config.seo.description in MetaTags.
      def description(value = nil)
        @description = value if value
        @description
      end

      # The "On this page" auto-TOC placement for this page. Defaults to the
      # configured DocsKit.configuration.on_page_default; set false to opt out,
      # or :panel/:toggle/:sidebar to override per page.
      def on_page(value = :__unset__)
        @on_page = value unless value == :__unset__
        defined?(@on_page) ? @on_page : DocsKit.configuration.on_page_default
      end
    end

    def view_template
      render DocsUI::Shell.new(
        title: self.class.title,
        description: self.class.description || lead,
        on_page: self.class.on_page
      ) do
        # data-md-skip drops this nav from the Markdown export — it's chrome, not
        # page content (DocsKit::MarkdownExport strips [data-md-skip]). The
        # "Markdown" action sits opposite "← Home"; it's chrome too, so it lives
        # inside the skipped nav and never appears in the .md twin.
        nav(class: "mb-6 flex items-center justify-between gap-4", data: { md_skip: true }) do
          a(href: root_path, class: "link link-hover text-sm opacity-70") { "← Home" }
          render DocsUI::MarkdownAction.new(request.path) if markdown_action?
        end

        render DocsUI::Header.new(self.class.title, eyebrow: self.class.eyebrow) do
          plain lead if lead
        end

        content
      end
    end

    # Whether to show the "Markdown" masthead action — the config knob
    # (DocsKit.configuration.page_markdown_action, default true).
    def markdown_action? = DocsKit.configuration.page_markdown_action

    # The lowercase authoring helpers md/prose/example come from DocsUI::PageHelpers
    # (included above) — the parens-free path that never hits the constant-reference
    # SyntaxError. The kit forms (DocsUI::Prose(), DocsUI::Example()) stay valid too.

    # Override in subclasses for the lead paragraph (optional).
    def lead = nil

    # Override in subclasses with the page body.
    def content
      raise NotImplementedError, "#{self.class} must implement #content"
    end
  end
end
