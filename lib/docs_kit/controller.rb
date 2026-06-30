# frozen_string_literal: true

module DocsKit
  # Controller glue for a docs site. Include in ApplicationController to get the
  # one shared render helper.
  #
  #   class ApplicationController < ActionController::Base
  #     include DocsKit::Controller
  #     def show = render_page(Views::Landings::Show.new)
  #   end
  module Controller
    # Render a Phlex page that is itself a full HTML document (it composes
    # Docs::Shell, which emits <html>/<head>/<body>). `layout: false` prevents the
    # Rails ERB application layout from double-nesting <html>. phlex-rails still
    # renders through a real view context, so CSRF, dom_id, url helpers, and the
    # phlex-reactive token signer all work inside components.
    def render_page(view)
      render view, layout: false
    end
  end
end
