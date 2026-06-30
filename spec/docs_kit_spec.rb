# frozen_string_literal: true

RSpec.describe DocsKit do
  it "has a version" do
    expect(DocsKit::VERSION).to match(/\A\d+\.\d+\.\d+/)
  end

  describe ".configure" do
    it "yields and memoizes the configuration" do
      described_class.configure do |c|
        c.brand = "phlex-reactive"
        c.themes = %w[dark light synthwave]
      end

      expect(described_class.configuration.brand).to eq("phlex-reactive")
      expect(described_class.configuration.themes).to eq(%w[dark light synthwave])
    end

    it "defaults title_suffix to brand and default_theme to the first theme" do
      described_class.configure do |c|
        c.brand = "DaisyUI Ruby"
        c.themes = %w[night dark light]
      end

      expect(described_class.configuration.title_suffix).to eq("DaisyUI Ruby")
      expect(described_class.configuration.default_theme).to eq("night")
    end

    it "resolves nav from a callable into a Hash" do
      described_class.configure { |c| c.nav = -> { { "Docs" => { "Guide" => [1, 2] } } } }

      expect(described_class.configuration.nav_groups).to eq("Docs" => { "Guide" => [1, 2] })
    end

    it "resolves a version badge callable, nil when unset" do
      expect(described_class.configuration.version_badge_text).to be_nil

      described_class.configure { |c| c.version_badge = -> { "v1.2.3" } }
      expect(described_class.configuration.version_badge_text).to eq("v1.2.3")
    end

    it "resolves the code theme class from a string" do
      described_class.configure { |c| c.code_theme = "Rouge::Themes::Monokai" }

      expect(described_class.configuration.code_theme_class).to eq(Rouge::Themes::Monokai)
    end
  end

  describe "the Docs Phlex kit" do
    it "is a Phlex::Kit" do
      expect(Docs.singleton_class.ancestors).to include(Phlex::Kit)
    end

    it "autoloads Docs::Code as a Phlex component" do
      expect(Docs::Code.ancestors).to include(Phlex::SGML)
    end
  end
end
