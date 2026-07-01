# frozen_string_literal: true

RSpec.describe DocsUI::Example do
  def render_group(&)
    described_class.new.call(&)
  end

  it "renders a tab and a panel per language" do
    html = render_group do |ex|
      ex.code(:ruby, filename: "client.rb") { "Anthropic.new" }
      ex.code(:python, filename: "client.py") { "anthropic.Client()" }
    end

    expect(html.scan('data-testid="code-lang-ruby"').size).to eq(1)
    expect(html.scan('data-testid="code-lang-python"').size).to eq(1)
    expect(html.scan('data-docs-nav-target="codePanel"').size).to eq(2)
    expect(html).to include(">Ruby<").and include(">Python<")
  end

  it "wires each tab to the selectLanguage action with a lang param" do
    html = render_group do |ex|
      ex.code(:ruby) { "1" }
      ex.code(:javascript) { "1" }
    end

    expect(html).to include('data-action="docs-nav#selectLanguage"')
    expect(html).to include('data-docs-nav-lang-param="ruby"')
    expect(html).to include('data-docs-nav-lang-param="javascript"')
    expect(html).to include('data-lang="ruby"') # panel carries the language
  end

  it "degrades to a plain code block (no tabs) for a single language" do
    html = render_group { |ex| ex.code(:ruby) { "puts 1" } }

    expect(html).to include("code-highlight")
    expect(html).not_to include("code-lang-")
    expect(html).not_to include("tablist")
  end

  it "renders nothing when no snippets are added" do
    html = described_class.new.call { |ex| ex } # no ex.code calls
    expect(html).to eq("")
  end

  it "humanizes an unknown language token for the tab label" do
    html = render_group do |ex|
      ex.code(:ruby) { "1" }
      ex.code(:elixir) { "1" }
    end

    expect(html).to include(">Elixir<")
  end

  it "maps friendly language tokens to a real Rouge lexer" do
    # :curl isn't a Rouge lexer; it must not blow up (falls back to shell).
    html = render_group do |ex|
      ex.code(:curl) { "curl https://api" }
      ex.code(:ruby) { "1" }
    end

    expect(html).to include(">cURL<")
    expect(html).to include("code-highlight")
  end
end
