# frozen_string_literal: true

RSpec.describe DocsKit::Configuration do
  describe "#icon_library" do
    it "defaults to lucide (matching the lucide icon names docs-kit ships)" do
      expect(described_class.new.icon_library).to eq("lucide")
    end

    it "is overridable via DocsKit.configure so a site can pin the chrome library" do
      DocsKit.configure { |c| c.icon_library = "phosphor" }

      expect(DocsKit.configuration.icon_library).to eq("phosphor")
    end
  end

  # A registry-v2 stub: a class with the .nav_items API the config derives nav
  # from. Two authored pages in one group.
  def registry_stub
    Class.new do
      def self.nav_items
        { "Guide" => [DocsKit::NavItem.new(href: "/docs/installation", label: "Installation")] }
      end
    end
  end

  describe "#nav_registries" do
    it "defaults to an empty Hash" do
      expect(described_class.new.nav_registries).to eq({})
    end

    it "is overridable so a site maps a heading to its registry" do
      reg = registry_stub
      DocsKit.configure { |c| c.nav_registries = { "Docs" => reg } }

      expect(DocsKit.configuration.nav_registries).to eq({ "Docs" => reg })
    end
  end

  describe "#nav_groups" do
    it "derives from nav_registries when no explicit nav lambda is set" do
      reg = registry_stub
      DocsKit.configure { |c| c.nav_registries = { "Docs" => reg } }

      groups = DocsKit.configuration.nav_groups
      expect(groups.keys).to eq(%w[Docs])
      expect(groups["Docs"]["Guide"].map(&:label)).to eq(%w[Installation])
    end

    it "drops a registry heading whose pages are all unauthored (empty nav_items)" do
      empty = Class.new { def self.nav_items = {} }
      reg = registry_stub
      DocsKit.configure { |c| c.nav_registries = { "Empty" => empty, "Docs" => reg } }

      expect(DocsKit.configuration.nav_groups.keys).to eq(%w[Docs])
    end

    it "lets an explicit nav lambda win over nav_registries (backwards compatible)" do
      reg = registry_stub
      DocsKit.configure do |c|
        c.nav_registries = { "Docs" => reg }
        c.nav = -> { { "Custom" => { "Group" => [] } } }
      end

      expect(DocsKit.configuration.nav_groups.keys).to eq(%w[Custom])
    end

    it "returns an empty Hash when neither nav nor nav_registries is set" do
      expect(described_class.new.nav_groups).to eq({})
    end
  end
end
