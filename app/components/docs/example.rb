# frozen_string_literal: true

module Docs
  # Base class for one component/demo example. A subclass renders a live component
  # (daisyUI and/or reactive) in #example; a viewer shows that live render in a
  # Preview tab and the extracted #example source in a Source tab, so the shown
  # code and the running component never drift.
  #
  #   class Views::Components::Examples::Button::Colors < Docs::Example
  #     include DaisyUI
  #     title "Buttons with colors"
  #     def example
  #       Button(:primary) { "Primary" }
  #     end
  #   end
  #
  # #example_source requires the `method_source` gem (a host docs-app dependency);
  # it is loaded lazily so the kit doesn't hard-depend on it.
  class Example < Phlex::HTML
    class << self
      # The heading shown above this example. Defaults to a humanized version of
      # the class's last name segment.
      def title(value = nil)
        @title = value if value
        @title || humanized_name
      end

      # Sort key for ordering examples on a page (lower first). Defaults to 100 so
      # unordered examples fall after explicitly-ordered ones.
      def order(value = nil)
        @order = value if value
        @order || 100
      end

      private

      def humanized_name
        last = name.to_s.split("::").last.to_s
        if last.respond_to?(:underscore)
          last.underscore.humanize
        else
          last.gsub(/([a-z\d])([A-Z])/, '\1 \2').tr("_", " ")
        end
      end
    end

    # Override with the live component render(s) to demonstrate.
    def example
      raise NotImplementedError, "#{self.class} must implement #example"
    end

    # The Ruby source of #example, extracted via method_source — the exact lines a
    # host app would write. Strips the `def example` / final `end` wrapper and
    # re-dedents to the least-indented body line.
    def example_source
      require "method_source"
      body = method(:example).source.lines[1..-2] || []
      dedent(body).join.strip
    end

    # Rendered live inside a Preview tab.
    def view_template
      example
    end

    private

    def dedent(lines)
      indents = lines.reject { |l| l.strip.empty? }.map { |l| l[/\A */].length }
      margin = indents.min || 0
      lines.map { |l| l.strip.empty? ? l : l[margin..] }
    end
  end
end
