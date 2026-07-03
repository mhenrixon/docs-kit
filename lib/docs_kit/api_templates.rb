# frozen_string_literal: true

module DocsKit
  # The four generic-HTTP snippet templates the gem ships (curl, fetch, Net::HTTP,
  # requests). Each is a `(DocsKit::ApiRequest) -> String` callable, referenced by
  # DocsKit::ApiClient::DEFAULTS.
  #
  # The gem intentionally ships GENERIC HTTP snippets — it cannot know a site's
  # SDK. A site swaps in SDK-flavored templates (or adds a `cli` client) by
  # overriding c.api_clients; these are the fallback every site starts from.
  #
  # Every template guards its payload lines on request.body? so a body-less GET
  # renders no dangling `-d`/`json=`/`request.body =` line.
  module ApiTemplates
    module_function

    # curl -X METHOD 'url' [-H "Header: v"]... [-d '{json}']
    def curl(request)
      lines = ["curl -X #{request.http_method} '#{request.url_with_query}'"]
      request.headers.each { |name, value| lines << %(  -H "#{name}: #{value}") }
      lines << %(  -H "Content-Type: application/json") if request.body?
      lines << "  -d '#{request.pretty_body_json}'" if request.body?
      lines.join(" \\\n")
    end

    # A fetch() call with a headers object and an optional JSON body.
    def javascript(request)
      headers = { "Content-Type" => "application/json" }.merge(request.headers)
      header_lines = headers.map { |k, v| %(    "#{k}": "#{v}") }.join(",\n")
      body_line = request.body? ? %(\n  body: JSON.stringify(#{compact_json(request)}),) : ""

      <<~JS.strip
        const response = await fetch("#{request.url_with_query}", {
          method: "#{request.http_method}",
          headers: {
        #{header_lines}
          },#{body_line}
        });
        const data = await response.json();
      JS
    end

    # A Net::HTTP snippet: build the request, set headers, optional JSON body, send.
    def ruby(request)
      header_lines = request.headers.map { |k, v| %(request["#{k}"] = "#{v}") }
      body_line = request.body? ? %(request.body = #{request.pretty_body_json}.to_json) : nil

      <<~RUBY.strip
        require "net/http"
        require "json"

        uri = URI("#{request.url_with_query}")
        request = Net::HTTP::#{request.http_method.capitalize}.new(uri)
        request["Content-Type"] = "application/json"
        #{[*header_lines, body_line].compact.join("\n")}

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
          http.request(request)
        end
      RUBY
    end

    # A requests.<verb>(url, headers=..., json=...) call. Pretty JSON with
    # double-quoted keys is valid Python dict syntax, so it drops straight into json=.
    def python(request)
      headers = { "Content-Type" => "application/json" }.merge(request.headers)
      header_repr = headers.map { |k, v| %("#{k}": "#{v}") }.join(", ")
      json_arg = request.body? ? ", json=#{request.pretty_body_json}" : ""

      <<~PY.strip
        import requests

        response = requests.#{request.method.to_s.downcase}(
            "#{request.url_with_query}",
            headers={#{header_repr}}#{json_arg},
        )
        data = response.json()
      PY
    end

    # --- helpers ------------------------------------------------------------

    # The body as compact single-line JSON, for inlining in a JS literal.
    def compact_json(request)
      require "json"
      json = request.pretty_body_json
      JSON.generate(JSON.parse(json))
    rescue JSON::ParserError
      json
    end
  end
end
