# frozen_string_literal: true

RSpec.describe DocsUI::Header do
  # Render the Header inside a host Phlex component so the (optional) lead block
  # runs in a Phlex context, as it would on a real page.
  def render_header(*args, lead: nil, **kwargs)
    header_args = args
    header_kwargs = kwargs
    lead_text = lead
    Class.new(Phlex::HTML) do
      define_method(:view_template) do
        if lead_text
          render DocsUI::Header.new(*header_args, **header_kwargs) { plain lead_text }
        else
          render DocsUI::Header.new(*header_args, **header_kwargs)
        end
      end
    end.new.call
  end

  it "renders the title from a positional argument" do
    html = render_header("Installation")

    expect(html).to include("<h1")
    expect(html).to include(">Installation")
  end

  it "renders the eyebrow kicker above the title" do
    html = render_header("Installation", eyebrow: "Guide")

    expect(html).to include(">Guide")
    expect(html.index(">Guide")).to be < html.index(">Installation")
  end

  it "renders the block as the lead paragraph under the h1" do
    html = render_header("Installation", lead: "Add the gem.")

    expect(html).to include("Add the gem.")
    expect(html.index(">Installation")).to be < html.index("Add the gem.")
  end

  # Backwards compatibility: existing sites (the gem Page base + both consumer
  # sites) pass the title as a kwarg. That MUST keep working, silently.
  context "when the title is passed as the legacy title: kwarg" do
    it "renders the same h1 as the positional form" do
      positional = render_header("Installation")
      legacy = render_header(title: "Installation")

      expect(legacy).to include(">Installation")
      expect(legacy).to eq(positional)
    end

    it "still honors the eyebrow kwarg alongside title:" do
      html = render_header(title: "Installation", eyebrow: "Guide")

      expect(html).to include(">Guide")
      expect(html).to include(">Installation")
    end
  end

  # The convention: primary arg is positional. If a caller mixes both forms,
  # the positional wins (it is the documented primary path).
  context "when both a positional title and a title: kwarg are given" do
    it "the positional title wins" do
      html = render_header("Positional", title: "Kwarg")

      expect(html).to include(">Positional")
      expect(html).not_to include(">Kwarg")
    end
  end
end
