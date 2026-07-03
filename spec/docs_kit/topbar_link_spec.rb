# frozen_string_literal: true

RSpec.describe DocsKit::TopbarLink do
  it "carries href/label and an optional icon" do
    link = described_class.new(href: "https://github.com/me/repo", label: "GitHub")

    expect(link.href).to eq("https://github.com/me/repo")
    expect(link.label).to eq("GitHub")
    expect(link.icon).to be_nil
  end

  it "carries a brand/lucide icon token when given" do
    expect(described_class.new(href: "/x", label: "X", icon: :github).icon).to eq(:github)
  end

  describe ".from" do
    it "returns a TopbarLink unchanged" do
      link = described_class.new(href: "/x", label: "X")

      expect(described_class.from(link)).to be(link)
    end

    it "builds one from a symbol-keyed Hash" do
      link = described_class.from(href: "https://x.com/me", label: "X", icon: :x)

      expect(link.href).to eq("https://x.com/me")
      expect(link.label).to eq("X")
      expect(link.icon).to eq(:x)
    end

    it "builds one from a string-keyed Hash (YAML/JSON-friendly)" do
      link = described_class.from("href" => "/gh", "label" => "GitHub", "icon" => "github")

      expect(link.href).to eq("/gh")
      expect(link.label).to eq("GitHub")
      expect(link.icon).to eq(:github)
    end

    it "coerces a String icon to a Symbol so :github and \"github\" resolve alike" do
      expect(described_class.from(href: "/x", label: "X", icon: "github").icon).to eq(:github)
    end

    it "leaves icon nil when omitted" do
      expect(described_class.from(href: "/x", label: "X").icon).to be_nil
    end
  end

  describe "#external?" do
    it "is true for an absolute http(s) URL" do
      expect(described_class.new(href: "https://github.com/x", label: "X")).to be_external
      expect(described_class.new(href: "http://example.com", label: "X")).to be_external
    end

    it "is false for a site-relative path" do
      expect(described_class.new(href: "/docs", label: "X")).not_to be_external
    end
  end
end
