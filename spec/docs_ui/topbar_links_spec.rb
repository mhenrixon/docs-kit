# frozen_string_literal: true

RSpec.describe DocsUI::TopbarLinks do
  def render(component = described_class.new) = component.call

  it "renders nothing by default (empty config → byte-identical topbar)" do
    expect(render).to eq("")
  end

  it "renders a configured GitHub link with the shipped brand mark" do
    DocsKit.configure do |c|
      c.topbar_links = [{ href: "https://github.com/me/repo", label: "GitHub", icon: :github }]
    end
    html = render

    expect(html).to include('href="https://github.com/me/repo"')
    expect(html).to include("<title>GitHub</title>")
    expect(html).to include(DocsUI::BrandMark::BRANDS[:github])
  end

  it "labels each icon-only link accessibly (aria-label from #label)" do
    DocsKit.configure do |c|
      c.topbar_links = [{ href: "https://github.com/me/repo", label: "GitHub", icon: :github }]
    end

    expect(render).to include('aria-label="GitHub"')
  end

  it "opens external links in a new tab with rel=noopener" do
    DocsKit.configure do |c|
      c.topbar_links = [{ href: "https://github.com/me/repo", label: "GitHub", icon: :github }]
    end
    html = render

    expect(html).to include('target="_blank"')
    expect(html).to include("noopener")
  end

  it "does NOT add target/rel to a site-relative link" do
    DocsKit.configure do |c|
      c.topbar_links = [{ href: "/changelog", label: "Changelog", icon: "history" }]
    end
    html = render

    expect(html).to include('href="/changelog"')
    expect(html).not_to include('target="_blank"')
  end

  it "renders the label as text when a link has no icon (never an empty button)" do
    DocsKit.configure do |c|
      c.topbar_links = [{ href: "https://example.com", label: "Blog" }]
    end
    html = render

    expect(html).to include('href="https://example.com"')
    expect(html).to include("Blog")
    # No brand <svg> when there's no icon.
    expect(html).not_to include("<svg")
  end

  it "renders links in declaration order" do
    DocsKit.configure do |c|
      c.topbar_links = [
        { href: "https://github.com/me/repo", label: "GitHub",  icon: :github },
        { href: "https://discord.gg/abc",     label: "Discord", icon: :discord }
      ]
    end
    html = render

    expect(html.index("GitHub")).to be < html.index("Discord")
  end
end
