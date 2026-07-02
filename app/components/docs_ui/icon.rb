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
      # rails_icons is a Railtie gem; outside a Rails host (isolated Phlex tests)
      # it isn't loaded, and in a not-yet-fully-set-up app its default library may
      # be unconfigured. Either way, render nothing rather than take down the page
      # — icons are chrome, not content. In development we still raise so a real
      # misconfiguration is visible.
      return unless defined?(::Icons::Icon) && rails_icons_library

      svg = svg_for(@name, **@attributes)
      raw(safe(svg)) if svg
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

      begin
        ::Icons::Icon.new(name: MISSING_ICON, library: rails_icons_library, variant: nil, arguments: arguments).svg
      rescue StandardError
        nil # even the fallback glyph isn't synced — render nothing.
      end
    rescue StandardError
      # Library misconfigured / icon set not synced. Surface it in dev; elsewhere
      # degrade to no icon rather than 500 the whole docs page.
      raise if local_env?

      nil
    end

    def rails_icons_library
      DocsKit.configuration.icon_library || ::RailsIcons.configuration.default_library
    rescue StandardError
      nil
    end

    def local_env?
      defined?(Rails) && Rails.env.local?
    end
  end
end
