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

    it "slugifies the brand into a nav_storage_key, overridable" do
      described_class.configure { |c| c.brand = "DaisyUI Ruby" }
      expect(described_class.configuration.nav_storage_key).to eq("daisyui-ruby")

      described_class.configure { |c| c.nav_storage_key = "custom" }
      expect(described_class.configuration.nav_storage_key).to eq("custom")
    end

    describe "on_page (auto-TOC) mode" do
      it "defaults to :panel" do
        expect(described_class.configuration.on_page_default).to eq(:panel)
      end

      it "accepts any of the three modes as the default" do
        %i[panel toggle sidebar].each do |mode|
          described_class.configure { |c| c.on_page_default = mode }
          expect(described_class.configuration.on_page_default).to eq(mode)
        end
      end

      it "treats false as no auto-TOC" do
        described_class.configure { |c| c.on_page_default = false }
        expect(described_class.configuration.on_page_default).to be(false)
      end

      it "normalizes a per-page override: true -> the default, a mode -> itself, false -> false" do
        described_class.configure { |c| c.on_page_default = :sidebar }
        config = described_class.configuration

        expect(config.normalize_on_page(true)).to eq(:sidebar)
        expect(config.normalize_on_page(:toggle)).to eq(:toggle)
        expect(config.normalize_on_page(false)).to be(false)
        expect(config.normalize_on_page(nil)).to be(false)
      end

      it "rejects an unknown mode" do
        config = described_class.configuration
        expect { config.normalize_on_page(:bogus) }.to raise_error(ArgumentError, /on_page must be one of/)
      end
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

  describe "the DocsUI Phlex kit" do
    it "is a Phlex::Kit" do
      expect(DocsUI.singleton_class.ancestors).to include(Phlex::Kit)
    end

    it "autoloads DocsUI::Code as a Phlex component" do
      expect(DocsUI::Code.ancestors).to include(Phlex::SGML)
    end
  end
end
