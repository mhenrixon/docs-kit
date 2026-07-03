# frozen_string_literal: true

RSpec.describe DocsUI::FieldTable do
  def render_field_table(...)
    described_class.new(...).call
  end

  let(:fields) do
    [
      { name: "url", type: "string", required: true, description: "HTTPS destination URL." },
      { name: "description", type: "string", description: "Optional internal label." }
    ]
  end

  it "uses Name / Type / Required / Description headers" do
    html = render_field_table(fields)

    expect(html).to include(">Name")
    expect(html).to include(">Type")
    expect(html).to include(">Required")
    expect(html).to include(">Description")
  end

  it "renders the field name in inline <code>" do
    html = render_field_table(fields)

    expect(html).to include(">url</code>")
    expect(html).to include(">description</code>")
  end

  it "renders the type and description as plain cells" do
    html = render_field_table(fields)

    expect(html).to include("string")
    expect(html).to include("HTTPS destination URL.")
  end

  it "marks a required field with a check mark" do
    html = render_field_table([{ name: "url", type: "string", required: true, description: "d" }])

    expect(html).to include("✓")
  end

  it "marks an optional field with the canonical em-dash placeholder" do
    html = render_field_table([{ name: "url", type: "string", description: "d" }])

    expect(html).to include("—")
    expect(html).not_to include("✓")
    # ONE canonical placeholder — never the ASCII hyphen "-" as a stand-in.
    expect(html).not_to include("<td>-</td>")
  end

  it "treats a missing :required key as optional (false default)" do
    html = render_field_table([{ name: "url", type: "string", description: "d" }])

    expect(html).to include("—")
    expect(html).not_to include("✓")
  end

  it "renders a description as inline markdown when passed a [:md, …] cell" do
    html = render_field_table(
      [{ name: "url", type: "string", description: [:md, "a **bold** note"] }]
    )

    expect(html).to include("<strong>bold</strong>")
    expect(html).not_to include("<p>")
  end

  it "reuses DocsUI::Table's wrapper (composition, not duplicated markup)" do
    html = render_field_table(fields)

    expect(html).to include("not-prose")
    expect(html).to include("rounded-box")
    expect(html).to include("table table-sm table-zebra")
  end

  it "renders headers only for an empty fields array" do
    html = render_field_table([])

    expect(html).to include(">Name")
    expect(html).not_to include("<td")
  end

  it "escapes HTML in a plain-string description" do
    html = render_field_table([{ name: "x", type: "string", description: "see <title>" }])

    expect(html).to include("&lt;title&gt;")
    expect(html).not_to include("<title>")
  end
end
