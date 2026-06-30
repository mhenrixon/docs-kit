# frozen_string_literal: true

RSpec.describe Docs::Code do
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
end
