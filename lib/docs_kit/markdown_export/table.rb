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

        header, *body = rows
        lines = [row(header), separator(header.length)]
        lines.concat(body.map { |cells| row(cells) })
        lines.join("\n")
      end

      private

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
