# frozen_string_literal: true

RSpec.describe DocsUI::RequestExample do
  def render_request(...)
    described_class.new(...).call
  end

  it "renders one tab per configured client (the four defaults)" do
    html = render_request(method: :post, path: "/v1/things", body: { name: "Acme" })

    %w[curl javascript ruby python].each do |token|
      expect(html.scan(%(data-testid="code-lang-#{token}")).size).to eq(1)
    end
    expect(html.scan('data-docs-nav-target="codePanel"').size).to eq(4)
  end

  it "labels each tab from the configured language labels" do
    html = render_request(method: :get, path: "/v1/things")

    expect(html).to include(">cURL<")
    expect(html).to include(">JavaScript<")
    expect(html).to include(">Ruby<")
    expect(html).to include(">Python<")
  end

  it "builds the curl tab from api_base_url + path, method and a -d JSON body" do
    DocsKit.configure { |c| c.api_base_url = "https://api.acme.test" }
    html = render_request(method: :post, path: "/v1/things", body: { name: "Acme" })

    expect(html).to include("https://api.acme.test/v1/things")
    expect(html).to include("curl -X POST")
    expect(html).to include("Acme") # the JSON body payload
  end

  it "injects the configured auth header into the curl snippet" do
    DocsKit.configure { |c| c.api_auth_header = "Authorization: Bearer sk_live_..." }
    html = render_request(method: :get, path: "/v1/things")

    expect(html).to include("Authorization: Bearer sk_live_...")
  end

  it "drops a colon-less auth header instead of emitting a value-less line" do
    DocsKit.configure { |c| c.api_auth_header = "Bearer sk_live_xyz" }
    html = render_request(method: :get, path: "/v1/things")

    # No malformed `-H "Bearer sk_live_xyz: "` (name with an empty value).
    expect(html).not_to include("Bearer sk_live_xyz")
  end

  it "filters and orders the tabs when clients: is given" do
    html = render_request(method: :get, path: "/v1/things", clients: %i[ruby curl])

    expect(html.scan('data-docs-nav-target="codePanel"').size).to eq(2)
    expect(html).to include('data-testid="code-lang-ruby"')
    expect(html).to include('data-testid="code-lang-curl"')
    expect(html).not_to include('data-testid="code-lang-python"')
    # order follows the clients: array (ruby tab before curl tab)
    expect(html.index("code-lang-ruby")).to be < html.index("code-lang-curl")
  end

  it "renders a site-added custom client from config" do
    cli = DocsKit::ApiClient.new(
      label: "CLI", lexer: :shell, filename: "acme",
      template: ->(req) { "acme things create --name #{req.body&.dig(:name)}" }
    )
    DocsKit.configure { |c| c.api_clients = { cli: cli } }

    # Alongside curl so Example renders tabs (a lone snippet degrades to no tabs).
    html = render_request(method: :post, path: "/v1/things", body: { name: "Acme" }, clients: %i[cli curl])

    expect(html).to include(">CLI<") # the client's own label, not the token capitalized
    expect(html).to include('data-testid="code-lang-cli"')
    # The snippet ran through the client template (Rouge highlights the :shell
    # tokens, so assert on the surviving pieces, not the whole command line).
    expect(html).to include("acme things create")
    expect(html).to include("Acme")
  end

  it "omits payload lines in every default template for a body-less GET" do
    html = render_request(method: :get, path: "/v1/things")

    expect(html).not_to include("-d ") # curl
    expect(html).not_to include("body: JSON.stringify") # javascript
    expect(html).not_to include("request.body =")    # ruby
    expect(html).not_to include("json=")             # python
  end

  it "keeps Example's progressive-enhancement markup (no server-side hidden panels)" do
    html = render_request(method: :get, path: "/v1/things")

    # Example never sets the `hidden` attribute server-side; the docs-nav JS
    # toggles it. With JS off every panel is visible (all four still present).
    expect(html).to include('data-docs-nav-target="codeGroup"')
    expect(html.scan('data-docs-nav-target="codePanel"').size).to eq(4)
    expect(html).not_to match(/<[^>]*\shidden(\s|>|=)/) # no `hidden` HTML attribute
  end
end
