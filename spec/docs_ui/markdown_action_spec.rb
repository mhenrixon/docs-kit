# frozen_string_literal: true

RSpec.describe DocsUI::MarkdownAction do
  def render_action(path)
    described_class.new(path).call
  end

  it "renders a link to the page's .md twin" do
    html = render_action("/docs/installation")

    expect(html).to include('href="/docs/installation.md"')
  end

  it "keeps an existing query string but points the path at .md" do
    html = render_action("/docs/installation?x=1")

    expect(html).to include('href="/docs/installation.md?x=1"')
  end

  it "does not double-append .md when the path already ends in .md" do
    html = render_action("/docs/installation.md")

    expect(html).to include('href="/docs/installation.md"')
    expect(html).not_to include(".md.md")
  end

  # JS-OFF: the plain link opens the raw Markdown. JS-ON: docs-nav enhances the
  # click into copy-to-clipboard (a target + action on the ONE controller).
  it "wires the docs-nav copy enhancement (target + action) so the one controller can enhance it" do
    html = render_action("/docs/x")

    expect(html).to include('data-docs-nav-target="markdownLink"')
    expect(html).to include("docs-nav#copyMarkdown")
  end

  it "labels the affordance 'Markdown'" do
    html = render_action("/docs/x")

    expect(html).to include("Markdown")
  end
end
