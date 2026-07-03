# frozen_string_literal: true

RSpec.describe DocsUI::PropTable do
  def render_prop_table(...)
    described_class.new(...).call
  end

  it "uses the default Option/Type/Default/Description headers" do
    html = render_prop_table([["brand", "String", '"Docs"', "The brand."]])

    expect(html).to include(">Option")
    expect(html).to include(">Type")
    expect(html).to include(">Default")
    expect(html).to include(">Description")
  end

  it "renders the first column as inline code, the rest plain" do
    html = render_prop_table([["brand", "String", '"Docs"', "The brand."]])

    # The name column is code-styled.
    expect(html).to include("<code")
    expect(html).to include(">brand</code>")
    # A later column is NOT wrapped in code.
    expect(html).to include(">The brand.")
    expect(html).not_to include("<code class=\"text-sm\">The brand.")
  end

  it "accepts custom headers, overriding the default set" do
    html = render_prop_table(
      [["title", "String", "—", "Doc title."]],
      headers: %w[Arg Type Default Description]
    )

    expect(html).to include(">Arg")
    expect(html).not_to include(">Option")
  end

  it "reuses DocsUI::Table's wrapper (composition, not duplicated markup)" do
    html = render_prop_table([["brand", "String", '"Docs"', "The brand."]])

    expect(html).to include("not-prose")
    expect(html).to include("rounded-box")
    expect(html).to include("table table-sm table-zebra")
  end

  it "still honors [:code, …] / [:md, …] cell types in non-name columns" do
    html = render_prop_table([["brand", [:code, "String"], "—", [:md, "a **note**"]]])

    expect(html).to include(">String</code>")
    expect(html).to include("<strong>note</strong>")
  end

  it "renders headers only for an empty rows array" do
    html = render_prop_table([])

    expect(html).to include(">Option")
    expect(html).not_to include("<td")
  end
end
