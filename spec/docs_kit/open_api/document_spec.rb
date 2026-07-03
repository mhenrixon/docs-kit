# frozen_string_literal: true

RSpec.describe DocsKit::OpenApi::Document do
  let(:yaml_path) { File.expand_path("../../fixtures/openapi.yaml", __dir__) }
  let(:json_path) { File.expand_path("../../fixtures/openapi.json", __dir__) }

  describe ".load / DocsKit::OpenApi.load" do
    it "loads from a YAML file path" do
      doc = DocsKit::OpenApi.load(yaml_path)

      expect(doc).to be_a(described_class)
      expect(doc.operation("createInvoice").summary).to eq("Create an invoice")
    end

    it "loads from a JSON file path" do
      doc = DocsKit::OpenApi.load(json_path)

      expect(doc.operation("createInvoice").summary).to eq("Create an invoice")
    end

    it "loads from a Pathname" do
      doc = DocsKit::OpenApi.load(Pathname.new(yaml_path))

      expect(doc.operation("listInvoices").summary).to eq("List invoices")
    end

    it "loads from an already-parsed Hash (string keys)" do
      hash = YAML.safe_load_file(yaml_path, aliases: true, permitted_classes: [Date, Time])
      doc = DocsKit::OpenApi.load(hash)

      expect(doc.operation("createInvoice").summary).to eq("Create an invoice")
    end

    it "resolves YAML anchors/aliases (the shared 401 response)" do
      doc = DocsKit::OpenApi.load(yaml_path)

      # createInvoice's 401 comes from the &unauthorized anchor merged via <<.
      errors = doc.operation("createInvoice").error_rows
      row = errors.find { |e| e[:status] == "401" }
      expect(row).not_to be_nil
      expect(row[:scenario]).to eq("Missing or invalid API key.")
    end
  end

  describe "#operation lookup" do
    subject(:doc) { DocsKit::OpenApi.load(yaml_path) }

    it "finds an operation by operationId" do
      expect(doc.operation("getInvoice").path).to eq("/v1/invoices/{id}")
    end

    it "finds an operation by (method, path) for a spec without an operationId" do
      op = doc.operation(:delete, "/v1/invoices/{id}")

      expect(op.summary).to eq("Delete an invoice")
      expect(op.http_method).to eq("DELETE")
    end

    it "is case-insensitive on the HTTP verb in a (method, path) lookup" do
      expect(doc.operation("GET", "/v1/invoices").operation_id).to eq("listInvoices")
    end

    it "raises OperationNotFound naming the available ids for an unknown operationId" do
      expect { doc.operation("noSuchOp") }
        .to raise_error(DocsKit::OpenApi::OperationNotFound, /createInvoice/)
    end

    it "raises OperationNotFound for a (method, path) that isn't in the spec" do
      expect { doc.operation(:get, "/nope") }
        .to raise_error(DocsKit::OpenApi::OperationNotFound)
    end
  end

  describe "#operations" do
    subject(:doc) { DocsKit::OpenApi.load(yaml_path) }

    it "enumerates every operation across every path (including the id-less one)" do
      ids = doc.operations.map(&:operation_id)

      expect(ids).to include("listInvoices", "createInvoice", "getInvoice")
      # Two paths × two verbs each (get/post, get/delete) = 4. The DELETE has no
      # operationId → its id is nil, but it's still enumerated.
      expect(doc.operations.size).to eq(4)
      expect(ids).to include(nil) # the id-less DELETE
    end
  end

  describe "$ref resolution" do
    subject(:doc) { DocsKit::OpenApi.load(yaml_path) }

    it "follows a local $ref into components/schemas for the request body" do
      rows = doc.operation("createInvoice").body_rows

      # CreateInvoiceRequest is allOf[Invoice, {idempotency_key}] → both merge in.
      names = rows.map { |r| r[:name] }
      expect(names).to include("amount", "currency", "idempotency_key")
    end

    it "does not infinitely recurse on a self-referential ($ref cycle) schema" do
      # Invoice.parent $refs back to Invoice; body_rows must terminate.
      expect { doc.operation("createInvoice").body_rows }.not_to raise_error
    end

    it "raises UnsupportedRef for an external/remote $ref" do
      external = { "$ref" => "external.yaml#/Foo" }
      op = build_operation(
        { "responses" => { "200" => { "description" => "ok",
                                      "content" => { "application/json" => { "schema" => external } } } } }
      )

      expect { op.success_example }
        .to raise_error(DocsKit::OpenApi::UnsupportedRef, /external\.yaml/)
    end
  end
end
