# frozen_string_literal: true

module Views
  module Landings
    # The home page — a marketing hero + feature grid + doc index, all from
    # `c.landing` config (see config/initializers/docs_kit.rb). Renders the shared
    # DocsUI::Landing component, so this site no longer hand-rolls a landing.
    class Show < Phlex::HTML
      def view_template
        render DocsUI::Landing.new
      end
    end
  end
end
