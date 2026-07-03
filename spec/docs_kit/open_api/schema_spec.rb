# frozen_string_literal: true

# Focused coverage for DocsKit::OpenApi::Schema branches the endpoint-level
# fixture doesn't exercise: oneOf/anyOf type labels and type-placeholder example
# synthesis (integer/number/boolean/string with no explicit example).
RSpec.describe DocsKit::OpenApi::Schema do
  # A bare Document is enough — these schemas carry no $refs.
  let(:document) { DocsKit::OpenApi.load("openapi" => "3.0.3", "paths" => {}) }

  def schema(node) = described_class.new(document, node)

  describe "#type_label" do
    it "labels a oneOf as 'one of: A | B'" do
      node = { "oneOf" => [{ "type" => "string" }, { "type" => "integer" }] }

      expect(schema(node).type_label).to eq("one of: string | integer")
    end

    it "labels an anyOf the same way" do
      node = { "anyOf" => [{ "type" => "boolean" }, { "type" => "string" }] }

      expect(schema(node).type_label).to eq("one of: boolean | string")
    end
  end

  describe "#example_value (type placeholders, no explicit example)" do
    it "synthesizes 0 for an integer" do
      expect(schema("type" => "integer").example_value).to eq(0)
    end

    it "synthesizes 0 for a number" do
      expect(schema("type" => "number").example_value).to eq(0)
    end

    it "synthesizes true for a boolean" do
      expect(schema("type" => "boolean").example_value).to be(true)
    end

    it "synthesizes 'string' for a string" do
      expect(schema("type" => "string").example_value).to eq("string")
    end

    it "synthesizes a placeholder object from properties" do
      node = { "type" => "object", "properties" => { "n" => { "type" => "integer" }, "s" => { "type" => "string" } } }

      expect(schema(node).example_value).to eq("n" => 0, "s" => "string")
    end
  end
end
