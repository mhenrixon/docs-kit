# frozen_string_literal: true

module DocsUI
  # The topbar docs-search affordance: a plain GET form to config.search_path (the
  # JS-off path — Enter lands on the server-rendered results page) that the ONE
  # docs-nav controller enhances into a keyboard-shortcut palette. The shortcuts
  # come from config.search_shortcuts (default "/" and "mod+k"): this component
  # renders one <kbd> hint per shortcut AND emits the parsed list as JSON on the
  # scope, so the badges and the key bindings share one source and can't drift.
  # The results dropdown is server-rendered here EMPTY and hidden; docs-nav fills
  # it from `search.json?q=` as the reader types and toggles it. The form still
  # submits normally if JS dies mid-typing, so search never depends on JavaScript.
  #
  # Rendered by DocsUI::Shell only when DocsKit.configuration.search_enabled?.
  #
  # The dropdown/menu/hidden classes are render-time LITERALS (never
  # interpolated), so Tailwind's scan of this file keeps them; the CSS also
  # @source inline()s them belt-and-suspenders, since they only appear at render
  # time (like the Drawer classes).
  class SearchBox < Phlex::HTML
    def view_template
      # data-docs-nav-target="searchScope" roots the palette so the shortcut keys
      # can focus the input, and the results dropdown is a sibling.
      # data-docs-nav-shortcuts-value carries the parsed shortcut list as JSON so
      # docs-nav binds each configured key without hardcoding any.
      div(
        class: "dropdown flex-none",
        data: { docs_nav_target: "searchScope", docs_nav_shortcuts_value: shortcuts_json }
      ) do
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

    # The configured shortcuts (DocsKit::Shortcut list) — drives both the visible
    # <kbd> badges and the JSON docs-nav binds against, so they can never drift.
    def shortcuts = config.search_shortcuts

    # The shortcut list as JSON for docs-nav's Value API (data-docs-nav-shortcuts-
    # value). Each entry is { key, mod, ctrl, shift, alt, meta } — everything the
    # controller needs to match a keydown without hardcoding any key.
    def shortcuts_json = shortcuts.map(&:to_h).to_json

    # The keyboard-shortcut hint the reader SEES — one <kbd> badge per configured
    # shortcut, rendered from DocsKit.configuration.search_shortcuts. A badge's
    # label is the parsed Shortcut#label ("/", "Ctrl K", "S", …); a mod-chord
    # badge is tagged data-hint=modifier so docs-nav swaps just its label to ⌘ on
    # mac — it never changes the key BINDING. Nothing renders when the site
    # configures no shortcuts. aria-hidden: the badges are decorative (the input
    # has aria-label).
    #
    # The class strings are render-time LITERALS so Tailwind's file scan keeps
    # them (kbd/kbd-sm are also @source inline'd in the CSS, belt-and-suspenders).
    def shortcut_hint
      return if shortcuts.empty?

      span(class: "ml-1 hidden items-center gap-1 sm:flex", aria_hidden: "true") do
        shortcuts.each { |shortcut| shortcut_badge(shortcut) }
      end
    end

    def shortcut_badge(shortcut)
      kbd(
        class: "kbd kbd-sm opacity-60",
        data: { docs_nav_target: "shortcutHint", hint: (shortcut.mod? ? "modifier" : "static") }
      ) { shortcut.label }
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
