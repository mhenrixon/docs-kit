# frozen_string_literal: true

RSpec.describe DocsUI::Section do
  # Render the Section inside a host Phlex component so the body block runs in a
  # Phlex context (where `plain`, `render`, etc. are available), as it would on a
  # real page.
  def render_section(*args, body: "BODY", **kwargs)
    section_args = args
    section_kwargs = kwargs
    Class.new(Phlex::HTML) do
      define_method(:view_template) do
        render DocsUI::Section.new(*section_args, **section_kwargs) { plain body }
      end
    end.new.call
  end

  # Render two sibling sections inside one host so they share a single Phlex
  # render context (as they would on a real Page). Colliding titles must NOT
  # produce duplicate DOM ids/anchors, or in-page links + the auto-TOC break.
  def render_two(title_a, title_b)
    Class.new(Phlex::HTML) do
      define_method(:view_template) do
        render(DocsUI::Section.new(title_a) { plain "A" })
        render(DocsUI::Section.new(title_b) { plain "B" })
      end
    end.new.call
  end

  it "de-duplicates ids when two sibling sections slugify to the same value" do
    html = render_two("Overview", "Overview")

    expect(html.scan('id="overview"').length).to eq(1)
    expect(html).to include('id="overview-1"')
    expect(html).to include('href="#overview"')
    expect(html).to include('href="#overview-1"')
  end

  it "de-duplicates ids for distinct titles that slugify identically (e.g. C++/C--)" do
    html = render_two("C++", "C--")

    ids = html.scan(/id="([^"]*)"/).flatten
    expect(ids.uniq.length).to eq(ids.length)
  end

  it "falls back to a sequenced id when the title slugifies to empty" do
    html = render_two("+++", "***")

    ids = html.scan(/id="([^"]*)"/).flatten
    expect(ids).to all(match(/\Asection(-\d+)?\z/))
    expect(ids.uniq.length).to eq(ids.length)
  end

  it "renders the title, anchor, and body" do
    html = render_section("Add the gem")

    expect(html).to include('id="add-the-gem"')
    expect(html).to include(">Add the gem")
    expect(html).to include('href="#add-the-gem"')
    expect(html).to include("BODY")
  end

  it "renders an optional description string under the title, before the body" do
    html = render_section("Overview", description: "A short lead.")

    expect(html).to include("A short lead.")
    expect(html.index("A short lead.")).to be < html.index("BODY")
    expect(html.index(">Overview")).to be < html.index("A short lead.")
  end

  it "omits the description entirely when none is given" do
    html = render_section("Plain")

    expect(html).not_to include("text-base-content/70")
  end

  it "renders a callable description as rich Phlex markup" do
    desc = lambda do
      code { "POST" }
      plain " /v1/messages"
    end
    html = render_section("Create a message", description: desc)

    expect(html).to include("<code>POST</code>")
    expect(html).to include("/v1/messages")
    expect(html.index("/v1/messages")).to be < html.index("BODY")
  end

  it "renders a Phlex component instance description (e.g. DocsUI::Endpoint)" do
    endpoint = DocsUI::Endpoint.new(:post, "/v1/messages")
    html = render_section("Create a message", description: endpoint)

    # The component's own markup lands in the description slot, before the body.
    expect(html).to include("badge-primary")
    expect(html).to include(">POST<")
    expect(html).to include("/v1/messages")
    expect(html.index("/v1/messages")).to be < html.index("BODY")
    expect(html.index(">Create a message")).to be < html.index("/v1/messages")
  end
end
