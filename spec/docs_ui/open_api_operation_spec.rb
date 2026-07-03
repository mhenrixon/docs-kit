# frozen_string_literal: true

# DocsUI::OpenApiOperation renders one DocsKit::OpenApi::Operation through the
# existing kit (Section + Endpoint + FieldTables + ErrorTable + RequestExample +
# JsonResponse). It reads config (api_base_url/auth for the snippet URL), so
# render through the real component and assert on the produced markup's semantics.
RSpec.describe DocsUI::OpenApiOperation do
  let(:yaml_path) { File.expand_path("../fixtures/openapi.yaml", __dir__) }
  let(:doc) { DocsKit::OpenApi.load(yaml_path) }

  def render_op(operation, **)
    described_class.new(operation, **).call
  end

  describe "the section + endpoint header" do
    it "titles the section with the operation summary" do
      html = render_op(doc.operation("createInvoice"))

      expect(html).to include(">Create an invoice<")
    end

    it "anchors the section id to the operationId (deep links + auto-TOC)" do
      html = render_op(doc.operation("createInvoice"))

      expect(html).to include('id="createInvoice"')
    end

    it "renders an Endpoint badge with the verb and path" do
      html = render_op(doc.operation("createInvoice"))

      expect(html).to include(">POST</code>")
      expect(html).to include(">/v1/invoices</code>")
    end

    it "renders the operation description as Markdown prose" do
      html = render_op(doc.operation("listInvoices"))

      # "Returns a paginated list of **invoices**." → the bold survives as <strong>.
      expect(html).to include("<strong>invoices</strong>")
    end
  end

  describe "the field tables" do
    it "renders a parameters FieldTable for query/path params" do
      html = render_op(doc.operation("listInvoices"))

      expect(html).to include(">limit</code>")
      expect(html).to include(">status</code>")
    end

    it "renders a request-body FieldTable flattening the schema (incl. nested/allOf)" do
      html = render_op(doc.operation("createInvoice"))

      expect(html).to include(">amount</code>")
      expect(html).to include(">idempotency_key</code>") # from the allOf branch
      expect(html).to include(">customer.id</code>") # nested object dotted
    end

    it "leaves a lone table unlabelled (no redundant heading)" do
      # createInvoice has a body but no parameters → a single table, no label.
      html = render_op(doc.operation("createInvoice"))

      expect(html).not_to include(">Parameters</h3>")
      expect(html).not_to include(">Request body</h3>")
    end

    it "labels both tables when the operation has parameters AND a request body" do
      op = build_op(
        "parameters" => [{ "name" => "page", "in" => "query", "schema" => { "type" => "integer" } }],
        "requestBody" => { "content" => { "application/json" => {
          "schema" => { "type" => "object", "properties" => { "name" => { "type" => "string" } } }
        } } },
        "responses" => {}
      )
      html = render_op(op)

      expect(html).to include(">Parameters</h3>")
      expect(html).to include(">Request body</h3>")
    end
  end

  describe "the error table" do
    it "renders 4xx/5xx responses as ErrorTable rows" do
      html = render_op(doc.operation("createInvoice"))

      expect(html).to include(">Scenario")
      expect(html).to include("401")
      expect(html).to include("422")
      expect(html).to include(">authentication_error</code>") # type from the example
    end

    it "omits the error table entirely when the operation has no 4xx/5xx responses" do
      op = build_op("responses" => { "200" => { "description" => "ok" } })
      html = render_op(op)

      expect(html).not_to include(">Scenario")
    end
  end

  describe "the request example" do
    it "renders RequestExample client tabs" do
      html = render_op(doc.operation("createInvoice"))

      expect(html).to include('data-testid="code-lang-curl"')
      expect(html).to include('data-testid="code-lang-ruby"')
    end

    it "passes clients: through to filter/order the tabs" do
      html = render_op(doc.operation("createInvoice"), clients: %i[curl ruby])

      expect(html).to include('data-testid="code-lang-curl"')
      expect(html).to include('data-testid="code-lang-ruby"')
      expect(html).not_to include('data-testid="code-lang-python"')
    end

    it "substitutes the path parameter example into the snippet URL" do
      DocsKit.configure { |c| c.api_base_url = "https://api.acme.test" }
      # The DELETE /v1/invoices/{id} has a path param (example inv_123) and NO
      # x-codeSamples, so it renders a generated RequestExample with a concrete URL.
      html = render_op(doc.operation(:delete, "/v1/invoices/{id}"))

      expect(html).to include("https://api.acme.test/v1/invoices/inv_123")
    end
  end

  describe "x-codeSamples override" do
    it "renders x-codeSamples as Example tabs instead of the generated RequestExample" do
      html = render_op(doc.operation("getInvoice"))

      # getInvoice ships two x-codeSamples (Ruby SDK, CLI) with custom labels.
      expect(html).to include(">Ruby SDK<")
      expect(html).to include(">CLI<")
      # Rouge highlights the source, so assert on surviving fragments (the
      # identifiers survive as separate spans), not the whole call.
      expect(html).to include("Billing").and include("retrieve")
      # No generated curl tab — the samples replaced it.
      expect(html).not_to include('data-testid="code-lang-curl"')
    end

    it "renders a lone code sample as a plain Code block (Example needs two tabs)" do
      op = build_op(
        "x-codeSamples" => [{ "lang" => "ruby", "label" => "Ruby", "source" => "Billing.call" }],
        "responses" => {}
      )
      html = render_op(op)

      expect(html).to include("Billing").and include("call")
      # A single sample → no tablist (that's Example's ≥2 rule).
      expect(html).not_to include('role="tablist"')
    end
  end

  describe "the success response block" do
    it "renders a JsonResponse from the first 2xx example" do
      html = render_op(doc.operation("createInvoice"))

      # DocsUI::Code stamps data-md-lang with the resolved Rouge tag.
      expect(html).to include('data-md-lang="json"')
      expect(html).to include("inv_123")
    end

    it "omits the response block when no 2xx example is derivable" do
      op = build_op("responses" => { "500" => { "description" => "boom" } })
      html = render_op(op)

      expect(html).not_to include('data-md-lang="json"')
    end
  end

  describe "the trailing block" do
    it "renders a passed block after the generated content (append hand-authored prose)" do
      html = described_class.new(doc.operation("createInvoice")).call do |c|
        c.plain "Extra author note."
      end

      expect(html).to include("Extra author note.")
    end
  end

  # A minimal single-operation Document, for the edge cases the fixture doesn't cover.
  def build_op(operation)
    DocsKit::OpenApi.load("openapi" => "3.0.3", "paths" => { "/x" => { "get" => operation } })
                    .operations.first
  end
end
