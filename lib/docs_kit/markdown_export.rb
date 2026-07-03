# frozen_string_literal: true

require "nokogiri"

module DocsKit
  # Derives a faithful GFM Markdown twin of a docs page FROM the page's own
  # rendered HTML. The gem emits the HTML, so the tag vocabulary is bounded and a
  # small hand-rolled Nokogiri visitor converts it exactly — no dependence on
  # authoring style (Phlex, `md` islands, and raw tags in Prose all convert
  # identically because conversion happens post-render).
  #
  #   DocsKit::MarkdownExport.new(page_view, view_context:, base_url: req.base_url).to_md
  #
  # The page is rendered, the #docs-content region (DocsUI::Shell's anchor) is
  # extracted, [data-md-skip] chrome is stripped, and the remaining subtree is
  # walked to Markdown. Data hints the kit stamps at render time drive the tricky
  # cases: data-md-lang (DocsUI::Code) → a ```lang fence; data-md-callout
  # (DocsUI::Callout) → a `> **Tip:**` blockquote.
  class MarkdownExport
    # The extraction anchor DocsUI::Shell stamps on its content column.
    CONTENT_SELECTOR = "#docs-content"

    # Elements dropped whole — chrome and non-content that must never reach the
    # Markdown twin. [data-md-skip] is authored (Page's "← Home" nav); script and
    # style carry no readable content.
    DROP_SELECTOR = "[data-md-skip], script, style"

    # Callout level → the bold label opening its blockquote.
    CALLOUT_LABELS = { "note" => "Note", "tip" => "Tip", "warning" => "Warning" }.freeze

    # The parameter kinds that count as a keyword arg (required or optional) when
    # sniffing whether a view's #call accepts a view_context: kwarg.
    KEYWORD_PARAM_TYPES = %i[key keyreq].freeze

    # view: a renderable page (a Phlex component in production). view_context: the
    # Rails view context to render it through (CSRF, url helpers). base_url: the
    # request's base URL, used to absolutize relative link/image hrefs so the
    # exported Markdown is portable.
    def initialize(view, view_context: nil, base_url: nil)
      @view = view
      @view_context = view_context
      @base_url = base_url
    end

    # The page's content as GFM Markdown, or "" when there is no #docs-content
    # region (a page that isn't the docs chrome — the HTML route is untouched).
    def to_md
      content = extract_content
      return "" unless content

      content.search(DROP_SELECTOR).each(&:remove)
      Blocks.new(self).render(content).strip
    end

    # Absolutize a relative href/src against the base URL; leave absolute and
    # anchor/mailto links untouched. No base URL → return as-is.
    def absolutize(url)
      return url if url.nil? || url.empty?
      return url unless @base_url
      return url if url.match?(%r{\A(?:[a-z][a-z0-9+.-]*:|//|#)}i)

      "#{@base_url.chomp('/')}/#{url.delete_prefix('/')}"
    end

    private

    # Render the page to an HTML document and grab the #docs-content subtree.
    def extract_content
      Nokogiri::HTML5.fragment(render_html).at_css(CONTENT_SELECTOR)
    end

    # Render the page to an HTML string. Production renders a Phlex component
    # through the Rails view context (so url helpers/CSRF work); in isolation the
    # view is rendered via #call. The seam: a view whose #call accepts a
    # view_context: kwarg gets it; a Phlex component with a view_context is
    # rendered through Rails; otherwise a bare #call.
    def render_html
      if call_accepts_view_context?
        @view.call(view_context: @view_context)
      elsif @view_context && @view.respond_to?(:render_in)
        @view_context.render(@view)
      else
        @view.call
      end
    end

    def call_accepts_view_context?
      @view.respond_to?(:call) &&
        @view.method(:call).parameters.any? { |type, name| name == :view_context && KEYWORD_PARAM_TYPES.include?(type) }
    end
  end
end
