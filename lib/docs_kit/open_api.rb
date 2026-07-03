# frozen_string_literal: true

require "yaml"
require "json"
require "pathname"

module DocsKit
  # The OpenAPI-bridge entry point. Loads an OpenAPI 3.x spec (a file path or an
  # already-parsed Hash) into a narrow, gem-owned object model — a
  # DocsKit::OpenApi::Document yielding DocsKit::OpenApi::Operation objects — that
  # exposes ONLY what the existing render targets consume (FieldTable rows,
  # ErrorTable rows, example bodies, code samples). No runtime parser dependency:
  # YAML via Psych, JSON via the stdlib.
  #
  #   doc = DocsKit::OpenApi.load("openapi.yaml")
  #   op  = doc.operation("createInvoice")   # or doc.operation(:post, "/v1/invoices")
  #   op.body_rows      # => [{ name:, type:, required:, description: }, ...]  (FieldTable)
  #   op.error_rows     # => [{ scenario:, status:, type: }, ...]             (ErrorTable)
  #   op.success_example# => a Hash → JsonResponse
  #
  # DocsUI::OpenApiOperation renders one Operation through the kit; the `operation`
  # page helper looks it up on DocsKit.configuration.openapi_document.
  module OpenApi
    # Raised when a requested operation isn't in the spec. The message lists the
    # available operationIds so a typo is diagnosable at the call site.
    class OperationNotFound < DocsKit::Error; end

    # Raised on a $ref this bridge intentionally doesn't resolve — an external or
    # remote reference (anything not starting "#/"). The message names the ref.
    class UnsupportedRef < DocsKit::Error; end

    # YAML types a real-world spec might legitimately carry (dates in examples).
    PERMITTED_YAML_CLASSES = [Date, Time].freeze

    module_function

    # Load a spec from a String/Pathname path (`.json` parsed as JSON, anything
    # else as YAML) or from an already-parsed Hash. Returns a Document.
    def load(source)
      Document.new(source.is_a?(Hash) ? source : parse_file(source))
    end

    # Parse a file by extension: JSON for `.json`, YAML (with alias support)
    # otherwise. Kept module-level so Document#load-style reloads share it.
    def parse_file(path)
      pathname = Pathname.new(path)
      contents = pathname.read
      if pathname.extname.casecmp?(".json")
        JSON.parse(contents)
      else
        YAML.safe_load(contents, aliases: true, permitted_classes: PERMITTED_YAML_CLASSES)
      end
    end
  end
end
