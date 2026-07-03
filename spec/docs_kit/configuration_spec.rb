# frozen_string_literal: true

RSpec.describe DocsKit::Configuration do
  describe "#brand_href" do
    it "defaults to \"/\" (the topbar brand link's current target)" do
      expect(described_class.new.brand_href).to eq("/")
    end

    it "is overridable so a site can point the brand link elsewhere (e.g. /docs)" do
      DocsKit.configure { |c| c.brand_href = "/docs" }

      expect(DocsKit.configuration.brand_href).to eq("/docs")
    end
  end

  describe "#tagline" do
    it "defaults to nil (the llms.txt blockquote line is omitted)" do
      expect(described_class.new.tagline).to be_nil
    end

    it "is overridable so a site sets its llms.txt summary" do
      DocsKit.configure { |c| c.tagline = "The shared Phlex chrome for docs sites." }

      expect(DocsKit.configuration.tagline).to eq("The shared Phlex chrome for docs sites.")
    end
  end

  describe "#page_markdown_action" do
    it "defaults to true (every page shows the 'Markdown' affordance)" do
      expect(described_class.new.page_markdown_action).to be(true)
    end

    it "is overridable so a site can opt out" do
      DocsKit.configure { |c| c.page_markdown_action = false }

      expect(DocsKit.configuration.page_markdown_action).to be(false)
    end
  end

  describe "#code_theme_dark" do
    it "defaults to nil (single-theme behavior, fully backwards compatible)" do
      expect(described_class.new.code_theme_dark).to be_nil
    end

    it "is overridable with a Rouge theme for dark daisyUI themes" do
      DocsKit.configure { |c| c.code_theme_dark = "Rouge::Themes::Monokai" }

      expect(DocsKit.configuration.code_theme_dark).to eq("Rouge::Themes::Monokai")
    end
  end

  describe "#code_theme_dark_class" do
    it "returns nil when code_theme_dark is unset" do
      expect(described_class.new.code_theme_dark_class).to be_nil
    end

    it "resolves a String theme name to the Rouge theme class" do
      DocsKit.configure { |c| c.code_theme_dark = "Rouge::Themes::Monokai" }

      expect(DocsKit.configuration.code_theme_dark_class).to eq(Rouge::Themes::Monokai)
    end

    it "passes a Rouge theme Class through unchanged" do
      DocsKit.configure { |c| c.code_theme_dark = Rouge::Themes::Monokai }

      expect(DocsKit.configuration.code_theme_dark_class).to eq(Rouge::Themes::Monokai)
    end
  end

  describe "#dark_themes" do
    it "defaults to the built-in daisyUI dark theme names" do
      expect(described_class.new.dark_themes).to eq(DocsKit::Configuration::DEFAULT_DARK_THEMES)
    end

    it "ships a frozen default constant so it can't be mutated in place" do
      expect(DocsKit::Configuration::DEFAULT_DARK_THEMES).to be_frozen
    end

    it "is overridable so a site can name its custom dark themes (e.g. zazu-dark)" do
      DocsKit.configure { |c| c.dark_themes = %w[zazu-dark] }

      expect(DocsKit.configuration.dark_themes).to eq(%w[zazu-dark])
    end
  end

  describe "#dark_themes_shipped" do
    it "intersects dark_themes with themes so only shipped themes generate CSS" do
      DocsKit.configure do |c|
        c.themes = %w[light dark synthwave]
      end

      # dark + synthwave are dark daisyUI themes AND shipped; light is not dark.
      expect(DocsKit.configuration.dark_themes_shipped).to eq(%w[dark synthwave])
    end

    it "preserves theme declaration order (not the dark-list order)" do
      DocsKit.configure do |c|
        c.themes = %w[synthwave light dark]
      end

      expect(DocsKit.configuration.dark_themes_shipped).to eq(%w[synthwave dark])
    end

    it "is empty when no shipped theme is a dark theme" do
      DocsKit.configure { |c| c.themes = %w[light retro] }

      expect(DocsKit.configuration.dark_themes_shipped).to eq([])
    end
  end

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

  describe "#api_base_url" do
    it "defaults to a neutral example host" do
      expect(described_class.new.api_base_url).to eq("https://api.example.com")
    end

    it "is overridable so a site points snippets at its own host" do
      DocsKit.configure { |c| c.api_base_url = "https://api.acme.test" }

      expect(DocsKit.configuration.api_base_url).to eq("https://api.acme.test")
    end
  end

  describe "#api_auth_header" do
    it "defaults to nil (no auth line in generated snippets)" do
      expect(described_class.new.api_auth_header).to be_nil
    end

    it "is overridable with the site's example Authorization header" do
      DocsKit.configure { |c| c.api_auth_header = "Authorization: Bearer sk_live_..." }

      expect(DocsKit.configuration.api_auth_header).to eq("Authorization: Bearer sk_live_...")
    end
  end

  describe "#api_clients" do
    it "ships four default clients in a stable order" do
      expect(described_class.new.api_clients.keys).to eq(%i[curl javascript ruby python])
    end

    it "exposes each default as a DocsKit::ApiClient with a label, lexer and template" do
      curl = described_class.new.api_clients[:curl]

      expect(curl).to be_a(DocsKit::ApiClient)
      expect(curl.label).to eq("cURL")
      expect(curl.lexer).to eq(:curl)
      expect(curl.template).to respond_to(:call)
    end

    it "merges site clients over the defaults, appending new ones in declaration order" do
      cli = DocsKit::ApiClient.new(label: "CLI", lexer: :shell, template: ->(_req) { "acme do" })
      DocsKit.configure { |c| c.api_clients = { cli: cli } }

      keys = DocsKit.configuration.api_clients.keys
      expect(keys).to eq(%i[curl javascript ruby python cli])
      expect(DocsKit.configuration.api_clients[:cli]).to eq(cli)
    end

    it "lets a site override a default client by reusing its token" do
      sdk_ruby = DocsKit::ApiClient.new(label: "Ruby", lexer: :ruby, template: ->(_req) { "Acme.new" })
      DocsKit.configure { |c| c.api_clients = { ruby: sdk_ruby } }

      clients = DocsKit.configuration.api_clients
      expect(clients.keys).to eq(%i[curl javascript ruby python]) # order preserved, no dup
      expect(clients[:ruby]).to eq(sdk_ruby)
    end
  end
end
