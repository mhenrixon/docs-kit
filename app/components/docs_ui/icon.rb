# frozen_string_literal: true

module DocsUI
  # Renders a synced lucide icon as inline SVG via rails_icons. Thin Phlex wrapper.
  #
  #   render DocsUI::Icon.new("search", class: "size-4")
  #
  # A missing icon name falls back to a question-mark glyph outside development,
  # rather than raising, so a typo never takes down a docs page in production.
  class Icon < Phlex::HTML
    MISSING_ICON = "circle-question-mark"

    def initialize(name, **attributes)
      @name = name
      @attributes = attributes
    end

    def view_template
      # rails_icons is a Railtie gem; outside a Rails host (e.g. isolated Phlex
      # unit tests) it isn't loaded. Render nothing rather than raise — in a real
      # docs app rails_icons is always present, so this only no-ops in tests.
      return unless defined?(::Icons::Icon)

      raw(safe(svg_for(@name, **@attributes)))
    end

    private

    def svg_for(name, **arguments)
      ::Icons::Icon.new(
        name: name.to_s.dasherize,
        library: rails_icons_library,
        variant: nil,
        arguments: arguments
      ).svg
    rescue ::Icons::IconNotFound
      raise if local_env?

      ::Icons::Icon.new(name: MISSING_ICON, library: rails_icons_library, variant: nil, arguments: arguments).svg
    end

    def rails_icons_library
      ::RailsIcons.configuration.default_library
    end

    def local_env?
      defined?(Rails) && Rails.env.local?
    end
  end
end
