# frozen_string_literal: true

RSpec.describe DocsUI::Code do
  it "highlights ruby source and injects scoped theme CSS" do
    html = described_class.new("puts 'hi'").call

    expect(html).to include("code-highlight")
    expect(html).to include("<pre>")
    expect(html).to include(".code-highlight") # the inlined Rouge theme scope
    expect(html).to include("<style>")
  end

  describe "the inline theme <style> under a CSP nonce" do
    context "when there is no CSP nonce (isolated render / host without a nonce)" do
      it "emits a <style> with NO nonce attribute (byte-identical to before)" do
        html = described_class.new("puts 'hi'").call

        expect(html).to include("<style>")
        expect(html).not_to include("nonce")
      end
    end

    context "when a CSP nonce is present (nonce-based style-src)" do
      it "carries the nonce on the inline <style> tag" do
        # In a real request #csp_nonce reads the request's CSP nonce off the view
        # context; here (no request) we override that seam so the nonce path is
        # exercised exactly as production would render it.
        styled = Class.new(described_class) do
          def csp_nonce = "testnonce"
        end
        html = styled.new("puts 'hi'").call

        expect(html).to include('<style nonce="testnonce">')
        expect(html).to include(".code-highlight") # still the Rouge theme CSS
      end
    end
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
