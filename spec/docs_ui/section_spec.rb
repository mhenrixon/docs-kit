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
end
