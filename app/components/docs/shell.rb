# frozen_string_literal: true

module Docs
  # The site shell — the full HTML document. A Phlex layout built on the daisyUI
  # Drawer: a sticky topbar, a sidebar always visible on desktop (lg:drawer-open)
  # that toggles as an overlay on mobile, and the page content in a scrollable
  # main. Loads Turbo + (when present) the phlex-reactive Stimulus controller via
  # the importmap tags, and the daisyUI-compiled Tailwind build.
  #
  # Shell IS the full <html> document, so controllers render the page view with
  # `layout: false` (see DocsKit::Controller#render_page) to avoid double <html>
  # nesting. phlex-rails still renders through a real view context, so CSRF,
  # dom_id, url helpers, and the reactive token signer all work inside components.
  #
  #   render Docs::Shell.new(title: "Installation") { page_body }
  class Shell < Phlex::HTML
    include Phlex::Rails::Helpers::CSRFMetaTags
    include Phlex::Rails::Helpers::CSPMetaTag
    include Phlex::Rails::Helpers::StylesheetLinkTag
    include Phlex::Rails::Helpers::JavaScriptImportmapTags
    include DaisyUI

    DRAWER_ID = "site-drawer"

    def initialize(title: nil)
      @title = title
    end

    def view_template(&)
      doctype
      html(lang: "en", data: { theme: config.default_theme }) do
        render_head
        body(class: "bg-base-100 text-base-content") do
          shell(&)
        end
      end
    end

    private

    def config = DocsKit.configuration

    def render_head
      head do
        title { [@title, config.title_suffix].compact.join(" · ") }
        meta(charset: "utf-8")
        meta(name: "viewport", content: "width=device-width,initial-scale=1")
        csrf_meta_tags
        csp_meta_tag
        # Turbo morphs page-level navigations so a re-render preserves scroll and
        # focus, matching the in-place feel of reactive components.
        meta(name: "turbo-refresh-method", content: "morph")
        meta(name: "turbo-refresh-scroll", content: "preserve")
        config.stylesheets.each { |sheet| stylesheet_link_tag(sheet, data: { turbo_track: "reload" }) }
        javascript_importmap_tags
      end
    end

    # The daisyUI Drawer app-shell. Desktop: sidebar always open (lg:drawer-open).
    # Mobile: sidebar hidden, toggled by the hamburger in the topbar.
    def shell(&)
      Drawer(id: DRAWER_ID, class: "lg:drawer-open min-h-screen") do |drawer|
        drawer.toggle

        drawer.content(class: "flex flex-col min-h-screen") do
          topbar
          main(class: "flex-1 overflow-auto px-4 py-8 md:px-8") do
            div(class: "mx-auto max-w-4xl", &)
          end
        end

        drawer.side(class: "z-40") do
          drawer.overlay
          render Docs::Sidebar.new
        end
      end
    end

    # Sticky topbar: hamburger (mobile only), brand, theme switcher.
    def topbar
      div(class: "navbar bg-base-200 border-b border-base-300 sticky top-0 z-30 px-4") do
        div(class: "flex-1 items-center gap-2") do
          label(for: DRAWER_ID, class: "btn btn-square btn-ghost btn-sm lg:hidden",
                aria_label: "Open menu") { render Docs::Icon.new("menu", class: "size-5") }
          a(href: "/", class: "btn btn-ghost text-lg font-bold") { config.brand }
        end
        div(class: "flex-none") do
          render Docs::ThemeSwitcher.new
        end
      end
    end
  end
end
