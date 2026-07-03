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

  describe "the keyboard-shortcut hint" do
    it "renders a server-side <kbd> hint so the reader sees how to open search" do
      html = render_box

      expect(html).to include("<kbd")
    end

    it "always advertises \"/\" — the shortcut no browser hijacks" do
      html = render_box

      # "/" works in every browser (unlike Cmd+K, which some browsers bind), so
      # it's the guaranteed-visible fallback. It must be present with JS off.
      expect(html).to match(%r{<kbd[^>]*>/?</kbd>|<kbd[^>]*>\s*/\s*</kbd>})
      expect(html).to include(">/</kbd>").or include("> / </kbd>")
    end

    it "renders a modifier hint the controller refines per platform" do
      html = render_box

      # Server default is the majority platform ("Ctrl K"); docs-nav swaps it to
      # ⌘K on mac. Tagged data-hint=modifier so the controller knows which to swap.
      expect(html).to include("Ctrl K")
      expect(html).to include('data-hint="modifier"')
    end

    it "tags the hint badges as docs-nav shortcutHint targets" do
      html = render_box

      expect(html).to include("shortcutHint")
    end

    it "hides the decorative hint from assistive tech (the input has aria-label)" do
      html = render_box

      expect(html).to include('aria-hidden="true"')
    end
  end
end
