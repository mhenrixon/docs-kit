# frozen_string_literal: true

# The lowercase authoring helpers (md/prose/example) live in DocsUI::PageHelpers
# and are mixed into DocsUI::Page. Page itself includes Phlex::Rails::Helpers::Routes
# (a live Rails view context) and cannot load in the standalone suite, so exercise
# the REAL helper module through a bare Phlex host that includes it plus the same
# DocsUI kit a Page body sees.
RSpec.describe DocsUI::PageHelpers do
  def render_body(&body)
    page_body = body
    Class.new(Phlex::HTML) do
      include DocsUI
      include DocsUI::PageHelpers

      define_method(:view_template, &page_body)
    end.new.call
  end

  describe "#prose" do
    it "renders a Prose block from a lowercase, parens-free method call" do
      html = render_body do
        prose do
          p { "Components are plain Ruby classes." }
          ul { li { "one" } }
        end
      end

      expect(html).to include("Components are plain Ruby classes.")
      expect(html).to include("<ul")
      expect(html).to include("<li>one</li>")
      # It is the Prose wrapper (its typographic child-selector classes), not a
      # bare div.
      expect(html).to include("[&_p]:my-4")
    end
  end

  describe "#example" do
    it "renders an Example (multi-language tabs) from a parens-free block" do
      html = render_body do
        # `example` here is the PageHelpers method under test, not RSpec's example.
        example do |ex| # rubocop:disable RSpec/NoExpectationExample
          ex.code(:ruby, filename: "client.rb") { "Anthropic.new" }
          ex.code(:python, filename: "client.py") { "anthropic.Client()" }
        end
      end

      expect(html).to include('data-testid="code-lang-ruby"')
      expect(html).to include('data-testid="code-lang-python"')
      expect(html.scan('data-docs-nav-target="codePanel"').size).to eq(2)
    end
  end

  describe "#md" do
    it "renders Prose-styled Markdown from a page body" do
      html = render_body { md("A **markdown** paragraph.") }

      expect(html).to include("text-base-content/80") # the Prose wrapper classes
      expect(html).to include("<strong>markdown</strong>")
    end
  end

  describe "#operation" do
    let(:yaml_path) { File.expand_path("../fixtures/openapi.yaml", __dir__) }

    before { DocsKit.configure { |c| c.openapi = yaml_path } }

    it "looks up an operation on the configured spec and renders it through the kit" do
      html = render_body { operation "createInvoice" }

      expect(html).to include(">Create an invoice<")
      expect(html).to include('id="createInvoice"')
      expect(html).to include(">POST</code>")
    end

    it "passes clients: through to the generated RequestExample" do
      html = render_body { operation "createInvoice", clients: %i[curl ruby] }

      expect(html).to include('data-testid="code-lang-curl"')
      expect(html).not_to include('data-testid="code-lang-python"')
    end

    it "yields the block so a page can append prose inside the operation section" do
      html = render_body do
        operation "createInvoice" do |op|
          op.plain "Author note."
        end
      end

      expect(html).to include("Author note.")
    end

    it "raises OperationNotFound (naming ids) for an unknown operationId" do
      expect { render_body { operation "nope" } }
        .to raise_error(DocsKit::OpenApi::OperationNotFound, /createInvoice/)
    end
  end
end
