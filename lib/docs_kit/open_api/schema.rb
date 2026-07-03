# frozen_string_literal: true

module DocsKit
  module OpenApi
    # A thin wrapper over one OpenAPI schema node that answers the three questions
    # the render targets ask: what's its display type label, what FieldTable rows
    # do its properties flatten to, and what example value does it synthesize.
    #
    # All traversal is cycle-safe (a $ref that loops back stops descending) and
    # depth-capped, because a real spec can be deeply nested or self-referential
    # (Invoice.parent → Invoice).
    class Schema
      # How deep object/property flattening and example synthesis descend before
      # stopping — guards both accidental depth and $ref cycles.
      MAX_DEPTH = 6

      def initialize(document, node)
        @document = document
        @node = node || {}
      end

      # A human display type for a FieldTable "Type" cell:
      #   "string", "integer", "array of string", "usd | eur | gbp" (enum),
      #   "one of: A | B" (oneOf/anyOf), "object".
      def type_label
        node = merged
        return enum_label(node["enum"]) if node["enum"]
        return one_of_label(node) if node["oneOf"] || node["anyOf"]
        return "array of #{Schema.new(@document, deref(node['items'])).type_label}" if array?(node)

        node["type"] || "object"
      end

      # The recursion state threaded through property flattening: the dotted-name
      # prefix, the current depth, and the $ref chain seen so far (for cycles).
      Cursor = Data.define(:prefix, :depth, :seen) do
        def self.root = new(prefix: "", depth: 0, seen: [])
        def descend(name, ref) = self.class.new(prefix: name, depth: depth + 1, seen: seen + [ref].compact)
        def dotted(name) = prefix.empty? ? name : "#{prefix}.#{name}"
      end

      # Flatten this schema's properties into FieldTable-ready rows. Nested object
      # properties dot their names (customer.id); required is read from the
      # object's `required` list. The Cursor threads prefix/depth/seen recursion.
      def rows(cursor: Cursor.root)
        node = merged
        return [] if cursor.depth >= MAX_DEPTH
        return [] unless node["properties"].is_a?(Hash)

        required = Array(node["required"])
        node["properties"].flat_map do |name, prop_node|
          property_rows(prop_node, name: name, required: required.include?(name), cursor: cursor)
        end
      end

      # Synthesize an example value for this schema: the node's own `example`,
      # else `default`, else the first enum value, else a per-type placeholder
      # (recursing into object properties / array items). Cycle-safe via `seen`.
      def example_value(depth: 0, seen: [])
        node = merged
        return node["example"] if node.key?("example")
        return node["default"] if node.key?("default")
        return node["enum"].first if node["enum"].is_a?(Array) && !node["enum"].empty?
        return [] if depth >= MAX_DEPTH

        synthesize(node, depth, seen)
      end

      private

      attr_reader :document

      # The node with any single $ref followed and allOf branches shallow-merged,
      # so callers see one flat schema. oneOf/anyOf are left for #type_label.
      def merged
        node = deref(@node)
        return {} unless node.is_a?(Hash)
        return merge_all_of(node) if node["allOf"].is_a?(Array)

        node
      end

      def merge_all_of(node)
        node["allOf"].each_with_object(node.except("allOf")) do |branch, acc|
          merge_branch!(acc, Schema.new(@document, branch).send(:merged))
        end
      end

      def merge_branch!(acc, resolved)
        acc["properties"] = (acc["properties"] || {}).merge(resolved["properties"] || {})
        acc["required"] = Array(acc["required"]) | Array(resolved["required"])
        acc["type"] ||= resolved["type"]
      end

      def property_rows(prop_node, name:, required:, cursor:)
        dotted = cursor.dotted(name)
        resolved = deref(prop_node)
        ref = prop_node.is_a?(Hash) ? prop_node["$ref"] : nil
        own_row = row(dotted, prop_node, required)

        # A $ref cycle, or a leaf: emit the row without descending.
        return [own_row] if (ref && cursor.seen.include?(ref)) || !object_with_properties?(resolved)

        child = Schema.new(@document, resolved).rows(cursor: cursor.descend(dotted, ref))
        [own_row, *child]
      end

      def row(name, prop_node, required)
        schema = Schema.new(@document, prop_node)
        {
          name: name,
          type: schema.type_label,
          required: required,
          description: description_cell(deref(prop_node))
        }
      end

      # An OpenAPI description is CommonMark, so hand it to FieldTable as an inline
      # Markdown cell ([:md, ...]); a description-less property gets no cell (the
      # component falls back to the em-dash).
      def description_cell(node)
        desc = node.is_a?(Hash) ? node["description"] : nil
        desc && !desc.to_s.strip.empty? ? [:md, desc.to_s] : nil
      end

      def synthesize(node, depth, seen)
        # A typeless node with properties is an implicit object.
        return synthesize_object(node, depth, seen) if node["type"] == "object" || node["properties"]

        case node["type"]
        when "array" then [synthesize_array_item(node, depth, seen)]
        when "integer", "number" then 0
        when "boolean" then true
        else "string"
        end
      end

      def synthesize_array_item(node, depth, seen)
        Schema.new(@document, deref(node["items"])).example_value(depth: depth + 1, seen: seen)
      end

      def synthesize_object(node, depth, seen)
        props = node["properties"]
        return {} unless props.is_a?(Hash)

        props.each_with_object({}) do |(name, prop_node), acc|
          ref = prop_node.is_a?(Hash) ? prop_node["$ref"] : nil
          next if ref && seen.include?(ref) # cycle: drop the looping property

          acc[name] = Schema.new(@document, prop_node)
                            .example_value(depth: depth + 1, seen: seen + [ref].compact)
        end
      end

      def array?(node)
        node["type"] == "array" || node.key?("items")
      end

      def object_with_properties?(node)
        node.is_a?(Hash) && node["properties"].is_a?(Hash)
      end

      def enum_label(values)
        Array(values).join(" | ")
      end

      def one_of_label(node)
        branches = node["oneOf"] || node["anyOf"]
        labels = branches.map { |b| Schema.new(@document, b).type_label }
        "one of: #{labels.join(' | ')}"
      end

      def deref(node)
        @document.deref(node)
      end
    end
  end
end
