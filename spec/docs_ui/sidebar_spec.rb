# frozen_string_literal: true

RSpec.describe DocsUI::Sidebar do
  # The brand header reads only DocsKit.configuration (no Rails request), so — like
  # shell_spec's topbar-only render — we exercise just that fragment through a tiny
  # subclass whose view_template renders only the header section.
  let(:header_only) do
    Class.new(described_class) do
      def view_template = header_section
    end
  end

  describe "the brand link" do
    it "defaults the brand href to \"/\"" do
      html = header_only.new.call

      expect(html).to include('href="/"')
    end

    it "follows config.brand_href when a site overrides it" do
      DocsKit.configure { |c| c.brand_href = "/docs" }
      html = header_only.new.call

      expect(html).to include('href="/docs"')
    end
  end
end
