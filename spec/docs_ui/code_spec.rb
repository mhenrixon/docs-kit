# frozen_string_literal: true

RSpec.describe DocsUI::Code do
  it "highlights ruby source and injects scoped theme CSS" do
    html = described_class.new("puts 'hi'").call

    expect(html).to include("code-highlight")
    expect(html).to include("<pre>")
    expect(html).to include(".code-highlight") # the inlined Rouge theme scope
    expect(html).to include("<style>")
  end

  it "renders a title bar with the filename when given" do
    html = described_class.new("x = 1", filename: "app/models/x.rb").call

    expect(html).to include("app/models/x.rb")
    expect(html).to include("font-mono")
  end

  it "falls back to plaintext for an unknown lexer" do
    html = described_class.new("anything", lexer: :nope).call

    expect(html).to include("code-highlight")
  end

  # "All languages available" — any Rouge lexer resolves by name, no allowlist.
  %i[python go rust elixir kotlin swift java php sql json dockerfile typescript].each do |lang|
    it "resolves the #{lang} lexer from Rouge's full registry" do
      resolved = described_class.new("code", lexer: lang).send(:lexer)
      expect(resolved).to be_a(Rouge::Lexer)
      expect(resolved).not_to be_a(Rouge::Lexers::PlainText)
    end
  end

  it "resolves a configured friendly alias" do
    DocsKit.configure { |c| c.code_lexer_aliases = { fancy: "ruby" } }
    resolved = described_class.new("x", lexer: :fancy).send(:lexer)
    expect(resolved).to be_a(Rouge::Lexers::Ruby)
  end

  it "uses the configured fallback for an unknown language" do
    DocsKit.configure { |c| c.code_lexer_fallback = "ruby" }
    resolved = described_class.new("x", lexer: :totally_unknown_lang).send(:lexer)
    expect(resolved).to be_a(Rouge::Lexers::Ruby)
  end

  it "passes an explicit Rouge lexer class through" do
    resolved = described_class.new("x", lexer: Rouge::Lexers::Python).send(:lexer)
    expect(resolved).to be_a(Rouge::Lexers::Python)
  end
end
