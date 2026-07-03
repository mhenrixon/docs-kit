# frozen_string_literal: true

module DocsUI
  # An error reference table for an API endpoint — a keyword-schema preset over
  # DocsUI::Table. Each error is a Hash:
  #
  #   render DocsUI::ErrorTable.new(
  #     [
  #       { scenario: "Missing or invalid API key", status: "401", type: "authentication_error" },
  #       { scenario: "Non-HTTPS URL",              status: "422", type: "validation_error", param: "url" },
  #     ]
  #   )
  #
  # Columns: Scenario / Status / Type (auto code-styled) / Param (auto code-styled).
  # The Param column is shown only when at least one error names a param — an
  # endpoint whose errors are all param-free renders a clean three-column table.
  # When the column IS shown, a param-free row gets the canonical em-dash `—`.
  class ErrorTable < Phlex::HTML
    BASE_HEADERS = %w[Scenario Status Type].freeze
    PARAM_HEADER = "Param"

    # Shared with FieldTable's canonical "no value" placeholder.
    NO_PARAM = "—"

    def initialize(errors)
      @errors = errors
      @with_param = errors.any? { |error| error[:param] }
    end

    def view_template
      render DocsUI::Table.new(headers, @errors.map { |error| row(error) })
    end

    private

    def headers
      @with_param ? [*BASE_HEADERS, PARAM_HEADER] : BASE_HEADERS
    end

    def row(error)
      cells = [
        error.fetch(:scenario),
        error.fetch(:status),
        [:code, error.fetch(:type)]
      ]
      cells << param_cell(error) if @with_param
      cells
    end

    def param_cell(error)
      param = error[:param]
      param ? [:code, param] : NO_PARAM
    end
  end
end
