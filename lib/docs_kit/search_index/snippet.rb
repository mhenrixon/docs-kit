# frozen_string_literal: true

require "cgi"

module DocsKit
  class SearchIndex
    # Builds the HTML-safe excerpt shown under a search result: a short window of
    # text centered on the first query-token match, with every token wrapped in
    # <mark>. Surrounding text is HTML-escaped so an angle bracket in the source
    # can never inject markup — the returned String is safe to render.
    class Snippet
      # Characters of context on either side of the first match.
      RADIUS = 80

      def self.build(text, tokens)
        new(text, tokens).build
      end

      def initialize(text, tokens)
        @flat = text.to_s.gsub(/\s+/, " ").strip
        @tokens = tokens
      end

      def build
        highlight(window)
      end

      private

      # A ~RADIUS-on-each-side slice around the first token match, with leading/
      # trailing ellipses when the window is cut from a longer body. No match (the
      # hit was title-only) → the head of the text.
      def window
        idx = first_match_index
        return head if idx.nil?

        start = [idx - RADIUS, 0].max
        finish = [idx + RADIUS, @flat.length].min
        "#{'…' if start.positive?}#{@flat[start...finish].strip}#{'…' if finish < @flat.length}"
      end

      def head
        slice = @flat[0, RADIUS * 2].to_s.strip
        @flat.length > RADIUS * 2 ? "#{slice}…" : slice
      end

      def first_match_index
        down = @flat.downcase
        @tokens.filter_map { |token| down.index(token) }.min
      end

      # Escape the window, then wrap each token's (case-insensitive) occurrences in
      # <mark>. Tokens are escaped before matching so the search runs against the
      # same escaped text and no token can smuggle in HTML.
      def highlight(window)
        escaped = CGI.escapeHTML(window)
        @tokens.each do |token|
          pattern = Regexp.new(Regexp.escape(CGI.escapeHTML(token)), Regexp::IGNORECASE)
          escaped = escaped.gsub(pattern) { |match| "<mark>#{match}</mark>" }
        end
        escaped
      end
    end
  end
end
