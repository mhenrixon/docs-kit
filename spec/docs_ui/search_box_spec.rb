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

  it "shrinks on a narrow topbar so it can't push the theme switcher off-screen" do
    # On a phone the brand + search + switcher must fit; the box shrinks
    # (min-w-0, not flex-none) and the input is capped on mobile (max-w-[40vw]),
    # lifted at sm:. Without this the topbar overflows ~34px at 390px.
    html = render_box

    expect(html).to include("min-w-0")
    expect(html).to include("max-w-[40vw]")
    expect(html).to include("sm:max-w-none")
    expect(html).not_to include("dropdown flex-none")
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

  describe "the keyboard-shortcut hint (config-driven)" do
    it "renders one <kbd> badge per configured shortcut" do
      html = render_box

      # Defaults are ["/", "mod+k"] → two badges.
      expect(html.scan("<kbd").size).to eq(2)
    end

    it "advertises the default \"/\" and \"Ctrl K\" (mod chord) badges" do
      html = render_box

      # "/" — the shortcut no browser hijacks. "Ctrl K" — the mod chord's server
      # default (docs-nav swaps the mod label to ⌘K on mac).
      expect(html).to include(">/</kbd>").or include("> / </kbd>")
      expect(html).to include("Ctrl K")
    end

    it "tags a mod-chord badge as a modifier hint the controller refines" do
      html = render_box

      # Only the mod badge is data-hint=modifier; docs-nav swaps just that label.
      expect(html).to include('data-hint="modifier"')
    end

    it "reflects a site's custom shortcut list in the badges" do
      DocsKit.configure { |c| c.search_shortcuts = ["mod+k", "s"] }
      html = render_box

      expect(html.scan("<kbd").size).to eq(2)
      expect(html).to include("Ctrl K") # mod+k
      expect(html).to include(">s</kbd>").or include("> s </kbd>") # bare "s"
    end

    it "renders no hint badges when a site clears the shortcut list" do
      DocsKit.configure { |c| c.search_shortcuts = [] }
      html = render_box

      expect(html).not_to include("<kbd")
    end

    it "tags the badges as docs-nav shortcutHint targets" do
      html = render_box

      expect(html).to include("shortcutHint")
    end

    it "hides the decorative hint from assistive tech (the input has aria-label)" do
      html = render_box

      expect(html).to include('aria-hidden="true"')
    end
  end

  describe "the shortcut payload docs-nav binds against" do
    it "emits the parsed shortcut list as JSON on the search scope" do
      html = render_box

      # docs-nav reads this to bind each key without hardcoding — the JSON carries
      # the key + modifier flags for every configured shortcut.
      expect(html).to include("docs-nav-shortcuts-value")
      expect(html).to include("&quot;key&quot;:&quot;k&quot;").or include('"key":"k"')
      expect(html).to include("mod")
    end

    it "reflects a custom shortcut list in the payload" do
      DocsKit.configure { |c| c.search_shortcuts = ["ctrl+shift+f"] }
      html = render_box

      expect(html).to include("shift")
      expect(html).to include("&quot;key&quot;:&quot;f&quot;").or include('"key":"f"')
    end
  end
end
