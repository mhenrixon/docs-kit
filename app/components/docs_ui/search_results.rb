# frozen_string_literal: true

module DocsUI
  # The server-rendered search results — the JS-off path. A plain page body (the
  # host renders it inside DocsUI::Shell) that echoes the query, lists the hits
  # grouped by page, and links each result to its section anchor. With JavaScript
  # off this IS the search UX; the docs-nav palette is a progressive enhancement
  # over the same DocsKit::SearchController that renders this.
  #
  #   render DocsUI::SearchResults.new(query: params[:q], hits: index.search(params[:q]))
  #
  # hits are DocsKit::SearchHit value objects (already ranked, snippet pre-marked
  # and HTML-safe). A blank query prompts the reader; a query with no hits renders
  # guidance instead of an empty list.
  class SearchResults < Phlex::HTML
    def initialize(query:, hits:)
      @query = query.to_s
      @hits = hits
    end

    def view_template
      div(class: "mx-auto max-w-3xl") do
        header
        if @query.strip.empty?
          prompt
        elsif @hits.empty?
          empty_state
        else
          results
        end
      end
    end

    private

    def header
      h1(class: "mb-2 text-3xl font-bold tracking-tight") { "Search" }
      return if @query.strip.empty?

      p(class: "mb-8 text-base-content/60") do
        plain "#{result_count} for "
        span(class: "font-semibold text-base-content") { "“#{@query}”" }
      end
    end

    def result_count
      n = @hits.size
      "#{n} result#{'s' unless n == 1}"
    end

    # Blank query — the bare /docs/search page. Tell the reader what to do.
    def prompt
      p(class: "text-base-content/60") { "Type a query above to search the docs." }
    end

    # A query that matched nothing — guidance, not a dead end.
    def empty_state
      div(class: "rounded-box border border-base-300 bg-base-200 p-6 text-center") do
        p(class: "mb-1 font-medium") { "No results for “#{@query}”." }
        p(class: "text-sm text-base-content/60") { "Try fewer or more general words." }
      end
    end

    # Hits grouped by page: one heading per page, each hit a linked card with its
    # section label + highlighted snippet. group_by preserves first-seen (rank)
    # order, so the best-scoring page leads.
    def results
      div(class: "space-y-8") do
        @hits.group_by(&:page_title).each do |page_title, page_hits|
          section(class: "space-y-2") do
            h2(class: "text-sm font-semibold uppercase tracking-wider text-base-content/60") { page_title }
            page_hits.each { |hit| result_row(hit) }
          end
        end
      end
    end

    def result_row(hit)
      a(
        href: hit.href,
        class: "block rounded-box border border-base-300 bg-base-100 p-4 transition " \
               "hover:border-primary hover:bg-base-200"
      ) do
        # A page-intro hit (no section) is the page overview; label it so as not
        # to duplicate the page-group heading above it.
        span(class: "block font-medium text-primary") { hit.section_title || "Overview" }
        # The snippet is a gem-produced, pre-escaped HTML string (the matched term
        # wrapped in <mark>, everything else escaped by SearchIndex::Snippet), so
        # it's trusted markup — raw(safe) is the same idiom DocsUI::Code uses for
        # its highlighted output. NEVER pass user/config free text here unescaped.
        p(class: "mt-1 text-sm text-base-content/70") { raw(safe(hit.snippet)) }
      end
    end
  end
end
