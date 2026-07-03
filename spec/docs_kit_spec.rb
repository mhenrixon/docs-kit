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

  # The RuboCop cops live under lib/rubocop/cop/docs_kit/ — OUTSIDE the gem's
  # zeitwerk push_dirs (lib/docs_kit + app/components/docs_ui) — and the cop
  # entry point lib/docs_kit/rubocop.rb defines RuboCop::Cop::DocsKit::*, not a
  # DocsKit::Rubocop constant, so it is explicitly ignored. The gem's loader
  # must therefore never try to autoload them (which would raise a Zeitwerk
  # NameError the moment the const was referenced).
  describe "the shipped RuboCop cops" do
    let(:loader) do
      found = nil
      Zeitwerk::Registry.loaders.each { |l| found = l if l.tag == "docs_kit" }
      found
    end

    it "boots the gem's zeitwerk loader" do
      expect(loader).not_to be_nil
    end

    it "does not register a DocsKit::Rubocop autoload for the cop entry point" do
      # If lib/docs_kit/rubocop.rb were NOT ignored, zeitwerk would set an
      # autoload for DocsKit::Rubocop and raise a NameError (mismatched constant)
      # the instant it was referenced. Ignored => plain uninitialized constant.
      expect(described_class.autoload?(:Rubocop)).to be_nil
      expect { DocsKit::Rubocop }.to raise_error(NameError)
      expect(described_class.const_defined?(:Rubocop, false)).to be(false)
    end

    it "loads the cops under the RuboCop namespace when the entry point is required" do
      require "docs_kit/rubocop"

      expect(RuboCop::Cop::DocsKit::RenderComponentPreferred.ancestors).to include(RuboCop::Cop::Base)
      expect(RuboCop::Cop::DocsKit::EscapedInterpolationInHeredoc.ancestors).to include(RuboCop::Cop::Base)
    end
  end
end
