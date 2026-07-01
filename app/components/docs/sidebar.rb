# frozen_string_literal: true

module Docs
  # The drawer sidebar: a brand header (with an optional version badge) over the
  # nav, driven entirely by DocsKit.configuration.nav_groups. Renders inside the
  # daisyUI drawer-side (Docs::Shell owns responsive visibility), so this is just
  # the panel content.
  #
  # nav_groups is an ordered Hash:
  #   { "Heading" => { "Subgroup" => [DocsKit::NavItem, ...] } }
  class Sidebar < Phlex::HTML
    include Phlex::Rails::Helpers::Request
    include DaisyUI

    def view_template
      div(class: "bg-base-200 flex min-h-full w-72 flex-col") do
        header_section
        div(class: "flex-1 overflow-y-auto px-2 pb-6") do
          Menu(class: "w-full gap-1") do
            nav_groups.each { |heading, grouped| nav_group(heading, grouped) }
          end
        end
      end
    end

    private

    def config = DocsKit.configuration
    def nav_groups = config.nav_groups

    def header_section
      div(class: "flex min-h-16 items-center gap-2 px-4") do
        a(href: "/", class: "text-lg font-bold text-base-content") { config.brand }
        badge = config.version_badge_text
        span(class: "badge badge-sm badge-ghost") { badge } if badge
      end
    end

    # A top-level collapsible group (e.g. "Docs") holding collapsible sub-groups
    # (e.g. "Guide", "Examples"). `grouped` is a { subgroup => [items] } Hash.
    def nav_group(heading, grouped)
      return if grouped.nil? || grouped.empty?

      li do
        details(open: true) do
          summary(class: "text-xs font-semibold uppercase tracking-wider text-base-content/50") { heading }
          ul do
            grouped.each { |subgroup, items| nav_subgroup(subgroup, items) }
          end
        end
      end
    end

    # A collapsible sub-group: its title is a <summary> so the whole section folds
    # away. daisyUI's Menu renders nested li>details as an accordion natively.
    def nav_subgroup(subgroup, items)
      li do
        details(open: true) do
          summary(class: "menu-title text-xs") { subgroup }
          ul do
            items.each { |item| li { nav_link(item) } }
          end
        end
      end
    end

    def nav_link(item)
      a(href: item.href, class: link_classes(item.href)) do
        render Docs::Icon.new(item.icon, class: "size-4 shrink-0") if item.icon
        span(class: "truncate") { item.label }
      end
    end

    def link_classes(href)
      active = current_path == href
      ["flex items-center gap-3", (active ? "menu-active font-medium" : nil)].compact
    end

    def current_path
      request&.path
    rescue StandardError
      nil
    end
  end
end
