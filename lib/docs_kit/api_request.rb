# frozen_string_literal: true

require "json"
require "uri"

module DocsKit
  # A single API request, declared once and handed to every client template so a
  # snippet is authored one place, not per language. DocsUI::RequestExample builds
  # one from its args (merging DocsKit.configuration.api_base_url + the auth header)
  # and each DocsKit::ApiClient#template receives it.
  #
  #   req = DocsKit::ApiRequest.new(
  #     method: :post, path: "/v1/things",
  #     url: "https://api.example.com/v1/things",
  #     body: { name: "Acme" }
  #   )
  #   req.http_method       # => "POST"
  #   req.pretty_body_json  # => %({\n  "name": "Acme"\n})
  #
  # Templates stay one short heredoc each: they read #http_method, #url,
  # #url_with_query, #headers, #body?, and #pretty_body_json.
  ApiRequest = Data.define(:method, :path, :url, :query, :headers, :body) do
    def initialize(method:, path:, url:, query: {}, headers: {}, body: nil)
      super
    end

    # The upcased HTTP verb for display in a snippet ("POST", "GET", ...).
    def http_method = method.to_s.upcase

    # Whether the request carries a payload body (drives whether a template emits
    # its payload lines at all).
    def body? = !body.nil?

    # The body as pretty-printed JSON with string keys (deep-stringified), or nil
    # when there is no body. A String body is passed through unchanged.
    def pretty_body_json
      return nil unless body?
      return body if body.is_a?(String)

      JSON.pretty_generate(deep_stringify(body))
    end

    # A URL-encoded "?a=1&b=2" query string, or "" when there is no query.
    def query_string
      return "" if query.nil? || query.empty?

      "?#{URI.encode_www_form(query)}"
    end

    # The URL with the query string appended (the copy-pasteable request target).
    def url_with_query = "#{url}#{query_string}"

    private

    # Recursively stringify Hash/Array keys and symbol values so JSON output reads
    # like a real API response (no Ruby :symbol / => syntax leaking through).
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
