# frozen_string_literal: true

module DocsUI
  # A parameter/field reference table for an API object or request body — a
  # keyword-schema preset over DocsUI::Table. Each field is a Hash:
  #
  #   render DocsUI::FieldTable.new(
  #     [
  #       { name: "url",         type: "string", required: true, description: "HTTPS destination URL." },
  #       { name: "description", type: "string",                 description: "Optional internal label." },
  #       { name: "events",      type: "array",  required: true, description: [:md, "e.g. `payment_link.paid`"] },
  #     ]
  #   )
  #
  # Columns: Name (auto code-styled) / Type / Required (✓ or the canonical em-dash
  # `—`) / Description. `required:` defaults to false. The description cell follows
  # DocsUI::Table's convention — a plain String is escaped text, `[:code, "x"]` is
  # inline code, `[:md, "…"]` is inline Markdown.
  class FieldTable < Phlex::HTML
    HEADERS = %w[Name Type Required Description].freeze

    # The ONE canonical "no value" placeholder across the whole kit — never the
    # ASCII hyphen "-", never a bare "—" typed ad hoc in a page.
    REQUIRED_YES = "✓"
    REQUIRED_NO = "—"

    def initialize(fields)
      @fields = fields
    end

    def view_template
      render DocsUI::Table.new(HEADERS, @fields.map { |field| row(field) })
    end

    private

    def row(field)
      [
        [:code, field.fetch(:name)],
        field.fetch(:type),
        field.fetch(:required, false) ? REQUIRED_YES : REQUIRED_NO,
        field.fetch(:description, REQUIRED_NO)
      ]
    end
  end
end
