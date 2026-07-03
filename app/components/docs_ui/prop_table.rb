# frozen_string_literal: true

module DocsUI
  # A props/options/params reference table: name · type · default · description,
  # with the first column (the name) auto code-styled. A thin preset over
  # DocsUI::Table — same cell conventions, same markup, no duplication.
  #
  #   render DocsUI::PropTable.new(
  #     [
  #       ["brand", "String", '"Docs"', "Topbar + sidebar heading."],
  #       ["themes", "Array", "%w[dark light]", "ThemeSwitcher options."],
  #     ]
  #   )
  #
  # The default headers are Option/Type/Default/Description; pass `headers:` to
  # override (e.g. `%w[Arg Type Default Description]` for a component's args). Cell
  # values follow DocsUI::Table's convention (String / [:code, "x"] / [:md, "…"]);
  # the first cell of each row is wrapped in <code> automatically unless it's
  # already a special-cell pair.
  class PropTable < Phlex::HTML
    DEFAULT_HEADERS = %w[Option Type Default Description].freeze

    def initialize(rows, headers: DEFAULT_HEADERS)
      @rows = rows.map { |cells| code_first_column(cells) }
      @headers = headers
    end

    def view_template
      render DocsUI::Table.new(@headers, @rows)
    end

    private

    # Auto-code-style the name column. A plain String first cell becomes a
    # [:code, …] cell; a cell that's already a typed pair ([:code, …]/[:md, …]) is
    # left as the author wrote it.
    def code_first_column(cells)
      first, *rest = cells
      first = [:code, first] unless first.is_a?(Array)
      [first, *rest]
    end
  end
end
