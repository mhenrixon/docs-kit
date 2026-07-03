# frozen_string_literal: true

# DocsUI::SearchBox is the topbar search affordance the Shell renders when search
# is enabled. It must work with JS off (a real GET form to config.search_path)
# and expose the docs-nav hooks (targets + actions) the palette enhances. Asserts
# on semantics, not a full-HTML snapshot.
RSpec.describe DocsUI::SearchBox do
  def render_box = described_class.new.call

  it "is a real GET form to config.search_path with a q input (JS-off path)" do
    html = render_box

    expect(html).to include('action="/docs/search"')
    expect(html).to include('method="get"')
    expect(html).to include('name="q"')
    expect(html).to include('role="search"')
  end

  it "follows config.search_path when a site overrides it" do
    DocsKit.configure { |c| c.search_path = "/guides/search" }

    expect(render_box).to include('action="/guides/search"')
  end

  it "exposes the docs-nav targets the palette fills" do
    html = render_box

    expect(html).to include("searchScope")
    expect(html).to include("searchInput")
    expect(html).to include("searchResults")
  end

  it "wires the input actions the palette listens on" do
    html = render_box

    expect(html).to include("input->docs-nav#performSearch")
    expect(html).to include("keydown->docs-nav#navigateResults")
    expect(html).to include("submit->docs-nav#submitSearch")
  end

  it "renders the results dropdown hidden (docs-nav reveals it as you type)" do
    html = render_box

    # The palette starts hidden; with JS off it stays hidden and the form submits.
    expect(html).to match(/dropdown-content[^"]*\bhidden\b/)
  end
end
