# frozen_string_literal: true

require "json"

module DocsUI
  # A pretty-printed JSON response block. Give it a Ruby Hash (deep-stringified and
  # JSON.pretty_generate'd) or a pre-formatted String; it renders a DocsUI::Code
  # with the json lexer and a filename title bar. Kills the hand-rolled
  # deep_stringify + JSON.pretty_generate every API page was copy-pasting.
  #
  #   render DocsUI::JsonResponse.new({ id: "obj_1", status: "active" })
  #   render DocsUI::JsonResponse.new(raw_json_string, filename: "webhook.json")
  #
  # A Hash with symbol keys renders as real JSON (string keys, no :symbol / =>
  # leaking through). A String is passed through verbatim (already formatted).
  class JsonResponse < Phlex::HTML
    def initialize(body, filename: "response.json")
      @body = body
      @filename = filename
    end

    def view_template
      render DocsUI::Code.new(json_source, lexer: :json, filename: @filename)
    end

    private

    # The JSON string to highlight: a String passes through; a Hash/Array is
    # deep-stringified then pretty-generated so it reads like an API response.
    def json_source
      return @body if @body.is_a?(String)

      JSON.pretty_generate(deep_stringify(@body))
    end

    # Recursively stringify keys and symbol values so the output is real JSON.
    def deep_stringify(value)
      case value
      when Hash then value.to_h { |k, v| [k.to_s, deep_stringify(v)] }
      when Array then value.map { |v| deep_stringify(v) }
      when Symbol then value.to_s
      else value
      end
    end
  end
end
