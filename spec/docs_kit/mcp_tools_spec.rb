# frozen_string_literal: true

# DocsKit::McpTools is the pure, HTTP-free core the MCP server exposes: three
# plain-Ruby functions over the SAME registry + Markdown twin + search index the
# docs render from (DocsKit::LlmsText.pages / MarkdownExport / SearchIndex). No
# `mcp` gem, no JSON-RPC, no controller — so the whole consumption story is
# unit-testable without booting Rails or the SDK. DocsKit::McpServer wraps these
# into MCP tools; this spec proves the data.
RSpec.describe DocsKit::McpTools do
  # A page-ish registry entry: #slug / #title / #group / #href / #view_class —
  # exactly the duck type DocsKit::Registry::Entry (and LlmsText.pages) exposes.
  # A nil view_class means an unwritten page, excluded everywhere.
  def entry(slug:, title:, group:, href:, view_class:)
    Struct.new(:slug, :title, :group, :href, :view_class, keyword_init: true)
          .new(slug:, title:, group:, href:, view_class:)
  end

  # A fake registry standing in for a DocsKit::Registry class: #all lists every
  # entry (authored + unwritten) and #from_slug looks one up, in registry order.
  def registry(all:)
    Class.new do
      define_singleton_method(:all) { all }
      define_singleton_method(:from_slug) { |slug| all.find { |e| e.slug.to_s == slug.to_s } }
    end
  end

  # A view whose #call renders a #docs-content region MarkdownExport can convert.
  # Built as a bare class (no Phlex host needed — the converter works on the
  # rendered HTML string), matching the markdown_export spec's html fixture.
  def view_rendering(inner_html)
    Class.new do
      define_method(:call) { "<div id=\"docs-content\">#{inner_html}</div>" }
    end
  end

  let(:overview_view) { view_rendering("<h2>Setup</h2><p>Install the gem, then configure it.</p>") }
  let(:install_view)  { view_rendering("<p>Add the gem to your Gemfile.</p>") }

  let(:doc_registry) do
    registry(
      all: [
        entry(slug: "overview", title: "Overview", group: "Guide", href: "/docs/overview", view_class: overview_view),
        entry(slug: "unwritten", title: "Unwritten", group: "Guide", href: "/docs/unwritten", view_class: nil),
        entry(slug: "installation", title: "Installation", group: "Guide", href: "/docs/installation",
              view_class: install_view)
      ]
    )
  end

  def configure(registries: { "Docs" => doc_registry })
    DocsKit.configure { |c| c.nav_registries = registries }
    DocsKit.configuration
  end

  describe ".list_pages" do
    subject(:pages) { described_class.list_pages(configure, base_url: "https://acme.dev") }

    it "returns one entry per AUTHORED page (unwritten pages excluded)" do
      expect(pages.map { |p| p[:slug] }).to eq(%w[overview installation])
    end

    it "carries slug, title, group, and an absolute url for each page" do
      overview = pages.first

      expect(overview).to include(
        slug: "overview",
        title: "Overview",
        group: "Guide",
        url: "https://acme.dev/docs/overview"
      )
    end

    it "falls back to a relative url when no base_url is given" do
      relative = described_class.list_pages(configure)

      expect(relative.first[:url]).to eq("/docs/overview")
    end

    it "spans every registry in config order" do
      api = registry(all: [entry(slug: "users", title: "Users", group: "API", href: "/api/users",
                                 view_class: view_rendering("<p>List users.</p>"))])
      pages = described_class.list_pages(configure(registries: { "Docs" => doc_registry, "API" => api }))

      expect(pages.map { |p| p[:title] }).to eq(%w[Overview Installation Users])
    end
  end

  describe ".get_page" do
    it "returns the page's Markdown twin for a known slug" do
      result = described_class.get_page(configure, slug: "overview", base_url: "https://acme.dev")

      expect(result[:markdown]).to include("## Setup").and include("Install the gem")
      expect(result[:found]).to be(true)
    end

    it "carries the page title and absolute url" do
      result = described_class.get_page(configure, slug: "installation", base_url: "https://acme.dev")

      expect(result).to include(title: "Installation", url: "https://acme.dev/docs/installation")
    end

    context "when the slug is unknown" do
      subject(:result) { described_class.get_page(configure, slug: "nope") }

      it "reports not found rather than raising" do
        expect(result[:found]).to be(false)
      end

      it "lists the valid slugs so an agent can retry" do
        expect(result[:message]).to include("overview").and include("installation")
        expect(result[:message]).not_to include("unwritten")
      end
    end

    context "when the slug names an unwritten page" do
      it "is treated as not found (its view_class doesn't resolve)" do
        result = described_class.get_page(configure, slug: "unwritten")

        expect(result[:found]).to be(false)
      end
    end
  end

  describe ".search_docs" do
    subject(:hits) { described_class.search_docs(configure, query: "install", base_url: "https://acme.dev") }

    it "returns ranked hits with page_title, section_title, url, and snippet" do
      hit = hits.first

      expect(hit).to include(:page_title, :section_title, :url, :snippet)
    end

    it "matches content across every authored page's Markdown twin" do
      titles = hits.map { |h| h[:page_title] }

      expect(titles).to include("Installation")
    end

    it "absolutizes each hit's url against the base_url" do
      expect(hits.map { |h| h[:url] }).to all(start_with("https://acme.dev/"))
    end

    it "strips the <mark> highlight so the snippet is plain text (not HTML)" do
      expect(hits.map { |h| h[:snippet] }.join).not_to include("<mark>")
    end

    it "returns an empty list for a blank query" do
      expect(described_class.search_docs(configure, query: "")).to eq([])
    end
  end
end
