# frozen_string_literal: true

module Docs
  # An "On this page" table of contents that lights up the section you're reading.
  # It ships EMPTY: the docs-nav Stimulus controller fills it from the current
  # page's <h2>/<h3> ids and highlights the active one via scroll-spy, so a page
  # gets a live TOC with no server-side knowledge of its own headings.
  #
  # Render it inside the sidebar's docs-nav controller scope (Docs::Sidebar owns
  # the controller), or anywhere within an element that has
  # data-controller="docs-nav". With JS off it renders nothing visible.
  #
  #   render Docs::OnThisPage.new            # sticky aside on wide layouts
  class OnThisPage < Phlex::HTML
    def initialize(title: "On this page")
      @title = title
    end

    def view_template
      nav(
        class: "not-prose text-sm",
        aria_label: @title,
        data: { docs_nav_target: "toc" }
      ) do
        # The controller replaces this with the generated list; until then (and
        # with JS off) it's empty, so nothing renders. A heading is added here so
        # a populated TOC has a label.
        div(class: "mb-2 px-3 text-xs font-semibold uppercase tracking-wider text-base-content/50") { @title }
      end
    end
  end
end
