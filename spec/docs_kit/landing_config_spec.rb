# frozen_string_literal: true

RSpec.describe DocsKit::LandingConfig do
  subject(:landing) { described_class.new }

  describe "defaults" do
    it "shows the doc index by default" do
      expect(landing.doc_index?).to be(true)
    end

    it "has no ctas, features, or install snippet" do
      expect(landing.ctas).to eq([])
      expect(landing.features).to eq([])
      expect(landing.install_snippet).to be_nil
    end
  end

  describe "#doc_index?" do
    it "is false only when explicitly disabled" do
      landing.doc_index = false
      expect(landing.doc_index?).to be(false)
    end

    it "stays true for any non-false value" do
      landing.doc_index = nil
      expect(landing.doc_index?).to be(true)
    end
  end

  describe "#features" do
    it "normalizes Hashes into Feature value objects" do
      landing.features = [{ icon: "zap", title: "Fast", body: "Very." }]

      feature = landing.features.first
      expect(feature).to be_a(described_class::Feature)
      expect(feature.icon).to eq("zap")
      expect(feature.title).to eq("Fast")
      expect(feature.body).to eq("Very.")
    end

    it "accepts a title-only feature (icon/body optional)" do
      landing.features = [{ title: "Simple" }]

      feature = landing.features.first
      expect(feature.title).to eq("Simple")
      expect(feature.icon).to be_nil
      expect(feature.body).to be_nil
    end

    it "passes an existing Feature through unchanged" do
      feature = described_class::Feature.new(icon: "x", title: "T", body: "B")
      landing.features = [feature]

      expect(landing.features.first).to equal(feature)
    end
  end

  describe "#ctas" do
    it "normalizes Hashes into Cta value objects with a default ghost style" do
      landing.ctas = [{ label: "GitHub", href: "https://github.com/x" }]

      cta = landing.ctas.first
      expect(cta).to be_a(described_class::Cta)
      expect(cta.label).to eq("GitHub")
      expect(cta.style).to eq(:ghost)
    end

    describe "Cta#btn_class" do
      it "maps :primary to btn-primary" do
        cta = described_class::Cta.new(label: "Go", href: "/x", style: :primary)
        expect(cta.btn_class).to eq("btn btn-primary")
      end

      it "maps any other style to btn-ghost" do
        cta = described_class::Cta.new(label: "Go", href: "/x", style: :ghost)
        expect(cta.btn_class).to eq("btn btn-ghost")
      end
    end

    describe "Cta#external?" do
      it "is true for an absolute http(s) href" do
        expect(described_class::Cta.new(label: "x", href: "https://a.com").external?).to be(true)
      end

      it "is false for a site-relative href" do
        expect(described_class::Cta.new(label: "x", href: "/docs/overview").external?).to be(false)
      end
    end
  end

  describe "#install_snippet" do
    it "normalizes the install Hash with a default :shell lexer" do
      landing.install = { code: 'gem "x"', filename: "Gemfile" }

      expect(landing.install_snippet).to eq(code: 'gem "x"', filename: "Gemfile", lexer: :shell)
    end

    it "honors an explicit lexer" do
      landing.install = { code: "print()", lexer: :python }

      expect(landing.install_snippet[:lexer]).to eq(:python)
    end

    it "is nil when unset" do
      expect(landing.install_snippet).to be_nil
    end
  end

  describe "#hero_logo" do
    it "is nil when unset" do
      expect(landing.hero_logo).to be_nil
    end

    it "normalizes an inline SVG-mark Hash into an inline Logo" do
      landing.logo = { svg: "M1 1H2Z", viewbox: "0 0 10 10", label: "Acme" }

      logo = landing.hero_logo
      expect(logo).to be_a(described_class::Logo)
      expect(logo).to be_inline
      expect(logo.svg).to eq("M1 1H2Z")
      expect(logo.viewbox).to eq("0 0 10 10")
      expect(logo.label).to eq("Acme")
    end

    it "normalizes an image Hash into a non-inline Logo" do
      landing.logo = { src: "logo.svg", alt: "Acme" }

      logo = landing.hero_logo
      expect(logo).not_to be_inline
      expect(logo.src).to eq("logo.svg")
      expect(logo.alt).to eq("Acme")
    end

    it "defaults the viewbox to a 24×24 box" do
      landing.logo = { svg: "M0 0Z" }

      expect(landing.hero_logo.viewbox).to eq("0 0 24 24")
    end
  end
end
