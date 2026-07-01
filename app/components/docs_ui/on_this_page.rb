# frozen_string_literal: true

module DocsUI
  # An "On this page" table of contents that auto-collects the current page's
  # <h2>/<h3> and highlights the section you're reading (scroll-spy). It ships
  # EMPTY — the docs-nav Stimulus controller fills it from the DOM, so a page gets
  # a live, self-maintaining TOC with zero server-side knowledge of its headings.
  #
  # Three placements, same data, chosen by `mode:` (see
  # DocsKit::Configuration::ON_PAGE_MODES):
  #
  #   :panel   — a fixed card pinned to the top-right of the viewport (below the
  #              topbar). On wide screens it's always visible; on narrower screens
  #              it collapses to a floating toggle button (docs-nav#toggleToc).
  #   :toggle  — always the floating toggle button + dropdown (top-right).
  #   :sidebar — a slot the controller fills under the active left-nav item.
  #
  # The controller hides the whole thing when the page has too few headings, so
  # short pages show nothing (data-docs-nav-target="tocRoot" + auto-hide).
  #
  #   render DocsUI::OnThisPage.new(mode: :panel)
  class OnThisPage < Phlex::HTML
    def initialize(mode: :panel, title: "On this page")
      @mode = mode
      @title = title
    end

    def view_template
      case @mode
      when :toggle then toggle_only
      when :sidebar then nil # the controller injects under the active nav item; no content slot
      else panel
      end
    end

    private

    # The empty list the controller fills. `tocRoot` is what auto-hides on short
    # pages; the docs-nav controller populates the inner list.
    def toc_list(**attrs)
      nav(**mix({ aria_label: @title, data: { docs_nav_target: "toc" } }, attrs)) do
        heading
      end
    end

    def heading
      div(class: "mb-2 text-xs font-semibold uppercase tracking-wider text-base-content/60") { @title }
    end

    # :panel — a card fixed to the top-right of the viewport, just below the
    # sticky topbar. Solid bg-base-300 with a border + shadow so it stands out and
    # stays out of the way (it never overlaps the prose). On < xl it's hidden and
    # the compact toggle button takes over instead.
    #
    # data-docs-nav-target="tocRoot" wraps BOTH the card and the toggle so the
    # controller hides the whole feature at once on short pages.
    def panel
      div(class: "not-prose", data: { docs_nav_target: "tocRoot" }) do
        # Wide screens: the always-visible card.
        toc_list(
          class: "hidden xl:block fixed right-4 top-20 z-20 max-h-[70vh] w-64 overflow-y-auto " \
                 "rounded-box border border-base-300 bg-base-300 p-4 text-sm shadow-xl"
        )
        # Narrower screens: a floating toggle button that reveals the same card.
        floating_toggle(hide_on_xl: true)
      end
    end

    # :toggle — always the floating toggle button (no always-visible card).
    def toggle_only
      div(class: "not-prose", data: { docs_nav_target: "tocRoot" }) do
        floating_toggle(hide_on_xl: false)
      end
    end

    # A floating button pinned top-right that toggles a popover TOC card.
    # hide_on_xl: true for :panel (hide the button at xl+, where the always-open
    # card shows instead); false for :toggle (always show the button). The
    # `xl:hidden` class is written as a LITERAL (never interpolated) so Tailwind's
    # scanner keeps it — a computed "#{bp}:hidden" would be tree-shaken away.
    def floating_toggle(hide_on_xl:)
      wrapper = "fixed right-4 top-20 z-20"
      wrapper += " xl:hidden" if hide_on_xl

      div(class: wrapper, data: { docs_nav_target: "tocToggleWrap" }) do
        button(
          type: "button",
          class: "btn btn-sm gap-1 border border-base-300 bg-base-300 shadow-lg",
          aria_label: @title,
          data: { action: "docs-nav#toggleToc", docs_nav_target: "tocToggleBtn" }
        ) do
          render DocsUI::Icon.new("list", class: "size-4")
          span(class: "hidden sm:inline") { @title }
        end
        # The popover card, hidden until toggled.
        toc_list(
          class: "hidden mt-2 max-h-[70vh] w-64 overflow-y-auto rounded-box " \
                 "border border-base-300 bg-base-300 p-4 text-sm shadow-xl",
          data: { docs_nav_target: "tocPopover" }
        )
      end
    end
  end
end
