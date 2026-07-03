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
            shortcut_hint
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

    # The keyboard-shortcut hint the reader SEES — two <kbd> badges:
    #   Ctrl K / ⌘K  — focus search (docs-nav refines the modifier to the OS)
    #   /            — always works; no browser hijacks "/"
    #
    # Server-rendered with a sensible default (the majority "Ctrl K") so the hint
    # is correct and honest with JS off; docs-nav#refreshShortcutHint only swaps
    # the modifier label to ⌘K on mac — it never changes the key BINDING. Both
    # keys work in every current browser (Cmd/Ctrl+K is a cancellable accelerator,
    # not a reserved shortcut), and "/" carries the reader through any residual
    # edge. aria-hidden: the badges are decorative — the input has aria-label.
    #
    # The class strings are render-time LITERALS so Tailwind's file scan keeps
    # them (kbd/kbd-sm are also @source inline'd in the CSS, belt-and-suspenders).
    def shortcut_hint
      span(class: "ml-1 hidden items-center gap-1 sm:flex", aria_hidden: "true") do
        kbd(class: "kbd kbd-sm opacity-60",
            data: { docs_nav_target: "shortcutHint", hint: "modifier" }) { "Ctrl K" }
        kbd(class: "kbd kbd-sm opacity-60",
            data: { docs_nav_target: "shortcutHint", hint: "slash" }) { "/" }
      end
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
