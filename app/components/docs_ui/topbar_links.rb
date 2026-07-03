# frozen_string_literal: true

module DocsUI
  # The config-driven repo/social links in the topbar, next to the theme switcher
  # (DocsKit.configuration.topbar_links). Each link renders as an icon-only ghost
  # button — a DocsUI::BrandMark (a shipped brand glyph like GitHub/Discord, or a
  # lucide fallback) whose accessible name is the link's #label. External links
  # open in a new tab with rel=noopener; a site-relative link opens in place.
  #
  # Renders nothing when the site configures no links, so a site that sets
  # c.topbar_links = [] (the default) has a byte-identical topbar.
  class TopbarLinks < Phlex::HTML
    def view_template
      links = DocsKit.configuration.topbar_links
      return if links.empty?

      links.each { |link| topbar_link(link) }
    end

    private

    def topbar_link(link)
      # An icon-only button when the link names an icon (square), else a text
      # button showing the label — so an icon-less link is never a blank button.
      icon = link.icon
      a(
        href: link.href,
        class: "btn btn-sm btn-ghost #{'btn-square' if icon}",
        aria_label: link.label,
        title: link.label,
        target: (link.external? ? "_blank" : nil),
        rel: (link.external? ? "noopener noreferrer" : nil)
      ) do
        if icon
          render DocsUI::BrandMark.new(icon, label: link.label, class: "size-5")
        else
          plain link.label
        end
      end
    end
  end
end
