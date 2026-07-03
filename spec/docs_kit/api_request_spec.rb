# frozen_string_literal: true

RSpec.describe DocsKit::ApiRequest do
  def build(**overrides)
    described_class.new(method: :get, path: "/v1/things",
                        url: "https://api.example.com/v1/things", **overrides)
  end

  it "carries method/path/url and optional query/headers/body" do
    req = build
    expect(req.method).to eq(:get)
    expect(req.path).to eq("/v1/things")
    expect(req.url).to eq("https://api.example.com/v1/things")
    expect(req.query).to eq({})
    expect(req.headers).to eq({})
    expect(req.body).to be_nil
  end

  it "upcases the HTTP method for display" do
    expect(build(method: :post).http_method).to eq("POST")
    expect(build(method: "patch").http_method).to eq("PATCH")
  end

  describe "#body?" do
    it "is false with no body" do
      expect(build.body?).to be(false)
    end

    it "is true when a body hash is present" do
      expect(build(method: :post, body: { name: "x" }).body?).to be(true)
    end
  end

  describe "#pretty_body_json" do
    it "is nil when there is no body" do
      expect(build.pretty_body_json).to be_nil
    end

    it "deep-stringifies symbol keys and pretty-prints" do
      req = build(method: :post, body: { name: "Acme", nested: { count: 2 } })
      json = req.pretty_body_json

      expect(json).to include('"name": "Acme"')
      expect(json).to include('"nested": {')
      expect(json).to include('"count": 2')
      # pretty_generate uses two-space indentation across lines.
      expect(json).to include("\n  ")
    end

    it "deep-stringifies nested arrays and symbol values" do
      req = build(method: :post, body: { events: %i[payment_link_paid refund_created] })
      json = req.pretty_body_json

      expect(json).to include('"payment_link_paid"') # symbol → JSON string
      expect(json).to include('"refund_created"')
      expect(json).not_to include(":payment_link_paid") # no Ruby symbol leaking
    end

    it "passes a String body through unchanged (already formatted)" do
      req = build(method: :post, body: %({"a": 1}))
      expect(req.pretty_body_json).to eq(%({"a": 1}))
    end
  end

  describe "#query_string" do
    it "is empty when there is no query" do
      expect(build.query_string).to eq("")
    end

    it "renders a URL-encoded ?key=value string" do
      req = build(query: { limit: 10, cursor: "a b" })
      expect(req.query_string).to eq("?limit=10&cursor=a+b")
    end
  end

  describe "#url_with_query" do
    it "returns the bare url with no query" do
      expect(build.url_with_query).to eq("https://api.example.com/v1/things")
    end

    it "appends the encoded query string" do
      expect(build(query: { limit: 10 }).url_with_query).to eq("https://api.example.com/v1/things?limit=10")
    end
  end
end
