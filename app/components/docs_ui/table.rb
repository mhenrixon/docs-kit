# frozen_string_literal: true

module DocsUI
  # A generic reference table — headers + rows — in the kit's daisyUI look (a
  # `table table-sm table-zebra` inside a `rounded-box` border, `not-prose` so the
  # surrounding Prose typography doesn't restyle it). This is the piece every docs
  # site was hand-rolling; compose it, don't write raw `table`/`tr`/`td` markup.
  #
  #   render DocsUI::Table.new(
  #     ["Option", "Type", "Default", "Description"],
  #     [
  #       ["brand", "String", '"Docs"', "Topbar + sidebar heading."],
  #       ["themes", [:code, "%w[dark light]"], "—", "ThemeSwitcher options."],
  #     ]
  #   )
  #
  # Cell values (the same convention the dogfood PropTable proved):
  #
  #   * String        → plain text (Phlex-escaped; HTML in it is inert, never live)
  #   * [:code, "x"]  → inline <code> (for a type, a default literal, an identifier)
  #   * [:md, "…"]    → inline GFM through DocsUI::Markdown (bold/links/inline code),
  #                     opt-in so a plain String that merely *looks* like markdown
  #                     is never surprise-parsed.
  #
  # PropTable is a thin preset over this (name/type/default/description, first
  # column auto-code-styled).
  class Table < Phlex::HTML
    WRAPPER = "not-prose my-4 overflow-x-auto rounded-box border border-base-300"
    TABLE = "table table-sm table-zebra"

    def initialize(headers, rows)
      @headers = headers
      @rows = rows
    end

    def view_template
      div(class: WRAPPER) do
        table(class: TABLE) do
          thead do
            tr { @headers.each { |header| th(class: "whitespace-nowrap") { plain header.to_s } } }
          end
          tbody do
            @rows.each { |cells| tr { cells.each { |cell| td { render_cell(cell) } } } }
          end
        end
      end
    end

    private

    # Dispatch a cell by its shape. A [type, value] pair selects an inline
    # renderer; anything else is plain, Phlex-escaped text.
    def render_cell(cell)
      case cell
      in [:code, value] then code(class: "text-sm") { plain value.to_s }
      in [:md, value] then render DocsUI::Markdown.inline(value.to_s)
      in [Symbol => _tag, *]
        raise ArgumentError,
              "DocsUI::Table: unknown or malformed typed cell #{cell.inspect}; use [:code, value] or [:md, value]"
      else plain cell.to_s
      end
    end
  end
end
