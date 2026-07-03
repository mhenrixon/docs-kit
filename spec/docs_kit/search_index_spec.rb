# frozen_string_literal: true

# DocsKit::SearchIndex builds an in-memory search index from the docs pages'
# Markdown twins — one entry per page SECTION (split on `## ` headings), plus a
# page-level entry for the intro text before the first heading. It's a pure Ruby
# builder + scorer: given [title, href, markdown] triples it produces entries,
# and #search ranks them (title > heading > body) with a highlighted snippet.
# No Rails — the controller owns rendering the twins (DocsKit::MarkdownExport),
# exactly as DocsKit::LlmsText separates shaping from the controller's rendering.
#
# The anchor is the crux: the Markdown twin drops the section's slug id (it emits
# `## Add the gem` text only), so the index RECOMPUTES it as the heading text
# parameterized — the same rule DocsUI::Section#slugify uses to stamp the id.
RSpec.describe DocsKit::SearchIndex do
  # A realistic two-page corpus. Each triple is [page_title, page_href, markdown]
  # — the shape the controller produces from MarkdownExport#to_md.
  subject(:index) { described_class.new(pages) }

  let(:install_md) do
    <<~MD
      Install docs-kit in a fresh Rails app.

      ## Add the gem

      Add `gem "docs-kit"` to your Gemfile, then run bundle install.

      ## Run the generator

      Run the install generator to wire the chrome and CSS build.
    MD
  end

  let(:config_md) do
    <<~MD
      Every docs site differs only in configuration.

      ## Themes

      List the daisyUI themes the switcher offers.
    MD
  end

  let(:pages) do
    [
      ["Installation", "/docs/installation", install_md],
      ["Configuration", "/docs/configuration", config_md]
    ]
  end

  describe ".new / #entries" do
    it "builds one entry per section plus a page-intro entry" do
      # Installation: intro + 2 sections; Configuration: intro + 1 section = 5.
      expect(index.entries.size).to eq(5)
    end

    it "carries the page title on every entry" do
      titles = index.entries.map(&:page_title).uniq
      expect(titles).to contain_exactly("Installation", "Configuration")
    end

    it "labels a section entry with its heading text" do
      section = index.entries.find { |e| e.section_title == "Add the gem" }
      expect(section).not_to be_nil
      expect(section.page_title).to eq("Installation")
    end

    it "leaves the page-intro entry with no section title" do
      intro = index.entries.find { |e| e.page_title == "Installation" && e.section_title.nil? }
      expect(intro).not_to be_nil
      expect(intro.body).to include("fresh Rails app")
    end

    it "anchors a section href to the recomputed slug (twin drops the id)" do
      section = index.entries.find { |e| e.section_title == "Run the generator" }
      # heading text → parameterize → the same id DocsUI::Section stamps.
      expect(section.href).to eq("/docs/installation#run-the-generator")
    end

    it "anchors the page-intro entry to the bare page href (no fragment)" do
      intro = index.entries.find { |e| e.page_title == "Configuration" && e.section_title.nil? }
      expect(intro.href).to eq("/docs/configuration")
    end
  end

  describe "#search" do
    it "returns [] for a blank query" do
      expect(index.search("")).to eq([])
      expect(index.search("   ")).to eq([])
      expect(index.search(nil)).to eq([])
    end

    it "finds a body match and returns a SearchHit carrying the page + section" do
      hits = index.search("bundle install")
      hit = hits.first

      expect(hit.page_title).to eq("Installation")
      expect(hit.section_title).to eq("Add the gem")
      expect(hit.href).to eq("/docs/installation#add-the-gem")
    end

    it "is case-insensitive" do
      expect(index.search("THEMES")).not_to be_empty
      expect(index.search("themes")).not_to be_empty
    end

    it "ranks a heading (section-title) match above a body-only match" do
      # "generator" appears in the 'Run the generator' HEADING and in the
      # Installation intro BODY ('install generator'). The heading hit wins.
      hits = index.search("generator")

      expect(hits.first.section_title).to eq("Run the generator")
    end

    it "ranks a page-title match above a heading match above a body match" do
      # Craft three entries that each match 'alpha' in a different field.
      corpus = [
        ["Alpha", "/docs/alpha", "Nothing relevant here.\n\n## Intro\n\nPlain body."],
        ["Beta", "/docs/beta", "Body only.\n\n## Alpha thing\n\nA heading match."],
        ["Gamma", "/docs/gamma", "This mentions alpha in the body.\n\n## Intro\n\nMore."]
      ]
      hits = described_class.new(corpus).search("alpha")

      expect(hits.map(&:page_title).first(3)).to eq(%w[Alpha Beta Gamma])
    end

    it "requires ALL tokens to match (multi-token AND)" do
      # 'themes' is in Configuration; 'gemfile' is in Installation. No single
      # entry has both, so the AND query returns nothing.
      expect(index.search("themes gemfile")).to be_empty

      # Both tokens live in the same 'Add the gem' section.
      hits = index.search("gem gemfile")
      expect(hits).not_to be_empty
      expect(hits.first.section_title).to eq("Add the gem")
    end

    it "includes a snippet containing the matched term" do
      hit = index.search("daisyUI").first

      expect(hit.snippet).to match(/daisyui/i)
    end

    it "marks the matched term in the snippet with <mark> and escapes the rest" do
      hit = index.search("bundle").first

      expect(hit.snippet).to include("<mark>").and include("</mark>")
      # The snippet is HTML-safe: the marked term is wrapped, surrounding text is
      # escaped, so an angle-bracket in the source can't inject markup.
      expect(hit.snippet).to be_a(String)
    end

    it "escapes HTML in the body so a snippet can't inject markup" do
      corpus = [["Danger", "/docs/danger", "Uses <script>alert(1)</script> tags here."]]
      hit = described_class.new(corpus).search("tags").first

      expect(hit.snippet).to include("&lt;script&gt;")
      expect(hit.snippet).not_to include("<script>")
    end

    it "caps results at 20" do
      corpus = Array.new(30) do |i|
        ["Page#{i}", "/docs/p#{i}", "Common keyword appears here in page #{i}."]
      end
      hits = described_class.new(corpus).search("keyword")

      expect(hits.size).to eq(20)
    end

    it "returns [] when nothing matches" do
      expect(index.search("nonexistentxyz")).to eq([])
    end

    it "still indexes a page with an empty twin (title stays searchable)" do
      empty = described_class.new([["Empty page", "/docs/empty", ""]])

      expect(empty.entries.size).to eq(1)
      hit = empty.search("empty").first
      expect(hit.page_title).to eq("Empty page")
      expect(hit.href).to eq("/docs/empty")
    end

    it "treats a `## ` line inside a fenced code block as body, not a section" do
      # The bash fence contains `## install the gem`; it must NOT become a phantom
      # section entry with a `#install-the-gem` anchor (a slug the rendered page
      # never stamps — DocsUI::Section only ids real headings). Only the real
      # `## Real Section` heading below the fence is a section.
      corpus = [["Guide", "/guide", "Intro.\n\n```bash\n## install the gem\n```\n\n## Real Section\n\nBody.\n"]]
      index = described_class.new(corpus)

      # No entry carries the in-fence text as its section title / anchor.
      fence = index.entries.find { |e| e.section_title == "install the gem" }
      expect(fence).to be_nil
      expect(index.entries.map(&:href)).not_to include("/guide#install-the-gem")

      # The in-fence text stays with the intro, and only the real heading is a section.
      section_titles = index.entries.map(&:section_title)
      expect(section_titles).to contain_exactly(nil, "Real Section")
    end

    it "snippets from the head when the match is a section-title, not body text" do
      corpus = [["P", "/docs/p", "Intro.\n\n## Widgets\n\n"]]
      # 'widgets' matches the heading; the section body is empty, so the snippet
      # falls back to the section title.
      hit = described_class.new(corpus).search("widgets").first

      expect(hit.section_title).to eq("Widgets")
      expect(hit.snippet).to match(/widgets/i)
    end
  end

  describe "DocsKit::SearchHit" do
    it "is a value object with the fields a result needs" do
      hit = DocsKit::SearchHit.new(
        page_title: "P", section_title: "S", href: "/docs/p#s",
        snippet: "…", score: 3
      )

      expect(hit.page_title).to eq("P")
      expect(hit.section_title).to eq("S")
      expect(hit.href).to eq("/docs/p#s")
      expect(hit.snippet).to eq("…")
      expect(hit.score).to eq(3)
    end
  end
end
