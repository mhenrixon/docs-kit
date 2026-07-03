# frozen_string_literal: true

module DocsUI
  # The "Markdown" masthead affordance: a link to the current page's `.md` twin.
  # With JS off it simply opens the raw Markdown (a working, no-JS fallback); the
  # docs-nav controller enhances the click into copy-to-clipboard (a new target +
  # action on the ONE controller — the single-controller rule holds).
  #
  #   render DocsUI::MarkdownAction.new(request.path)
  #
  # Rendered by DocsUI::Page when DocsKit.configuration.page_markdown_action is
  # true (the default). The `.md` twin itself is produced by
  # DocsKit::Controller#render_page → DocsKit::MarkdownExport.
  class MarkdownAction < Phlex::HTML
    LABEL = "Markdown"
    CLASSES = "btn btn-ghost btn-xs gap-1 opacity-70 hover:opacity-100"

    def initialize(path)
      @path = path.to_s
    end

    def view_template
      a(
        href: md_href,
        class: CLASSES,
        # JS-ON: docs-nav intercepts the click, fetches the .md, copies it, and
        # (because the browser default is prevented) never navigates away.
        data: { docs_nav_target: "markdownLink", action: "docs-nav#copyMarkdown" }
      ) do
        render DocsUI::Icon.new("clipboard", class: "size-3.5")
        plain LABEL
      end
    end

    private

    # The `.md` twin URL: the request path with a `.md` extension, preserving any
    # query string. Idempotent — a path already ending in `.md` is left as-is.
    def md_href
      path, query = @path.split("?", 2)
      path = "#{path}.md" unless path.end_with?(".md")
      query ? "#{path}?#{query}" : path
    end
  end
end
