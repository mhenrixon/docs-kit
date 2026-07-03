# frozen_string_literal: true

module DocsKit
  # One ranked search result. Built by DocsKit::SearchIndex#search and rendered by
  # DocsUI::SearchResults (html) / serialized to JSON for the docs-nav palette.
  #
  #   page_title    — the page the hit lives on (results group by this)
  #   section_title — the `## ` section, or nil for a page-intro hit
  #   href          — the page href + "#anchor" (nil section → bare page href)
  #   snippet       — an HTML-safe excerpt around the match, the term in <mark>
  #   score         — the rank weight (title > heading > body); higher wins
  SearchHit = Data.define(:page_title, :section_title, :href, :snippet, :score) do
    def initialize(page_title:, href:, snippet:, score:, section_title: nil)
      super
    end

    # The label a result row shows: "Page → Section", or just the page title for
    # a page-intro hit.
    def label
      section_title ? "#{page_title} → #{section_title}" : page_title
    end

    # JSON shape the palette fetches (matches #label / #href / #snippet).
    def as_json(*)
      { "label" => label, "href" => href, "snippet" => snippet }
    end
  end
end
