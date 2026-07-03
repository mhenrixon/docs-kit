# frozen_string_literal: true

module DocsKit
  # A single external link rendered in the topbar next to the theme switcher —
  # a repo link, a chat invite, a social profile. Sites declare these in config
  # as plain Hashes; #topbar_links normalizes each into a TopbarLink so the Shell
  # stays value-object-driven (like DocsKit::NavItem for the sidebar):
  #
  #   c.topbar_links = [
  #     { href: "https://github.com/me/repo", label: "GitHub",  icon: :github },
  #     { href: "https://discord.gg/abc",     label: "Discord", icon: :discord },
  #   ]
  #
  # The Shell renders each as an icon-only ghost button; #label is the accessible
  # name (aria-label + title). #icon is a token DocsUI::BrandMark resolves — a
  # shipped brand mark (:github, :discord, …) or, failing that, a lucide icon
  # name (any string DocsUI::Icon knows). nil #icon renders the label as text.
  TopbarLink = Data.define(:href, :label, :icon) do
    def initialize(href:, label:, icon: nil)
      super(href:, label:, icon: icon&.to_sym)
    end

    # Build a TopbarLink from a Hash (symbol- OR string-keyed, so a YAML/JSON
    # config loads cleanly) or pass an existing TopbarLink through unchanged.
    def self.from(link)
      return link if link.is_a?(self)

      attrs = link.to_h.transform_keys(&:to_sym)
      new(href: attrs[:href], label: attrs[:label], icon: attrs[:icon])
    end

    # Whether the href points off-site (absolute http/https). The Shell adds
    # target=_blank + rel=noopener only for external links; a site-relative link
    # (e.g. "/changelog") opens in place like any nav link.
    def external?
      href.to_s.match?(%r{\Ahttps?://}i)
    end
  end
end
