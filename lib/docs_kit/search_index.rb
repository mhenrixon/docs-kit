# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

module DocsKit
  # An in-memory docs search index, built straight from the pages' Markdown twins
  # — zero authoring, no external service, no build step. This is the structural
  # replacement for the hand-maintained "second registry" + regex-parsed text a
  # site used to keep: the twin already IS the page's content, split on its `## `
  # headings into searchable sections.
  #
  #   DocsKit::SearchIndex.new(triples).search("theme switcher")
  #
  # `triples` is [[page_title, page_href, markdown], ...] — the controller renders
  # each registry page through DocsKit::MarkdownExport and hands the triples in,
  # exactly as DocsKit::LlmsText separates pure shaping from the controller's
  # rendering. So the whole index + scorer is unit-testable with no Rails.
  #
  # One entry per section (plus a page-intro entry for the text before the first
  # `## `). Scoring is plain Ruby: case-insensitive token match, all tokens must
  # hit (AND), a title hit outranks a heading hit outranks a body hit. Results cap
  # at MAX_RESULTS with an HTML-safe snippet around the match (the term in
  # <mark>). No dependencies, no fuzzy matching (revisit if usage demands it).
  class SearchIndex
    # Field weights — a match in the page title beats a section heading beats body
    # text, so the most on-topic section floats up.
    TITLE_WEIGHT = 100
    HEADING_WEIGHT = 10
    BODY_WEIGHT = 1

    # Never return more than this — a docs site is tens of pages, and a reader
    # scans the top matches, not a hundred.
    MAX_RESULTS = 20

    # An indexed section (or page intro). `haystacks` holds the lowercased text of
    # each weighted field so scoring is a simple include? per token.
    #
    # The page title is searchable ONLY on the page-intro entry (section_title
    # nil), not on every section: a title token matches all sections of a page
    # equally, so weighting each section by the title would flood the results with
    # near-identical rows from one page. A pure title match therefore surfaces
    # once (the intro), while a section still ranks on its own heading/body.
    Entry = Struct.new(:page_title, :section_title, :href, :body, keyword_init: true) do
      # { weight => lowercased searchable text } for this entry.
      def haystacks
        @haystacks ||= begin
          fields = {
            HEADING_WEIGHT => section_title.to_s.downcase,
            BODY_WEIGHT => body.to_s.downcase
          }
          fields[TITLE_WEIGHT] = page_title.to_s.downcase if section_title.nil?
          fields
        end
      end
    end

    # triples: [[page_title, page_href, markdown], ...].
    def initialize(triples = [])
      @entries = triples.flat_map { |title, href, markdown| entries_for(title, href, markdown) }
    end

    attr_reader :entries

    # The top MAX_RESULTS SearchHits for `query`, best first. Blank query → [].
    # Every whitespace-split token must match the entry somewhere (AND); the
    # entry's score is the sum, per token, of the best field it matched.
    def search(query)
      tokens = tokenize(query)
      return [] if tokens.empty?

      scored = @entries.filter_map { |entry| score_entry(entry, tokens) }
      scored.sort_by { |hit| [-hit.score, hit.page_title, hit.section_title.to_s] }
            .first(MAX_RESULTS)
    end

    private

    # Split a page's Markdown twin into entries: the intro text (before the first
    # `## `) becomes a page-level entry; each `## Heading` starts a section entry
    # whose href carries the recomputed anchor.
    def entries_for(page_title, page_href, markdown)
      intro, sections = split_sections(markdown.to_s)
      built = []
      built << build_entry(page_title, nil, page_href, intro) unless intro.strip.empty?
      sections.each do |heading, body|
        anchor = "#{page_href}##{slugify(heading)}"
        built << build_entry(page_title, heading, anchor, body)
      end
      # A page with no intro and no sections (empty twin) still gets one entry, so
      # its title is searchable.
      built << build_entry(page_title, nil, page_href, "") if built.empty?
      built
    end

    def build_entry(page_title, section_title, href, body)
      Entry.new(page_title: page_title, section_title: section_title, href: href, body: body.strip)
    end

    # → [intro_text, [[heading, body], ...]]. Splits on lines that are exactly a
    # level-2 ATX heading (`## Foo`), matching MarkdownExport's twin output.
    def split_sections(markdown)
      parts = markdown.split(/^\#\#[ \t]+(.+?)[ \t]*$/)
      intro = parts.shift.to_s
      sections = parts.each_slice(2).map { |heading, body| [heading.to_s.strip, body.to_s] }
      [intro, sections]
    end

    # The section anchor the twin dropped: the same slug DocsUI::Section stamps on
    # its <section id> (ActiveSupport #parameterize when available, else a minimal
    # ASCII slug so the index works off-Rails too).
    def slugify(text)
      return text.parameterize if text.respond_to?(:parameterize)

      text.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
    end

    def tokenize(query)
      query.to_s.downcase.split(/\s+/).reject(&:empty?)
    end

    # A SearchHit if EVERY token matched somewhere in the entry (AND), else nil.
    # Each token scores the heaviest field it appears in; the entry score sums
    # those, so a section matching more tokens (and in heavier fields) ranks higher.
    def score_entry(entry, tokens)
      total = 0
      tokens.each do |token|
        best = best_field_weight(entry, token)
        return nil unless best # this token matched nothing → entry is out (AND)

        total += best
      end
      SearchHit.new(
        page_title: entry.page_title, section_title: entry.section_title,
        href: entry.href, snippet: snippet_for(entry, tokens), score: total
      )
    end

    # The heaviest field weight whose text contains `token`, or nil if none do.
    def best_field_weight(entry, token)
      entry.haystacks.select { |_weight, text| text.include?(token) }.keys.max
    end

    # An HTML-safe snippet around the match. Prefer the body; if the match is
    # title-only (empty body), fall back to the section or page title so the row
    # still has context. Snippet windowing + <mark> highlighting + escaping live
    # in SearchIndex::Snippet.
    def snippet_for(entry, tokens)
      source = entry.body.to_s
      if source.strip.empty?
        source = entry.section_title.to_s.empty? ? entry.page_title.to_s : entry.section_title.to_s
      end
      Snippet.build(source, tokens)
    end
  end
end
