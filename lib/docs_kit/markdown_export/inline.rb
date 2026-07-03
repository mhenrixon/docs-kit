# frozen_string_literal: true

module DocsKit
  class MarkdownExport
    # The inline pass: a node's descendants flattened to a single run of Markdown
    # text (bold/italic/code/links). Block elements never reach here; an unknown
    # inline element recurses into its children so its text survives.
    class Inline
      # Emphasis tags whose Markdown just wraps the inner text in a delimiter.
      # Keeps #render_node a flat dispatch instead of a branch per tag.
      WRAP = {
        "strong" => "**", "b" => "**",
        "em" => "*", "i" => "*",
        "del" => "~~", "s" => "~~"
      }.freeze

      def initialize(export)
        @export = export
      end

      # Inline-render a node OR a Nokogiri node-set (an <li>'s inline children).
      def render(node_or_set)
        nodes = node_or_set.respond_to?(:children) ? node_or_set.children : node_or_set
        nodes.map { |child| render_node(child) }.join
      end

      # Dispatch one node. Text is returned verbatim (Nokogiri decoded entities,
      # so `<`/`&` are literal — GFM keeps them). Elements map to their inline
      # Markdown; the DocsUI::Section hover-anchor "#" span is dropped.
      def render_node(node)
        return node.text if node.text?
        return "" unless node.element?

        name = node.name
        wrap = WRAP[name]
        return "#{wrap}#{render(node)}#{wrap}" if wrap

        element(node, name)
      end

      # The non-emphasis inline elements. `code` keeps its text verbatim; `a`
      # becomes a link; a decorative "#" span (Section's hover anchor) is dropped;
      # any other wrapper recurses so its text survives.
      def element(node, name)
        case name
        when "code" then code_span(node.text)
        when "a" then link(node)
        when "img" then image(node)
        when "br" then "  \n"
        when "span" then anchor_decoration?(node) ? "" : render(node)
        else render(node)
        end
      end

      def image(node)
        "![#{node['alt']}](#{@export.absolutize(node['src'])})"
      end

      # A heading's inline text, treating a self-referencing anchor (href="#id",
      # DocsUI::Section's deep-link wrapper) as transparent — its children render
      # directly, so a heading is `## Title`, never `## [Title](#id)`.
      def heading_text(node)
        node.children.map do |child|
          self_anchor?(child) ? render(child) : render_node(child)
        end.join.strip
      end

      private

      # A GFM-correct inline code span. The fence is a backtick run one longer
      # than the longest run inside the text, so an interior backtick can never
      # close the span; a space pads content that starts or ends with a backtick.
      def code_span(text)
        fence = "`" * ((text.scan(/`+/).map(&:length).max || 0) + 1)
        pad = text.start_with?("`") || text.end_with?("`") ? " " : ""
        "#{fence}#{pad}#{text}#{pad}#{fence}"
      end

      def self_anchor?(node)
        node.element? && node.name == "a" && node["href"].to_s.start_with?("#")
      end

      def link(node)
        "[#{render(node)}](#{@export.absolutize(node['href'])})"
      end

      # DocsUI::Section renders a decorative "#" span (a hover deep-link glyph)
      # inside its heading anchor. It's chrome, not content — drop it so a heading
      # doesn't export as "Title #".
      def anchor_decoration?(node)
        node.text.strip == "#" && node.parent&.name == "a"
      end
    end
  end
end
