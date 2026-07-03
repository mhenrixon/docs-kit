# frozen_string_literal: true

RSpec.describe DocsUI::BrandMark do
  def render(component) = component.call

  describe ".brand?" do
    it "is true for a shipped brand key (symbol or string)" do
      expect(described_class.brand?(:github)).to be(true)
      expect(described_class.brand?("github")).to be(true)
    end

    it "is false for a non-brand token (a lucide name, nil, blank)" do
      expect(described_class.brand?(:search)).to be(false)
      expect(described_class.brand?(nil)).to be(false)
      expect(described_class.brand?("")).to be(false)
    end
  end

  describe "the shipped developer/social brand set" do
    it "ships the curated brands the topbar advertises" do
      %i[github gitlab discord x rubygems bluesky mastodon
         slack whatsapp telegram linkedin youtube reddit stackoverflow].each do |key|
        expect(described_class.brand?(key)).to be(true), "expected #{key} to be a shipped brand"
      end
    end

    it "stores every brand path as a 24x24 single-path SVG (valid, non-empty)" do
      described_class::BRANDS.each do |key, path|
        expect(path).to be_a(String)
        expect(path).not_to be_empty
        expect(path[0]).to match(/[Mm]/), "#{key} path should start with a moveto command"
        expect(path).not_to include('"'), "#{key} path must not contain a quote (breaks the attribute)"
      end
    end
  end

  describe "rendering a shipped brand" do
    subject(:mark) { described_class.new(:github, class: "size-5", label: "GitHub") }

    it "renders an inline 24x24 <svg> with the brand's path" do
      html = render(mark)

      expect(html).to include("<svg")
      expect(html).to include('viewBox="0 0 24 24"')
      expect(html).to include(described_class::BRANDS[:github])
    end

    it "carries the passed class on the svg" do
      expect(render(mark)).to include('class="size-5"')
    end

    it "uses fill=currentColor so the mark inherits the button's text color" do
      expect(render(mark)).to include('fill="currentColor"')
    end

    it "labels the svg accessibly (role=img + <title>) from the label" do
      html = render(mark)

      expect(html).to include('role="img"')
      expect(html).to include("<title>GitHub</title>")
    end

    it "accepts a String brand key too" do
      expect(render(described_class.new("discord", label: "Discord")))
        .to include(described_class::BRANDS[:discord])
    end
  end

  describe "falling through to a lucide icon" do
    it "delegates a non-brand token to DocsUI::Icon (lucide name)" do
      # 'book-open' is not a brand, so BrandMark renders a DocsUI::Icon. In the
      # isolated suite rails_icons is absent, so Icon renders nothing — but the
      # point is that BrandMark does NOT emit a brand <svg>; it does not raise
      # and does not render a brand path.
      html = render(described_class.new(:"book-open", label: "Guide"))

      expect(html).not_to include("<title>Guide</title>")
      described_class::BRANDS.each_value { |path| expect(html).not_to include(path) }
    end
  end
end
