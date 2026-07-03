# frozen_string_literal: true

# DocsUI::SearchResults renders the server-rendered results page (the JS-off
# path): the query echoed back, hits grouped by page, each result linking to its
# section anchor, and a zero-hit guidance state. It's the body a page renders
# inside the Shell, so the whole thing works with no JavaScript. Asserts on
# semantics (a grouped page heading, an anchored href, the guidance text), not a
# brittle full-HTML snapshot.
RSpec.describe DocsUI::SearchResults do
  def render_results(...)
    described_class.new(...).call
  end

  let(:hits) do
    [
      DocsKit::SearchHit.new(
        page_title: "Installation", section_title: "Add the gem",
        href: "/docs/installation#add-the-gem",
        snippet: "Add <mark>gem</mark> to your Gemfile", score: 11
      ),
      DocsKit::SearchHit.new(
        page_title: "Installation", section_title: "Run the generator",
        href: "/docs/installation#run-the-generator",
        snippet: "Run the install <mark>generator</mark>", score: 10
      ),
      DocsKit::SearchHit.new(
        page_title: "Configuration", section_title: nil,
        href: "/docs/configuration",
        snippet: "Every docs site differs only in <mark>configuration</mark>", score: 1
      )
    ]
  end

  describe "with hits" do
    it "echoes the query back" do
      html = render_results(query: "gem", hits: hits)

      expect(html).to include("gem")
    end

    it "groups results under each page title (one heading per page)" do
      html = render_results(query: "x", hits: hits)

      # Two distinct pages → two group headings, each rendered once.
      expect(html.scan(">Installation<").size).to eq(1)
      expect(html.scan(">Configuration<").size).to eq(1)
    end

    it "links each hit to its section anchor" do
      html = render_results(query: "x", hits: hits)

      expect(html).to include('href="/docs/installation#add-the-gem"')
      expect(html).to include('href="/docs/installation#run-the-generator"')
      expect(html).to include('href="/docs/configuration"')
    end

    it "shows the section title as the result label" do
      html = render_results(query: "x", hits: hits)

      expect(html).to include("Add the gem")
      expect(html).to include("Run the generator")
    end

    it "renders the pre-highlighted snippet markup (trusted, gem-produced)" do
      html = render_results(query: "gem", hits: hits)

      # The <mark> from the SearchIndex snippet survives to the page (it's an
      # HTML-safe, gem-produced string), so the matched term is visibly marked.
      expect(html).to include("<mark>gem</mark>")
    end
  end

  describe "with no hits" do
    it "renders zero-hit guidance instead of an empty list" do
      html = render_results(query: "zzz", hits: [])

      expect(html).to match(/no results/i)
      # Echoes the query the reader typed so they can see what was searched.
      expect(html).to include("zzz")
    end
  end

  describe "with a blank query (the bare search page)" do
    it "prompts the reader to type a query" do
      html = render_results(query: "", hits: [])

      expect(html).to match(/search/i)
    end
  end

  it "escapes the echoed query (no HTML injection from the q param)" do
    html = render_results(query: "<script>alert(1)</script>", hits: [])

    expect(html).not_to include("<script>alert(1)</script>")
    expect(html).to include("&lt;script&gt;")
  end
end
