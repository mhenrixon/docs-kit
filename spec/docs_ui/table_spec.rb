# frozen_string_literal: true

RSpec.describe DocsUI::Table do
  def render_table(...)
    described_class.new(...).call
  end

  it "renders each header as a th" do
    html = render_table(%w[Name Type], [])

    expect(html).to include("<th")
    expect(html).to include(">Name")
    expect(html).to include(">Type")
  end

  it "renders each row cell as a td, after the headers" do
    html = render_table(%w[Name Type], [%w[brand String], %w[themes Array]])

    expect(html).to include("<td")
    expect(html).to include("brand")
    expect(html).to include("Array")
    # Headers precede body cells (thead before tbody).
    expect(html.index("Name")).to be < html.index("brand")
  end

  it "wraps the table in the kit's rounded-box border + daisyUI table classes" do
    html = render_table(%w[A], [%w[x]])

    expect(html).to include("not-prose")
    expect(html).to include("rounded-box")
    expect(html).to include("border-base-300")
    expect(html).to include("table table-sm table-zebra")
  end

  it "renders a [:code, \"x\"] cell as an inline <code> element" do
    html = render_table(%w[Name Type], [["brand", [:code, "String"]]])

    expect(html).to include("<code")
    expect(html).to include(">String</code>")
  end

  it "renders a [:md, \"…\"] cell through DocsUI::Markdown as inline content" do
    html = render_table(%w[Name Note], [["brand", [:md, "the **bold** brand"]]])

    # Markdown emphasis is rendered (not left as literal asterisks).
    expect(html).to include("<strong>bold</strong>")
    # …but inline — no block <p> wrapper leaking into the cell.
    expect(html).not_to include("<p>")
  end

  it "renders headers only when the rows array is empty" do
    html = render_table(%w[Name Type], [])

    expect(html).to include("<th")
    expect(html).to include(">Name")
    expect(html).not_to include("<td")
  end

  it "escapes HTML in a plain string cell (Phlex escaping, no html_safe)" do
    html = render_table(%w[Desc], [["Appended to <title> & such"]])

    expect(html).to include("&lt;title&gt;")
    expect(html).to include("&amp;")
    expect(html).not_to include("<title>")
  end

  it "escapes HTML in a header" do
    html = render_table(["<script>"], [])

    expect(html).to include("&lt;script&gt;")
    expect(html).not_to include("<script>")
  end
end
