# frozen_string_literal: true

module DocsUI
  # Lowercase, block-friendly authoring helpers mixed into DocsUI::Page. They
  # exist so the everyday page body never trips the Ruby parens-with-blocks trap:
  # a lowercase method call takes a block WITHOUT parens, so `prose do … end` is
  # unambiguously a method call (the bare `DocsUI::Prose do … end` kit form parses
  # as a constant reference — a SyntaxError). The kit forms stay valid; these are
  # the friction-free path.
  #
  # Extracted from Page so they can be unit-tested against a bare Phlex host:
  # Page itself includes Phlex::Rails::Helpers::Routes (a live Rails view context)
  # and cannot load in the standalone suite.
  module PageHelpers
    # Render a block of GFM Markdown as Prose-styled prose (see DocsUI::Markdown).
    # A lowercase method + heredoc sidesteps the parens-with-blocks gotcha:
    #   md <<~'MD'
    #     Write **prose** as Markdown. Single-quoted heredoc so #{} stays literal.
    #   MD
    def md(source)
      render DocsUI::Markdown.new(source)
    end

    # Render hand-authored prose in a DocsUI::Prose wrapper. Lowercase, so it
    # takes the block without parens: `prose do p { "…" } end`.
    def prose(&)
      render DocsUI::Prose.new(&)
    end

    # Render a multi-language code group (DocsUI::Example). Lowercase, so it takes
    # the block without parens: `example do |ex| ex.code(:ruby) { … } end`.
    def example(&)
      render DocsUI::Example.new(&)
    end

    # Render one OpenAPI operation from the configured spec as a full endpoint
    # reference (see DocsUI::OpenApiOperation) — zero hand-restatement. The
    # operation is looked up on DocsKit.configuration.openapi_document, so
    # `c.openapi` must be set; an unknown id raises OperationNotFound.
    #
    #   operation "createInvoice"                    # the whole endpoint block
    #   operation "createInvoice", clients: %i[curl ruby]  # filter the client tabs
    #   operation "createInvoice" do |op| op.plain "…" end # append prose inside it
    #
    # `id_or_method`/`path` mirror Document#operation: pass an operationId, or a
    # verb + path for a spec whose operations have no ids.
    def operation(id_or_method, path = nil, clients: nil, &)
      op = DocsKit.configuration.openapi_document.operation(id_or_method, path)
      render DocsUI::OpenApiOperation.new(op, clients: clients), &
    end
  end
end
