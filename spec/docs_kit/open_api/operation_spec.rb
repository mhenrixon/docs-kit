# frozen_string_literal: true

RSpec.describe DocsKit::OpenApi::Operation do
  let(:yaml_path) { File.expand_path("../../fixtures/openapi.yaml", __dir__) }
  let(:doc) { DocsKit::OpenApi.load(yaml_path) }

  describe "identity" do
    subject(:op) { doc.operation("createInvoice") }

    it "exposes the method, path, summary, description and operationId" do
      expect(op.http_method).to eq("POST")
      expect(op.path).to eq("/v1/invoices")
      expect(op.summary).to eq("Create an invoice")
      expect(op.description).to eq("Creates a new invoice for a customer.")
      expect(op.operation_id).to eq("createInvoice")
    end

    it "falls back the title to the operationId when summary is absent" do
      # Every fixture operation has a summary, so synthesize a summary-less op.
      op = build_operation({ "operationId" => "doThing", "responses" => {} })

      expect(op.title).to eq("doThing")
    end
  end

  describe "#parameter_rows" do
    it "returns FieldTable-ready rows for query/path params (name/type/required/[:md, desc])" do
      rows = doc.operation("listInvoices").parameter_rows

      limit = rows.find { |r| r[:name] == "limit" }
      expect(limit[:type]).to eq("integer")
      expect(limit[:required]).to be(false)
      expect(limit[:description]).to eq([:md, "How many invoices to return."])
    end

    it "marks a required path parameter required" do
      rows = doc.operation("getInvoice").parameter_rows

      id = rows.find { |r| r[:name] == "id" }
      expect(id[:required]).to be(true)
    end

    it "is empty for an operation with no parameters" do
      expect(doc.operation("createInvoice").parameter_rows).to eq([])
    end
  end

  describe "#body_rows" do
    subject(:rows) { doc.operation("createInvoice").body_rows }

    it "flattens the request-body schema properties into FieldTable rows" do
      names = rows.map { |r| r[:name] }
      expect(names).to include("amount", "currency", "idempotency_key")
    end

    it "labels an array-of-string property as 'array of string'" do
      line_items = rows.find { |r| r[:name] == "line_items" }
      expect(line_items[:type]).to eq("array of string")
    end

    it "marks a schema-required property required (from the schema's required list)" do
      amount = rows.find { |r| r[:name] == "amount" }
      expect(amount[:required]).to be(true)
    end

    it "dots nested object property names (customer.id, customer.name)" do
      names = rows.map { |r| r[:name] }
      expect(names).to include("customer.id", "customer.name")
    end

    it "renders an enum's type label as the allowed values" do
      currency = rows.find { |r| r[:name] == "currency" }
      expect(currency[:type]).to include("usd").and include("eur")
    end

    it "is empty for an operation with no request body" do
      expect(doc.operation("listInvoices").body_rows).to eq([])
    end
  end

  describe "#error_rows" do
    subject(:rows) { doc.operation("createInvoice").error_rows }

    it "returns one row per 4xx/5xx response (status + scenario from the description)" do
      statuses = rows.map { |r| r[:status] }
      expect(statuses).to contain_exactly("401", "422")
    end

    it "pulls the error type from a response example's top-level type field" do
      row = rows.find { |r| r[:status] == "401" }
      expect(row[:type]).to eq("authentication_error")
    end

    it "reads the type from an `examples` (plural) map too" do
      row = rows.find { |r| r[:status] == "422" }
      expect(row[:type]).to eq("validation_error")
    end

    it "omits 2xx responses from the error table" do
      expect(rows.map { |r| r[:status] }).not_to include("200")
    end

    it "leaves type nil when no example carries one" do
      op = build_operation({ "responses" => { "404" => { "description" => "Not found." } } })

      expect(op.error_rows.first).to eq(status: "404", scenario: "Not found.", type: nil)
    end
  end

  describe "#example_body (request body example precedence)" do
    it "synthesizes a body from the schema when no explicit example is given" do
      body = doc.operation("createInvoice").example_body

      # amount has an example (4200); currency has an enum → first value "usd".
      expect(body["amount"]).to eq(4200)
      expect(body["currency"]).to eq("usd")
    end

    it "returns nil for an operation with no request body" do
      expect(doc.operation("listInvoices").example_body).to be_nil
    end
  end

  describe "#example_path (path-parameter substitution for the snippet URL)" do
    it "substitutes a path parameter's example into the path" do
      expect(doc.operation("getInvoice").example_path).to eq("/v1/invoices/inv_123")
    end

    it "leaves the {placeholder} when the path param has no example" do
      op = build_operation(
        { "parameters" => [{ "name" => "id", "in" => "path", "required" => true,
                             "schema" => { "type" => "string" } }] },
        path: "/v1/things/{id}"
      )

      expect(op.example_path).to eq("/v1/things/{id}")
    end
  end

  describe "#example_query" do
    it "includes only query params that carry an explicit example" do
      # listInvoices: limit has example 10, status has none.
      expect(doc.operation("listInvoices").example_query).to eq("limit" => 10)
    end
  end

  describe "#success_example" do
    it "returns the first 2xx response's example body" do
      example = doc.operation("createInvoice").success_example

      expect(example["id"]).to eq("inv_123")
      expect(example["amount"]).to eq(4200)
    end

    it "synthesizes from the schema when the 2xx response has no explicit example" do
      # getInvoice's 200 has a schema ($ref Invoice) but no example block.
      example = doc.operation("getInvoice").success_example

      expect(example["id"]).to eq("inv_123") # from Invoice.id.example
    end

    it "returns nil when there is no 2xx response at all" do
      op = build_operation({ "responses" => { "500" => { "description" => "boom" } } })

      expect(op.success_example).to be_nil
    end
  end

  describe "#code_samples (x-codeSamples)" do
    subject(:samples) { doc.operation("getInvoice").code_samples }

    it "reads x-codeSamples into {lang, label, source} entries" do
      expect(samples.size).to eq(2)
      ruby = samples.find { |s| s[:lang] == "ruby" }
      expect(ruby[:label]).to eq("Ruby SDK")
      expect(ruby[:source]).to include("Billing::Invoice.retrieve")
    end

    it "is empty when the operation has no code samples" do
      expect(doc.operation("createInvoice").code_samples).to eq([])
    end

    it "reads the x-code-samples (hyphenated) spelling too" do
      op = build_operation({ "x-code-samples" => [{ "lang" => "shell", "source" => "curl /x" }] })

      expect(op.code_samples.first[:source]).to eq("curl /x")
    end
  end
end
