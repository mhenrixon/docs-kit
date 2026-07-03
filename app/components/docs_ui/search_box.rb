# frozen_string_literal: true

module DocsUI
  # The topbar docs-search affordance: a plain GET form to config.search_path (the
  # JS-off path — Enter lands on the server-rendered results page) that the ONE
  # docs-nav controller enhances into a Cmd+K palette. The palette results
  # dropdown is server-rendered here EMPTY and hidden; docs-nav fills it from
  # `search.json?q=` as the reader types and toggles it. The form still submits
  # normally if JS dies mid-typing, so search never depends on JavaScript.
  #
  # Rendered by DocsUI::Shell only when DocsKit.configuration.search_enabled?.
  #
  # The dropdown/menu/hidden classes are render-time LITERALS (never
  # interpolated), so Tailwind's scan of this file keeps them; the CSS also
  # @source inline()s them belt-and-suspenders, since they only appear at render
  # time (like the Drawer classes).
  class SearchBox < Phlex::HTML
    def view_template
      # data-docs-nav-target="searchScope" roots the palette so docs-nav#openSearch
      # (/ or Cmd+K) can focus the input, and the results dropdown is a sibling.
      div(class: "dropdown flex-none", data: { docs_nav_target: "searchScope" }) do
        form(
          action: config.search_path, method: "get", role: "search",
          class: "flex items-center", data: { action: "submit->docs-nav#submitSearch" }
        ) do
          label(class: "input input-sm flex items-center gap-2") do
            render DocsUI::Icon.new("search", class: "size-4 opacity-60")
            search_input
          end
        end
        results_dropdown
      end
    end

    private

    def config = DocsKit.configuration

    def search_input
      input(
        type: "search", name: "q", placeholder: "Search…", autocomplete: "off",
        aria_label: "Search docs", class: "grow bg-transparent",
        data: {
          docs_nav_target: "searchInput",
          action: "input->docs-nav#performSearch keydown->docs-nav#navigateResults"
        }
      )
    end

    # The palette results list — server-rendered EMPTY + hidden; docs-nav fills it.
    def results_dropdown
      ul(
        class: "dropdown-content menu bg-base-200 rounded-box z-40 mt-1 hidden max-h-96 " \
               "w-80 flex-nowrap overflow-y-auto p-2 shadow-2xl",
        data: { docs_nav_target: "searchResults" }
      )
    end
  end
end
