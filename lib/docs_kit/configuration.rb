# frozen_string_literal: true

module DocsKit
  # Per-site configuration for the shared docs chrome. Everything that differs
  # between two otherwise-identical docs sites lives here, so the Phlex shell
  # (Docs::Shell, Docs::Sidebar, Docs::ThemeSwitcher) is byte-identical across
  # sites and only the config changes.
  #
  #   DocsKit.configure do |c|
  #     c.brand        = "phlex-reactive"
  #     c.title_suffix = "phlex-reactive"
  #     c.themes       = %w[dark light synthwave ...]
  #     c.nav          = -> { { "Demos" => Demo.grouped, "Docs" => Doc.grouped } }
  #   end
  class Configuration
    # The brand text shown in the topbar and sidebar header.
    attr_accessor :brand

    # Appended to a page's <title> (e.g. "Installation · phlex-reactive").
    # Defaults to #brand when unset.
    attr_writer :title_suffix

    # The themes offered by the ThemeSwitcher. The first is the page default
    # unless #default_theme is set. Must match the themes enabled in the
    # site's Tailwind @plugin "daisyui" { themes: ... } block.
    attr_accessor :themes

    # The data-theme applied to <html> on first paint. Defaults to the first
    # entry of #themes.
    attr_writer :default_theme

    # A callable returning the sidebar nav as an ordered Hash of
    # { "Heading" => { "Subgroup" => [items] } }. Each item must respond to
    # the duck type the Sidebar renders (see Docs::Sidebar#nav_link): #href,
    # #label, and optional #icon. Defaults to an empty nav.
    #
    # Prefer #nav_registries for the common case — an explicit #nav lambda is
    # only needed for bespoke nav (multiple registries interleaved, custom
    # subgroups). When #nav is left at its default, the sidebar derives from
    # #nav_registries instead.
    attr_accessor :nav

    # An ordered { "Heading" => registry_class } map. Each registry responds to
    # .nav_items (Registry v2) → { group => [NavItem] } for its authored pages.
    # #nav_groups derives the whole sidebar from this with zero site code, so a
    # site never hand-writes the nav lambda. Defaults to {}. An explicit #nav
    # lambda still wins (full backwards compatibility).
    attr_accessor :nav_registries

    # Optional callable returning a short version-badge string for the sidebar
    # header (e.g. -> { "v#{DaisyUI::VERSION}" }). nil renders no badge.
    attr_accessor :version_badge

    # The stylesheet logical names linked in <head>, in order. Defaults to
    # ["application"] (the Bun/Tailwind-compiled build). A site that ships extra
    # stylesheets (e.g. a separate rouge theme) lists them here.
    attr_accessor :stylesheets

    # The Rouge theme class used by Docs::Code for inline syntax-highlight CSS.
    attr_accessor :code_theme

    # The lucide icon name used for a nav group with no explicit icon.
    attr_accessor :default_group_icon

    # The RailsIcons library docs-kit renders its OWN chrome icons from (the
    # sidebar carets, search glyph, theme toggle, etc.). Defaults to "lucide" to
    # match the lucide icon names docs-kit ships. This is independent of the host
    # app's RailsIcons.configuration.default_library — a host whose default is
    # phosphor/heroicons can leave this at "lucide" so the chrome keeps rendering,
    # without flipping its global default. Set to nil to defer to the host's
    # default_library.
    attr_accessor :icon_library

    # Namespaces the sidebar's localStorage keys (collapse state) so two docs
    # sites on the same origin don't clobber each other. Defaults to a slug of
    # the brand.
    attr_writer :nav_storage_key

    # The default "On this page" (auto-TOC) placement, used by Docs::Page when a
    # page doesn't pass its own on_page:. One of the ON_PAGE_MODES, or false to
    # render no auto-TOC by default.
    attr_writer :on_page_default

    # Friendly-name → Rouge lexer aliases for code blocks, merged over the
    # built-in defaults. Any language Rouge knows (~200) already works by its own
    # name/alias; use this only to add or override (e.g. { curl: "console",
    # dockerfile: "docker" }). Value is anything Rouge::Lexer.find accepts.
    attr_accessor :code_lexer_aliases

    # The lexer used when a requested language can't be resolved. Default
    # "plaintext" (no highlighting, never raises).
    attr_accessor :code_lexer_fallback

    # Human labels for language tabs in Docs::Example, merged over the built-ins
    # (e.g. { elixir: "Elixir", curl: "cURL" }). Unknown tokens humanize.
    attr_accessor :code_language_labels

    # The sentinel "no explicit nav" lambda. #nav_groups compares against this
    # identity to decide whether to derive the sidebar from #nav_registries.
    DEFAULT_NAV = -> { {} }

    # Built-in friendly aliases (kept small — Rouge resolves most names itself).
    DEFAULT_LEXER_ALIASES = { curl: "console", console: "console" }.freeze

    # Built-in tab labels for the common languages that don't just capitalize.
    DEFAULT_LANGUAGE_LABELS = {
      javascript: "JavaScript", typescript: "TypeScript", php: "PHP",
      curl: "cURL", json: "JSON", yaml: "YAML", html: "HTML", css: "CSS",
      erb: "ERB", jsx: "JSX", tsx: "TSX", sql: "SQL", graphql: "GraphQL"
    }.freeze

    def initialize
      @brand = "Docs"
      @title_suffix = nil
      @themes = %w[dark light]
      @default_theme = nil
      # The sentinel default nav lambda. #nav_groups treats it as "unset" and
      # derives the sidebar from #nav_registries instead; an explicit c.nav
      # replaces this object so the derivation steps aside (backwards compat).
      @nav = DEFAULT_NAV
      @nav_registries = {}
      @version_badge = nil
      @stylesheets = %w[application]
      @code_theme = "Rouge::Themes::Monokai"
      @default_group_icon = "file-text"
      @icon_library = "lucide"
      @nav_storage_key = nil
      @on_page_default = :panel
      @code_lexer_aliases = {}
      @code_lexer_fallback = "plaintext"
      @code_language_labels = {}
    end

    # The effective alias map (built-ins + site overrides), symbol-keyed.
    def lexer_aliases
      DEFAULT_LEXER_ALIASES.merge((@code_lexer_aliases || {}).transform_keys(&:to_sym))
    end

    # The effective label map (built-ins + site overrides), symbol-keyed.
    def language_labels
      DEFAULT_LANGUAGE_LABELS.merge((@code_language_labels || {}).transform_keys(&:to_sym))
    end

    # The auto-TOC placements, all driven by the same docs-nav Stimulus
    # controller (it reads the page's headings from the DOM):
    #   :panel   — a sticky card in the top-right of the content column
    #   :toggle  — a sticky floating button (top-right) opening a dropdown
    #   :sidebar — nested under the active nav item in the left sidebar
    ON_PAGE_MODES = %i[panel toggle sidebar].freeze

    # The resolved default placement (a mode symbol or false). A bare `true`
    # default means :panel (the canonical default), never a self-reference.
    def on_page_default
      raw = @on_page_default
      raw = :panel if raw == true
      coerce_on_page_mode(raw)
    end

    # Coerce a per-page on_page: value to a valid mode symbol or false. `true`
    # means "use the configured default".
    def normalize_on_page(value)
      return on_page_default if value == true

      coerce_on_page_mode(value)
    end

    private

    # { heading => registry.nav_items }, dropping headings with no authored
    # pages so the sidebar never shows an empty group.
    def nav_groups_from_registries
      @nav_registries.each_with_object({}) do |(heading, registry), acc|
        items = registry.nav_items
        acc[heading] = items unless items.empty?
      end
    end

    def coerce_on_page_mode(value)
      case value
      when false, nil then false
      when *ON_PAGE_MODES then value.to_sym
      else
        raise ArgumentError,
              "on_page must be one of #{ON_PAGE_MODES.inspect}, true, or false (got #{value.inspect})"
      end
    end

    public

    def nav_storage_key
      @nav_storage_key || @brand.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
    end

    def title_suffix
      @title_suffix || @brand
    end

    def default_theme
      @default_theme || Array(@themes).first
    end

    # The resolved nav Hash for this request. Always returns a Hash.
    #
    # An explicit #nav lambda wins. Otherwise the sidebar derives from
    # #nav_registries: each heading maps to its registry's .nav_items, and a
    # heading whose pages are all unauthored (empty nav_items) is dropped so no
    # empty group renders.
    def nav_groups
      return nav_groups_from_registries if @nav.equal?(DEFAULT_NAV)

      result = @nav.respond_to?(:call) ? @nav.call : @nav
      result || {}
    end

    # The resolved version badge string, or nil.
    def version_badge_text
      return unless @version_badge.respond_to?(:call)

      @version_badge.call
    end

    # The Rouge theme class resolved from #code_theme (String or class).
    def code_theme_class
      return @code_theme if @code_theme.is_a?(Class)

      Object.const_get(@code_theme.to_s)
    end
  end
end
