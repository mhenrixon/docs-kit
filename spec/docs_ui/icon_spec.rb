# frozen_string_literal: true

RSpec.describe DocsUI::Icon do
  describe "#rails_icons_library" do
    subject(:library) { described_class.new("search").send(:rails_icons_library) }

    it "defaults to the configured icon_library (lucide out of the box)" do
      expect(library).to eq("lucide")
    end

    it "returns the site's configured icon_library when set" do
      DocsKit.configure { |c| c.icon_library = "phosphor" }

      # The `||` short-circuits on a set icon_library, so this never touches
      # RailsIcons — a non-lucide host app can pin the chrome to any library.
      expect(library).to eq("phosphor")
    end

    context "when icon_library is nil (falls back to the host RailsIcons default)" do
      before { DocsKit.configure { |c| c.icon_library = nil } }

      it "reads RailsIcons.configuration.default_library when RailsIcons is present" do
        rails_icons = Module.new
        config = Struct.new(:default_library).new("heroicons")
        rails_icons.define_singleton_method(:configuration) { config }
        stub_const("RailsIcons", rails_icons)

        expect(library).to eq("heroicons")
      end

      it "degrades to nil when RailsIcons is not loaded (isolated / non-Rails host)" do
        # RailsIcons is a Railtie gem, absent from this isolated suite; the
        # rescue in #rails_icons_library swallows the NameError → nil.
        expect(library).to be_nil
      end
    end
  end
end
