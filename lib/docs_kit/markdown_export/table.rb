# frozen_string_literal: true

module DocsKit
  class MarkdownExport
    # A GFM pipe table. The first row (thead, or the first row if there's no
    # thead) is the header; a separator row follows; the rest are body rows. Cell
    # content is inline Markdown with pipes escaped so they don't break the table.
    class Table
      def initialize(export)
        @inline = Inline.new(export)
      end

      def render(node)
        rows = rows(node)
        return "" if rows.empty?

        width = rows.map(&:length).max
        header, *body = pad(rows, width)
        lines = [row(header), separator(width)]
        lines.concat(body.map { |cells| row(cells) })
        lines.join("\n")
      end

      private

      # Pad every row out to +width+ with empty cells so the header, separator,
      # and all body rows declare the same column count (a rectangular GFM table).
      def pad(rows, width)
        rows.map { |cells| cells + Array.new(width - cells.length, "") }
      end

      # All rows as arrays of cell strings, header row first. A <thead> row leads;
      # <tbody>/bare <tr> rows follow.
      def rows(node)
        node.css("tr").map do |tr|
          tr.css("th, td").map { |cell| cell_text(cell) }
        end
      end

      def cell_text(cell)
        @inline.render(cell).strip.gsub("|", "\\|").tr("\n", " ")
      end

      def row(cells)
        "| #{cells.join(' | ')} |"
      end

      def separator(count)
        "| #{Array.new(count, '---').join(' | ')} |"
      end
    end
  end
end
