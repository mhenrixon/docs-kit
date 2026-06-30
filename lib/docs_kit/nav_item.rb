# frozen_string_literal: true

module DocsKit
  # A single sidebar link. Sites map their own registries (Doc, Demo,
  # ComponentDoc, ...) to NavItems in the nav callable, so the Sidebar stays
  # registry-agnostic:
  #
  #   c.nav = -> {
  #     {
  #       "Demos" => Demo.grouped.transform_values { |demos|
  #         demos.map { |d| DocsKit::NavItem.new(href: demo_path(d.slug), label: d.title, icon: d.icon) }
  #       },
  #     }
  #   }
  #
  # The Sidebar renders #label at #href, with an optional lucide #icon.
  NavItem = Data.define(:href, :label, :icon) do
    def initialize(href:, label:, icon: nil)
      super
    end
  end
end
