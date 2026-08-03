# frozen_string_literal: true

RSpec.describe DocsUI::Landing do
  # The doc index reads only DocsKit.configuration.nav_groups (no Rails request),
  # so — like sidebar_spec's header-only render — exercise just that fragment
  # through a tiny subclass instead of composing the whole Shell.
  let(:index_only) do
    Class.new(described_class) do
      def view_template = doc_index
    end
  end

  def nav_item(href, label)
    DocsKit::NavItem.new(href: href, label: label)
  end

  describe "the doc index with a single heading" do
    before do
      DocsKit.configure do |c|
        c.nav = lambda {
          { "Documentation" => {
            "Getting started" => [nav_item("/docs/overview", "Overview")],
            "REST API" => [nav_item("/docs/accounts", "Accounts")]
          } }
        }
      end
    end

    it "renders the section heading once, with no duplicate per-group label" do
      html = index_only.new.call

      expect(html.scan("Documentation").count).to eq(1)
      expect(html).not_to include("<h3")
    end

    it "still links every page" do
      html = index_only.new.call

      expect(html).to include('href="/docs/overview"').and include('href="/docs/accounts"')
    end
  end

  describe "the doc index with multiple headings" do
    before do
      DocsKit.configure do |c|
        c.nav = lambda {
          {
            "Docs" => { "Guide" => [nav_item("/docs/install", "Installation")] },
            "Demos" => { "Examples" => [nav_item("/demos/counter", "Counter")] }
          }
        }
      end
    end

    it "labels each column with its heading" do
      html = index_only.new.call

      expect(html).to match(%r{<h3[^>]*>Docs</h3>})
      expect(html).to match(%r{<h3[^>]*>Demos</h3>})
    end
  end
end
