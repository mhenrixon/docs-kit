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
    attr_accessor :nav

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

    # Namespaces the sidebar's localStorage keys (collapse state) so two docs
    # sites on the same origin don't clobber each other. Defaults to a slug of
    # the brand.
    attr_writer :nav_storage_key

    def initialize
      @brand = "Docs"
      @title_suffix = nil
      @themes = %w[dark light]
      @default_theme = nil
      @nav = -> { {} }
      @version_badge = nil
      @stylesheets = %w[application]
      @code_theme = "Rouge::Themes::Monokai"
      @default_group_icon = "file-text"
      @nav_storage_key = nil
    end

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
    def nav_groups
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
