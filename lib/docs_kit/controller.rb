# frozen_string_literal: true

module DocsKit
  # Controller glue for a docs site. Include in ApplicationController to get the
  # one shared render helper.
  #
  #   class ApplicationController < ActionController::Base
  #     include DocsKit::Controller
  #     def show = render_page(Views::Landings::Show.new)
  #   end
  module Controller
    # Render a Phlex page that is itself a full HTML document (it composes
    # Docs::Shell, which emits <html>/<head>/<body>). `layout: false` prevents the
    # Rails ERB application layout from double-nesting <html>. phlex-rails still
    # renders through a real view context, so CSRF, dom_id, url helpers, and the
    # phlex-reactive token signer all work inside components.
    #
    # A `.md`/`.text` request instead returns the page's Markdown twin, derived
    # from the SAME render (DocsKit::MarkdownExport walks the rendered HTML). So
    # `GET /docs/x.md` is faithful GFM of exactly what `/docs/x` shows — the
    # author writes nothing extra, and the two never drift.
    def render_page(view)
      return render_markdown(view) if markdown_request?

      render view, layout: false
    end

    private

    # True for a `.md` or `.text` request. `.text` is accepted as an alias so a
    # host whose routes only allow the built-in `:text` format still gets the
    # twin.
    def markdown_request?
      request.format.md? || request.format.text?
    end

    # The Markdown twin as text/markdown. Rendered through the controller's view
    # context (so url helpers/CSRF resolve) and with the request base URL so
    # relative links in the export are absolutized to portable URLs.
    def render_markdown(view)
      markdown = DocsKit::MarkdownExport.new(
        view, view_context:, base_url: request.base_url
      ).to_md
      render plain: markdown, content_type: "text/markdown"
    end
  end
end
