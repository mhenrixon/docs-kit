# frozen_string_literal: true

module DocsKit
  module OpenApi
    # One OpenAPI operation (a path + verb), exposing exactly the shapes the kit's
    # render targets consume:
    #   #parameter_rows / #body_rows → DocsUI::FieldTable
    #   #error_rows                  → DocsUI::ErrorTable
    #   #example_body / #success_example → DocsUI::JsonResponse / RequestExample body
    #   #example_path / #example_query   → the RequestExample snippet URL
    #   #code_samples                → DocsUI::Example tabs (x-codeSamples)
    #
    # It never renders — it's the bridge value object DocsUI::OpenApiOperation
    # reads. All schema traversal delegates to DocsKit::OpenApi::Schema.
    class Operation
      # Both spellings of the code-samples vendor extension seen in the wild
      # (Redoc uses x-codeSamples; older tooling x-code-samples).
      CODE_SAMPLE_KEYS = %w[x-codeSamples x-code-samples].freeze

      # The media type the bridge reads bodies/examples from.
      JSON_MEDIA_TYPE = "application/json"

      attr_reader :path

      def initialize(document, method:, path:, raw:)
        @document = document
        @method = method
        @path = path
        @raw = raw
      end

      def http_method = @method.to_s.upcase
      def operation_id = @raw["operationId"]
      def summary = @raw["summary"]
      def description = @raw["description"]
      def deprecated? = @raw["deprecated"] == true

      # The section title: the summary, else the operationId, else the verb+path.
      def title
        summary || operation_id || "#{http_method} #{path}"
      end

      # FieldTable rows for the operation's query/path/header parameters.
      def parameter_rows
        parameters.map do |param|
          {
            name: param["name"],
            type: Schema.new(@document, param["schema"]).type_label,
            required: param["required"] == true,
            description: description_cell(param["description"])
          }
        end
      end

      # FieldTable rows for the request-body schema (flattened, nested-dotted).
      def body_rows
        schema = request_body_schema
        return [] unless schema

        Schema.new(@document, schema).rows
      end

      # ErrorTable rows for the 4xx/5xx responses: status + scenario (the response
      # description) + an optional error type read from the response example.
      def error_rows
        error_responses.map do |status, response|
          {
            status: status,
            scenario: response_description(response),
            type: error_type_for(response)
          }
        end
      end

      # A synthesized (or explicit) request body example Hash, or nil when the
      # operation has no request body.
      def example_body
        schema = request_body_schema
        return unless schema

        media = request_body_media
        return media["example"] if media&.key?("example")

        first_examples_value(media) || Schema.new(@document, schema).example_value
      end

      # The path with each path-parameter placeholder replaced by its example
      # (copy-pasteable), leaving {placeholders} without an example untouched.
      def example_path
        path.gsub(/\{(\w+)\}/) do
          name = Regexp.last_match(1)
          param = path_parameters.find { |p| p["name"] == name }
          example = param && param["example"]
          example.nil? ? "{#{name}}" : example.to_s
        end
      end

      # { name => value } for query params that carry an explicit example (never
      # invent a value for a required-but-example-less param — it stays doc-only).
      def example_query
        query_parameters.each_with_object({}) do |param, acc|
          acc[param["name"]] = param["example"] if param.key?("example")
        end
      end

      # The first 2xx response's example body (explicit or synthesized), or nil.
      def success_example
        _, response = success_response
        return unless response

        media = json_media(response)
        return unless media

        return media["example"] if media.key?("example")

        first_examples_value(media) || example_from_schema(media["schema"])
      end

      # x-codeSamples entries as { lang:, label:, source: } (either spelling).
      def code_samples
        raw_samples.map do |sample|
          {
            lang: sample["lang"],
            label: sample["label"],
            source: sample["source"].to_s
          }
        end
      end

      private

      def parameters
        Array(@raw["parameters"]).map { |p| @document.deref(p) }
      end

      def path_parameters = parameters.select { |p| p["in"] == "path" }
      def query_parameters = parameters.select { |p| p["in"] == "query" }

      def request_body
        @document.deref(@raw["requestBody"])
      end

      def request_body_media
        body = request_body
        return unless body.is_a?(Hash)

        (body["content"] || {})[JSON_MEDIA_TYPE]
      end

      def request_body_schema
        media = request_body_media
        media && media["schema"]
      end

      def responses = @raw["responses"] || {}

      def error_responses
        responses.select { |status, _| status.to_s =~ /\A[45]/ }
                 .transform_values { |r| @document.deref(r) }
      end

      def success_response
        responses.map { |status, r| [status, @document.deref(r)] }
                 .find { |status, _| status.to_s.start_with?("2") }
      end

      def json_media(response)
        return unless response.is_a?(Hash)

        (response["content"] || {})[JSON_MEDIA_TYPE]
      end

      def response_description(response)
        desc = response["description"]
        desc.nil? || desc.to_s.strip.empty? ? http_method : desc.to_s
      end

      # An error type is not a first-class OpenAPI field. When a response example
      # carries a top-level "type" string, surface it; otherwise nil.
      def error_type_for(response)
        media = json_media(response)
        return unless media

        example = media["example"] || first_examples_value(media)
        example.is_a?(Hash) ? example["type"] : nil
      end

      # The value of the first entry in an `examples` (plural) map, or nil.
      def first_examples_value(media)
        return unless media.is_a?(Hash)

        examples = media["examples"]
        return unless examples.is_a?(Hash) && !examples.empty?

        entry = @document.deref(examples.values.first)
        entry.is_a?(Hash) ? entry["value"] : nil
      end

      def example_from_schema(schema)
        schema && Schema.new(@document, schema).example_value
      end

      def description_cell(text)
        text && !text.to_s.strip.empty? ? [:md, text.to_s] : nil
      end

      def raw_samples
        key = CODE_SAMPLE_KEYS.find { |k| @raw.key?(k) }
        key ? Array(@raw[key]) : []
      end
    end
  end
end
