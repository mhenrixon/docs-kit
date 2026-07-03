# frozen_string_literal: true

RSpec.describe DocsUI::Callout do
  it "renders a daisyUI alert with the level's styling and icon" do
    html = described_class.new(:warning) { "Restart the server." }.call

    expect(html).to include("alert-warning")
    expect(html).to include("Restart the server.")
  end

  it "renders the title when given" do
    html = described_class.new(:tip, title: "Heads up") { "body" }.call

    expect(html).to include("Heads up")
  end

  # The Markdown export (DocsKit::MarkdownExport) turns a callout into a
  # `> **Tip:** …` blockquote. It reads the level off data-md-callout so the
  # converter needn't reverse-engineer it from the alert-* class.
  describe "data-md-callout (the Markdown-export blockquote hint)" do
    it "stamps the level name on the alert" do
      html = described_class.new(:tip) { "A helpful tip." }.call

      expect(html).to include('data-md-callout="tip"')
    end

    it "stamps note for the default level" do
      html = described_class.new { "Just a note." }.call

      expect(html).to include('data-md-callout="note"')
    end

    it "falls back to note for an unknown level" do
      html = described_class.new(:bogus) { "text" }.call

      expect(html).to include('data-md-callout="note"')
    end
  end
end
