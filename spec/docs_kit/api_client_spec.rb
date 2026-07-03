# frozen_string_literal: true

RSpec.describe DocsKit::ApiClient do
  def request(**overrides)
    DocsKit::ApiRequest.new(method: :get, path: "/v1/things", url: "https://api.example.com/v1/things", **overrides)
  end

  it "carries label/lexer/filename/template" do
    client = described_class.new(label: "cURL", lexer: :curl, filename: "request.sh", template: ->(_r) { "curl" })
    expect(client.label).to eq("cURL")
    expect(client.lexer).to eq(:curl)
    expect(client.filename).to eq("request.sh")
    expect(client.template).to respond_to(:call)
  end

  it "defaults filename to nil" do
    expect(described_class.new(label: "X", lexer: :ruby, template: ->(_r) { "" }).filename).to be_nil
  end

  describe "#filename_for" do
    it "returns a static string filename verbatim" do
      client = described_class.new(label: "cURL", lexer: :curl, filename: "request.sh", template: ->(_r) { "" })
      expect(client.filename_for(request)).to eq("request.sh")
    end

    it "calls a proc filename with the request" do
      client = described_class.new(
        label: "cURL", lexer: :curl,
        filename: ->(req) { "#{req.http_method.downcase}.sh" }, template: ->(_r) { "" }
      )
      expect(client.filename_for(request(method: :post))).to eq("post.sh")
    end
  end

  describe "#render" do
    it "runs the template against the request" do
      client = described_class.new(
        label: "cURL", lexer: :curl,
        template: ->(req) { "curl #{req.url}" }
      )
      expect(client.render(request)).to eq("curl https://api.example.com/v1/things")
    end
  end

  describe "the four shipped defaults" do
    def render_default(token, **request_overrides)
      DocsKit::ApiClient::DEFAULTS.fetch(token).render(request(**request_overrides))
    end

    it "curl emits the method, url and (with a body) a -d payload" do
      out = render_default(:curl, method: :post, body: { name: "Acme" },
                                  url: "https://api.example.com/v1/things")
      expect(out).to include("curl -X POST")
      expect(out).to include("https://api.example.com/v1/things")
      expect(out).to include("-d '")
      expect(out).to include('"name": "Acme"')
    end

    it "curl omits the -d payload for a body-less GET" do
      out = render_default(:curl)
      expect(out).not_to include("-d ")
      expect(out).to include("https://api.example.com/v1/things")
    end

    it "curl adds an -H auth header line when the request carries one" do
      out = render_default(:curl, headers: { "Authorization" => "Bearer sk_live_..." })
      expect(out).to include('-H "Authorization: Bearer sk_live_..."')
    end

    it "javascript emits a fetch call, with a JSON body only when present" do
      with_body = render_default(:javascript, method: :post, body: { name: "Acme" })
      expect(with_body).to include("fetch(")
      expect(with_body).to include("method: \"POST\"")
      expect(with_body).to include("body: JSON.stringify(")

      without_body = render_default(:javascript)
      expect(without_body).to include("fetch(")
      expect(without_body).not_to include("body: JSON.stringify(")
    end

    it "javascript inlines a non-JSON String body verbatim instead of raising" do
      out = render_default(:javascript, method: :post, body: "name=Acme")
      expect(out).to include("body: JSON.stringify(name=Acme)")
    end

    it "ruby emits a Net::HTTP snippet, with a request body only when present" do
      with_body = render_default(:ruby, method: :post, body: { name: "Acme" })
      expect(with_body).to include("Net::HTTP")
      expect(with_body).to include("request.body =")

      without_body = render_default(:ruby)
      expect(without_body).to include("Net::HTTP")
      expect(without_body).not_to include("request.body =")
    end

    it "python emits a requests call, passing json= only when a body is present" do
      with_body = render_default(:python, method: :post, body: { name: "Acme" })
      expect(with_body).to include("import requests")
      expect(with_body).to include("requests.post(")
      expect(with_body).to include("json=")

      without_body = render_default(:python)
      expect(without_body).to include("requests.get(")
      expect(without_body).not_to include("json=")
    end
  end
end
