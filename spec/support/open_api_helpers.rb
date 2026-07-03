# frozen_string_literal: true

# Helpers for the DocsKit::OpenApi specs: build a Document around a single
# operation from a compact Hash, so an example asserting one edge case doesn't
# carry a 20-line inline spec (RSpec/ExampleLength).
module OpenApiHelpers
  # A Document whose only path (`path`, default "/x") + verb (`method`, default
  # get) is the passed operation Hash. Returns the Document.
  def build_document(operation, path: "/x", method: "get")
    DocsKit::OpenApi.load(
      "openapi" => "3.0.3",
      "paths" => { path => { method.to_s => operation } }
    )
  end

  # The single Operation from #build_document.
  def build_operation(operation, path: "/x", method: "get")
    build_document(operation, path: path, method: method).operations.first
  end
end

RSpec.configure { |c| c.include OpenApiHelpers }
