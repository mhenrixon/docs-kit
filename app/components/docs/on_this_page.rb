# frozen_string_literal: true

module Docs
  # An "On this page" table of contents that auto-collects the current page's
  # <h2>/<h3> and highlights the section you're reading (scroll-spy). It ships
  # EMPTY — the docs-nav Stimulus controller fills it from the DOM, so a page gets
  # a live, self-maintaining TOC with zero server-side knowledge of its headings.
  #
  # Three placements, same data, chosen by `mode:` (see
  # DocsKit::Configuration::ON_PAGE_MODES):
  #
  #   :panel   — a sticky card floating in the top-right of the content column
  #   :toggle  — a sticky floating button (top-right) that opens a dropdown
  #   :sidebar — a slot the controller fills under the active left-nav item
  #
  # The controller hides the whole thing when the page has too few headings, so
  # short pages show nothing (data-docs-nav-target="tocRoot" + auto-hide).
  #
  #   render Docs::OnThisPage.new(mode: :panel)
  class OnThisPage < Phlex::HTML
    def initialize(mode: :panel, title: "On this page")
      @mode = mode
      @title = title
    end

    def view_template
      case @mode
      when :toggle then toggle
      when :sidebar then nil # the controller injects under the active nav item; no content slot
      else panel
      end
    end

    private

    # Common: the empty list the controller fills. `tocRoot` is what auto-hides.
    def toc_target(**attrs)
      nav(**mix({ aria_label: @title, data: { docs_nav_target: "toc tocRoot" } }, attrs))
    end

    def heading
      div(class: "mb-2 px-3 text-xs font-semibold uppercase tracking-wider text-base-content/50") { @title }
    end

    # :panel — a sticky card in the top-right of the content column. Hidden on
    # narrow screens (where :toggle would be used); the content stays full-width.
    def panel
      toc_target(
        class: "not-prose hidden xl:block absolute right-0 top-0 w-56 " \
               "sticky-toc rounded-box border border-base-300 bg-base-200/60 p-3 text-sm"
      ) do
        heading
      end
    end

    # :toggle — a sticky floating button that opens a daisyUI dropdown. Zero extra
    # JS for the open/close (daisyUI dropdown); the controller only fills the list.
    def toggle
      div(class: "not-prose dropdown dropdown-end sticky-toc absolute right-0 top-0") do
        div(tabindex: "0", role: "button",
            class: "btn btn-sm btn-ghost gap-1", aria_label: @title) do
          render Docs::Icon.new("list", class: "size-4")
          plain @title
        end
        toc_target(
          tabindex: "0",
          class: "dropdown-content z-10 mt-2 w-64 rounded-box border border-base-300 " \
                 "bg-base-200 p-3 shadow-2xl"
        )
      end
    end
  end
end
