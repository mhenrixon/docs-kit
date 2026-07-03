# frozen_string_literal: true

RSpec.describe DocsUI::JsonResponse do
  def render_json(...)
    described_class.new(...).call
  end

  it "renders a Hash as pretty-printed JSON with string keys" do
    html = render_json({ id: "obj_1", nested: { count: 2 } })

    # Rouge highlights the JSON; the string content still appears in the markup.
    expect(html).to include("id")
    expect(html).to include("obj_1")
    expect(html).to include("nested")
    expect(html).to include("count")
    expect(html).to include("code-highlight") # went through DocsUI::Code
  end

  it "deep-stringifies nested symbol keys (no Ruby :symbol syntax leaks in)" do
    html = render_json({ outer: { inner: :value } })

    expect(html).not_to include(":inner")
    expect(html).not_to include("=>")
  end

  it "passes a pre-formatted String body through unchanged" do
    preformatted = %({\n  "already": "formatted"\n})
    html = render_json(preformatted)

    expect(html).to include("already")
    expect(html).to include("formatted")
  end

  it "renders a filename title bar (default response.json)" do
    expect(render_json({ a: 1 })).to include("response.json")
  end

  it "accepts a custom filename" do
    expect(render_json({ a: 1 }, filename: "webhook.json")).to include("webhook.json")
  end

  it "escapes HTML in string values (Rouge/Phlex path, no raw injection)" do
    html = render_json({ note: "<script>alert(1)</script>" })

    expect(html).not_to include("<script>alert(1)</script>")
    expect(html).to include("&lt;script&gt;")
  end
end
