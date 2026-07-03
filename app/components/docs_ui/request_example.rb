# frozen_string_literal: true

module DocsUI
  # One structured request declaration → one code tab per configured API client.
  # Declare method/path/body once and every client (curl, javascript, ruby,
  # python by default; plus whatever a site adds) renders its own snippet, in a
  # DocsUI::Example so the sticky global language preference keeps working.
  #
  #   render DocsUI::RequestExample.new(
  #     method: :post, path: "/v1/webhook_endpoints",
  #     body: { url: "https://example.com/hook", events: ["payment.paid"] }
  #   )
  #
  #   # only some tabs, in a chosen order:
  #   render DocsUI::RequestExample.new(method: :get, path: "/v1/things", clients: %i[curl ruby])
  #
  # The base URL and an example auth header come from config
  # (DocsKit.configuration.api_base_url / #api_auth_header); the client set comes
  # from #api_clients (defaults + site overrides). This replaces the per-client
  # heredoc a docs page used to hand-write once per endpoint per language.
  class RequestExample < Phlex::HTML
    def initialize(method:, path:, body: nil, query: nil, headers: {}, clients: nil)
      @method = method
      @path = path
      @body = body
      @query = query || {}
      @headers = headers || {}
      @clients = clients
    end

    def view_template
      request = build_request
      selected = selected_clients

      render DocsUI::Example.new do |ex|
        selected.each do |token, client|
          ex.code(
            token,
            lexer: client.lexer,
            label: client.label,
            filename: client.filename_for(request)
          ) { client.render(request) }
        end
      end
    end

    private

    # The request struct handed to every client template: config base URL + path,
    # config auth header merged into the headers.
    def build_request
      config = DocsKit.configuration
      DocsKit::ApiRequest.new(
        method: @method,
        path: @path,
        url: "#{config.api_base_url}#{@path}",
        query: @query,
        headers: merged_headers(config.api_auth_header),
        body: @body
      )
    end

    # The site's example Authorization header (if any) merged into the per-request
    # headers. The header line is "Name: value"; split it into a { name => value }
    # entry so templates can format it per language.
    def merged_headers(auth_header)
      return @headers if auth_header.nil? || auth_header.strip.empty?

      name, value = auth_header.split(":", 2).map(&:strip)
      { name => value }.merge(@headers)
    end

    # The { token => ApiClient } tabs to render, in order: the configured full map,
    # or just the requested `clients:` tokens (in the given order), skipping any
    # unknown token so a typo degrades to fewer tabs rather than raising.
    def selected_clients
      configured = DocsKit.configuration.api_clients
      return configured if @clients.nil?

      @clients.filter_map { |token| [token.to_sym, configured[token.to_sym]] if configured.key?(token.to_sym) }.to_h
    end
  end
end
