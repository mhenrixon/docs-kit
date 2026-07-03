# frozen_string_literal: true

module DocsKit
  module OpenApi
    # A parsed OpenAPI 3.x document. Indexes every path/verb operation and offers
    # two lookups — by operationId, or by (method, path) for specs that omit ids —
    # plus the shared local-$ref resolver every Operation/Schema reads through.
    #
    # Keys stay Strings internally (that's how both YAML and JSON parse), so the
    # model never guesses at symbol/string key shape.
    class Document
      # The HTTP verbs an OpenAPI path item may carry, lower-cased as they appear
      # in the spec.
      HTTP_METHODS = %w[get put post delete options head patch trace].freeze

      def initialize(raw)
        @raw = raw
      end

      # Look up an operation. Two forms:
      #   operation("createInvoice")           — by operationId
      #   operation(:post, "/v1/invoices")     — by HTTP method + path
      # Raises OperationNotFound (naming the available ids) when nothing matches.
      def operation(id_or_method, path = nil)
        found = path.nil? ? by_operation_id(id_or_method) : by_method_and_path(id_or_method, path)
        found || raise(OperationNotFound, not_found_message(id_or_method, path))
      end

      # Every operation across every path, in document order.
      def operations
        @operations ||= build_operations
      end

      # Resolve a local $ref ("#/components/schemas/Foo") to the referenced node.
      # An external/remote ref (not starting "#/") raises UnsupportedRef. Used by
      # Operation and Schema so ref handling lives in exactly one place.
      def resolve_ref(ref)
        raise UnsupportedRef, "external/remote $ref is not supported: #{ref}" unless ref.start_with?("#/")

        ref.delete_prefix("#/").split("/").reduce(@raw) do |node, segment|
          # JSON Pointer escaping: ~1 → "/", ~0 → "~".
          key = segment.gsub("~1", "/").gsub("~0", "~")
          node.is_a?(Hash) ? node[key] : nil
        end
      end

      # Follow a node's $ref (if any) one hop to the referenced node; a node
      # without a $ref is returned unchanged.
      def deref(node)
        node.is_a?(Hash) && node.key?("$ref") ? resolve_ref(node["$ref"]) : node
      end

      private

      def build_operations
        paths.flat_map do |path, item|
          next [] unless item.is_a?(Hash)

          item.filter_map do |verb, op|
            next unless HTTP_METHODS.include?(verb.to_s.downcase)
            next unless op.is_a?(Hash)

            Operation.new(self, method: verb, path: path, raw: op)
          end
        end
      end

      def paths
        @raw["paths"] || {}
      end

      def by_operation_id(id)
        operations.find { |op| op.operation_id == id.to_s }
      end

      def by_method_and_path(method, path)
        verb = method.to_s.downcase
        operations.find { |op| op.http_method.downcase == verb && op.path == path }
      end

      def not_found_message(id_or_method, path)
        if path
          "no operation #{id_or_method.to_s.upcase} #{path} in the OpenAPI spec"
        else
          ids = operations.filter_map(&:operation_id)
          "unknown operationId #{id_or_method.inspect}; available: #{ids.join(', ')}"
        end
      end
    end
  end
end
