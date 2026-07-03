# frozen_string_literal: true

module DocsUI
  # Renders one OpenAPI operation as a full endpoint reference, composed entirely
  # from the existing kit — zero hand-restatement. Given a
  # DocsKit::OpenApi::Operation it emits:
  #
  #   * a DocsUI::Section titled with the operation summary (id: the operationId,
  #     so deep links + the auto-TOC resolve), described by a DocsUI::Endpoint badge;
  #   * the operation description as Markdown prose (when present);
  #   * a parameters DocsUI::FieldTable and a request-body DocsUI::FieldTable (each
  #     labelled only when BOTH are present, so a single table reads clean);
  #   * a DocsUI::ErrorTable from the 4xx/5xx responses (when any);
  #   * the request block — the operation's x-codeSamples (a DocsUI::Example when
  #     ≥2, a plain DocsUI::Code when exactly one), else a generated
  #     DocsUI::RequestExample (respecting a passed clients: filter);
  #   * a DocsUI::JsonResponse from the first 2xx example (when derivable);
  #   * finally the caller's block, so a page can append hand-authored prose.
  #
  #   render DocsUI::OpenApiOperation.new(doc.operation("createInvoice"))
  #
  # The `operation` page helper is the friction-free front door; use this directly
  # for bespoke composition. It reads config only through the components it composes
  # (RequestExample pulls api_base_url/auth), never hardcodes a site value.
  class OpenApiOperation < Phlex::HTML
    def initialize(operation, clients: nil)
      @operation = operation
      @clients = clients
    end

    def view_template(&block)
      render DocsUI::Section.new(@operation.title, id: @operation.operation_id, description: endpoint_badge) do
        operation_description
        field_tables
        error_table
        request_block
        success_response
        yield_content(&block)
      end
    end

    private

    def endpoint_badge
      DocsUI::Endpoint.new(@operation.http_method, @operation.path)
    end

    def operation_description
      description = @operation.description
      render DocsUI::Markdown.new(description) if present?(description)
    end

    # Both FieldTables, each labelled only when the OTHER is also present (so a
    # lone table reads clean without a redundant "Parameters"/"Body" heading).
    def field_tables
      params = @operation.parameter_rows
      body = @operation.body_rows
      both = !params.empty? && !body.empty?

      field_table("Parameters", params, labelled: both)
      field_table("Request body", body, labelled: both)
    end

    def field_table(label, rows, labelled:)
      return if rows.empty?

      # All utility classes here are already emitted elsewhere in the kit
      # (prose.rb / header.rb / shell.rb), so no new Tailwind @source scan is
      # needed — see Critical Rule 6.
      h3(class: "mb-2 mt-8 text-lg font-semibold") { label } if labelled
      render DocsUI::FieldTable.new(rows)
    end

    def error_table
      rows = @operation.error_rows
      render DocsUI::ErrorTable.new(rows) unless rows.empty?
    end

    # The request block: x-codeSamples win over the generated RequestExample. Two+
    # samples → a DocsUI::Example (tabbed); exactly one → a plain DocsUI::Code
    # (Example needs two tabs to render any); none → the generated RequestExample.
    def request_block
      samples = @operation.code_samples
      case samples.length
      when 0 then generated_request
      when 1 then single_code_sample(samples.first)
      else code_sample_tabs(samples)
      end
    end

    def generated_request
      render DocsUI::RequestExample.new(
        method: @operation.http_method,
        path: @operation.example_path,
        body: @operation.example_body,
        query: @operation.example_query,
        clients: @clients
      )
    end

    def single_code_sample(sample)
      render DocsUI::Code.new(sample[:source], lexer: sample[:lang])
    end

    def code_sample_tabs(samples)
      render DocsUI::Example.new do |ex|
        samples.each do |sample|
          ex.code(sample[:lang], label: sample[:label]) { sample[:source] }
        end
      end
    end

    def success_response
      example = @operation.success_example
      render DocsUI::JsonResponse.new(example) unless example.nil?
    end

    def yield_content(&block)
      yield self if block
    end

    def present?(value)
      !value.nil? && !value.to_s.strip.empty?
    end
  end
end
