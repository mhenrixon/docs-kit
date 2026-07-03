# frozen_string_literal: true

require "tmpdir"
require "fileutils"

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

  describe "#seo" do
    it "returns a DocsKit::SeoConfig with backwards-safe defaults" do
      seo = described_class.new.seo

      expect(seo).to be_a(DocsKit::SeoConfig)
      expect(seo.description).to be_nil
      expect(seo.og_image).to eq("og/og.png")
    end

    it "memoizes the same instance so a `c.seo.x = ...` block sticks" do
      config = described_class.new
      first = config.seo

      # The same object every call — a `c.seo.description = ...` block mutates the
      # instance the Shell later reads (not a throwaway rebuilt per access).
      expect(config.seo).to be(first)
    end

    it "is configured via the nested block (c.seo.description = ...)" do
      DocsKit.configure { |c| c.seo.description = "The shared Phlex chrome for docs." }

      expect(DocsKit.configuration.seo.description).to eq("The shared Phlex chrome for docs.")
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

  describe "#search" do
    it "defaults to true (the topbar search form renders)" do
      expect(described_class.new.search).to be(true)
    end

    it "is overridable so a site can hide search site-wide" do
      DocsKit.configure { |c| c.search = false }

      expect(DocsKit.configuration.search).to be(false)
    end
  end

  describe "#mcp" do
    it "defaults to true (the endpoint is on wherever the mcp gem + route are present)" do
      expect(described_class.new.mcp).to be(true)
    end

    it "is overridable so a site with the gem installed can still disable the endpoint" do
      DocsKit.configure { |c| c.mcp = false }

      expect(DocsKit.configuration.mcp).to be(false)
    end
  end

  describe "#mcp_enabled?" do
    # The endpoint requires BOTH the config toggle on AND the optional `mcp` gem
    # present — the same "toggle AND capability" shape as #search_enabled?. The
    # suite loads `mcp` (dev/test group), so defined?(MCP) is true here.
    it "is true when #mcp is on and the mcp gem is loaded" do
      skip "mcp gem not loaded in this run" unless defined?(MCP)

      expect(described_class.new.mcp_enabled?).to be(true)
    end

    it "is false when #mcp is off, even with the gem present" do
      DocsKit.configure { |c| c.mcp = false }

      expect(DocsKit.configuration.mcp_enabled?).to be(false)
    end

    it "is false when the mcp gem is absent, even with #mcp on" do
      config = described_class.new
      allow(config).to receive(:mcp_gem_present?).and_return(false)

      expect(config.mcp_enabled?).to be(false)
    end
  end

  describe "#search_path" do
    it "defaults to \"/docs/search\" (the route the generator draws)" do
      expect(described_class.new.search_path).to eq("/docs/search")
    end

    it "is overridable so a site can mount search elsewhere" do
      DocsKit.configure { |c| c.search_path = "/guides/search" }

      expect(DocsKit.configuration.search_path).to eq("/guides/search")
    end
  end

  describe "#search_shortcuts" do
    it "defaults to \"/\" and the platform \"mod+k\" chord" do
      shortcuts = described_class.new.search_shortcuts

      expect(shortcuts.map(&:key)).to eq(%w[/ k])
      # The chord is the platform modifier so one config works on every OS.
      slash, modk = shortcuts
      expect(slash.mod?).to be(false)
      expect(modk.mod?).to be(true)
    end

    it "returns parsed DocsKit::Shortcut objects, not raw strings" do
      expect(described_class.new.search_shortcuts).to all(be_a(DocsKit::Shortcut))
    end

    it "accepts a site's own list of shortcut strings" do
      DocsKit.configure { |c| c.search_shortcuts = ["mod+k", "s", "ctrl+shift+f"] }

      shortcuts = DocsKit.configuration.search_shortcuts
      expect(shortcuts.map(&:key)).to eq(%w[k s f])
      expect(shortcuts.last.shift?).to be(true)
    end

    it "drops entries that don't parse (a modifier-only string)" do
      DocsKit.configure { |c| c.search_shortcuts = ["/", "mod+", ""] }

      expect(DocsKit.configuration.search_shortcuts.map(&:key)).to eq(%w[/])
    end

    it "is empty when a site clears the list" do
      DocsKit.configure { |c| c.search_shortcuts = [] }

      expect(DocsKit.configuration.search_shortcuts).to eq([])
    end
  end

  describe "#search_enabled?" do
    it "is true by default (search on + a path set)" do
      expect(described_class.new.search_enabled?).to be(true)
    end

    it "is false when search is disabled" do
      DocsKit.configure { |c| c.search = false }

      expect(DocsKit.configuration.search_enabled?).to be(false)
    end

    it "is false when search_path is blanked (nothing to submit to)" do
      DocsKit.configure { |c| c.search_path = "" }

      expect(DocsKit.configuration.search_enabled?).to be(false)
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

    it "degrades to nil (no dark CSS) when the theme name doesn't resolve, rather than raising" do
      DocsKit.configure { |c| c.code_theme_dark = "Rouge::Themes::Nope" }

      expect { DocsKit.configuration.code_theme_dark_class }.not_to raise_error
      expect(DocsKit.configuration.code_theme_dark_class).to be_nil
    end
  end

  describe "#code_theme_class" do
    it "resolves a String theme name to the Rouge theme class" do
      DocsKit.configure { |c| c.code_theme = "Rouge::Themes::Github" }

      expect(DocsKit.configuration.code_theme_class).to eq(Rouge::Themes::Github)
    end

    it "degrades to the default theme when a typo'd theme name doesn't resolve (not a crash)" do
      DocsKit.configure { |c| c.code_theme = "Rouge::Themes::Doesnotexist" }

      expect { DocsKit.configuration.code_theme_class }.not_to raise_error
      expect(DocsKit.configuration.code_theme_class).to eq(Rouge::Themes::Monokai)
    end
  end

  describe "#version_badge_text" do
    it "returns nil when unset" do
      expect(described_class.new.version_badge_text).to be_nil
    end

    it "calls a lambda value" do
      DocsKit.configure { |c| c.version_badge = -> { "v1.2.3" } }

      expect(DocsKit.configuration.version_badge_text).to eq("v1.2.3")
    end

    it "renders a plain String value (not only a callable)" do
      DocsKit.configure { |c| c.version_badge = "v1.2" }

      expect(DocsKit.configuration.version_badge_text).to eq("v1.2")
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

    it "honors an explicitly-assigned nav that resolves to empty (not object identity)" do
      # A site that deliberately sets an empty nav lambda must WIN over
      # nav_registries — the 'is nav set?' test is explicit assignment, not
      # `equal?(DEFAULT_NAV)` (any lambda is a different object).
      reg = registry_stub
      DocsKit.configure do |c|
        c.nav_registries = { "Docs" => reg }
        c.nav = -> { {} }
      end

      expect(DocsKit.configuration.nav_groups).to eq({})
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

  describe "#openapi" do
    let(:yaml_path) { File.expand_path("../fixtures/openapi.yaml", __dir__) }

    it "defaults to nil (the bridge is off; sites keep working unchanged)" do
      expect(described_class.new.openapi).to be_nil
    end

    it "accepts a String path" do
      DocsKit.configure { |c| c.openapi = yaml_path }

      expect(DocsKit.configuration.openapi).to eq(yaml_path)
    end

    it "accepts a Pathname" do
      DocsKit.configure { |c| c.openapi = Pathname.new(yaml_path) }

      expect(DocsKit.configuration.openapi).to eq(Pathname.new(yaml_path))
    end

    it "accepts an already-parsed Hash" do
      hash = YAML.safe_load_file(yaml_path, aliases: true, permitted_classes: [Date, Time])
      DocsKit.configure { |c| c.openapi = hash }

      expect(DocsKit.configuration.openapi).to eq(hash)
    end
  end

  describe "#topbar_links" do
    it "defaults to an empty array (no topbar links, byte-identical to before)" do
      expect(described_class.new.topbar_links).to eq([])
    end

    it "normalizes symbol-keyed Hashes into TopbarLink value objects" do
      DocsKit.configure do |c|
        c.topbar_links = [{ href: "https://github.com/me/repo", label: "GitHub", icon: :github }]
      end

      links = DocsKit.configuration.topbar_links
      expect(links.length).to eq(1)
      expect(links.first).to be_a(DocsKit::TopbarLink)
      expect(links.first.href).to eq("https://github.com/me/repo")
      expect(links.first.label).to eq("GitHub")
      expect(links.first.icon).to eq(:github)
    end

    it "accepts already-built TopbarLink objects unchanged" do
      link = DocsKit::TopbarLink.new(href: "/x", label: "X", icon: :x)
      DocsKit.configure { |c| c.topbar_links = [link] }

      expect(DocsKit.configuration.topbar_links).to eq([link])
    end

    it "preserves declaration order across mixed inputs" do
      DocsKit.configure do |c|
        c.topbar_links = [
          { href: "/a", label: "A", icon: :github },
          { href: "/b", label: "B", icon: :discord }
        ]
      end

      expect(DocsKit.configuration.topbar_links.map(&:label)).to eq(%w[A B])
    end

    it "coerces a nil assignment back to an empty array" do
      DocsKit.configure { |c| c.topbar_links = nil }

      expect(DocsKit.configuration.topbar_links).to eq([])
    end
  end

  describe "#openapi_document" do
    let(:yaml_path) { File.expand_path("../fixtures/openapi.yaml", __dir__) }

    it "returns a Document when c.openapi is set" do
      DocsKit.configure { |c| c.openapi = yaml_path }

      expect(DocsKit.configuration.openapi_document).to be_a(DocsKit::OpenApi::Document)
    end

    it "memoizes the loaded Document (same instance across reads)" do
      DocsKit.configure { |c| c.openapi = yaml_path }
      config = DocsKit.configuration
      first = config.openapi_document

      expect(config.openapi_document).to be(first)
    end

    it "reloads when the source file's mtime changes" do
      tmp = File.join(Dir.mktmpdir, "openapi.yaml")
      FileUtils.cp(yaml_path, tmp)
      DocsKit.configure { |c| c.openapi = tmp }
      config = DocsKit.configuration
      first = config.openapi_document

      # Rewrite with a changed mtime a second into the future (mtime resolution).
      FileUtils.touch(tmp, mtime: File.mtime(tmp) + 2)

      expect(config.openapi_document).not_to be(first)
    end

    it "raises a DocsKit::Error naming c.openapi when read while unset" do
      expect { described_class.new.openapi_document }
        .to raise_error(DocsKit::Error, /c\.openapi/)
    end
  end
end
