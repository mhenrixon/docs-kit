# frozen_string_literal: true

module Views
  module Docs
    module Pages
      # The OpenAPI bridge: point `c.openapi` at a spec and render a whole
      # endpoint with one `operation "id"` call — badge, tables, request tabs, and
      # response, all derived from the spec. This page documents the bridge AND
      # renders three real operations from docs/openapi.yaml, live.
      class OpenApi < DocsUI::Page
        title "OpenAPI bridge"
        eyebrow "Authoring"

        def lead
          "If you already maintain an OpenAPI spec, don't restate it. Point c.openapi " \
            "at the file and one line renders the whole endpoint — method, path, " \
            "fields, errors, request tabs, and response — derived from the spec."
        end

        def content
          overview_section
          setup_section
          mapping_section
          live_create_section
          live_get_section
          live_list_section
          lookup_section
        end

        private

        def overview_section
          DocsUI::Section("Zero hand-restatement",
                          description: "One operation call → a full endpoint reference, composed from the kit.") do
            md <<~'MD'
              An API-reference page normally restates every method, path, field,
              and response that your `openapi.yaml` already describes — and a field
              rename means editing both. The **OpenAPI bridge** closes that gap: a
              single `operation "operationId"` reads the spec and renders the whole
              endpoint through the same kit the [API reference](/docs/api) page
              composes by hand — a `DocsUI::Endpoint` badge, `FieldTable`s,
              an `ErrorTable`, a `RequestExample` (or your `x-codeSamples`), and a
              `JsonResponse`.

              Because it's composed from the kit, the `.md` twin, `llms.txt`,
              search, and MCP surfaces all derive from it for free.
            MD
          end
        end

        def setup_section
          DocsUI::Section("Point c.openapi at your spec",
                          description: "A path (.json ⇒ JSON, else YAML) or an already-parsed Hash. nil by default.") do
            DocsUI::Code(<<~RUBY, filename: "config/initializers/docs_kit.rb")
              DocsKit.configure do |c|
                c.openapi = Rails.root.join("openapi.yaml")
              end
            RUBY

            md <<~'MD'
              Then, in any page's `#content`, render an operation by its
              `operationId`:
            MD

            DocsUI::Code(<<~RUBY, filename: "app/views/docs/pages/invoices.rb")
              def content
                operation "createInvoice"
              end
            RUBY

            DocsUI::Callout(:tip) do
              plain "The document is memoized and reloads when the file's mtime changes, so editing "
              code { "openapi.yaml" }
              plain " in development shows up without a server restart."
            end
          end
        end

        def mapping_section
          DocsUI::Section("What one operation expands to",
                          description: "Each part of the operation maps to one kit component.") do
            render DocsUI::Table.new(
              ["Spec source", "Renders as"],
              [
                ["operationId + summary + method/path", [:md, "the Section title + a `DocsUI::Endpoint` badge"]],
                ["description", "Markdown prose"],
                ["parameters (query/path)", [:md, "a `DocsUI::FieldTable`"]],
                ["requestBody schema ($ref, allOf, nested)", [:md, "a `FieldTable` (nested names dotted: `customer.id`)"]],
                ["4xx / 5xx responses", [:md, "a `DocsUI::ErrorTable` (error `type` from a response example)"]],
                ["x-codeSamples", [:md, "`DocsUI::Example` tabs (a lone sample → a plain `Code`)"]],
                ["no code samples", [:md, "a generated `DocsUI::RequestExample`"]],
                ["first 2xx example", [:md, "a `DocsUI::JsonResponse`"]]
              ]
            )
          end
        end

        def live_create_section
          DocsUI::Section("Live: createInvoice",
                          description: "Rendered from docs/openapi.yaml — request body, errors, tabs, and response.") do
            md <<~'MD'
              The section below is produced by a single call — `operation
              "createInvoice"`. Nothing here is hand-written:
            MD

            operation "createInvoice"
          end
        end

        def live_get_section
          DocsUI::Section("Live: getInvoice (with x-codeSamples)",
                          description: "This operation ships x-codeSamples, so they replace the generated tabs.") do
            md <<~'MD'
              `getInvoice` carries `x-codeSamples` (a Ruby SDK tab and a CLI tab) in
              the spec, so the bridge renders those instead of the generic
              curl/JS/Ruby/Python snippets — and substitutes the `id` parameter's
              example into the path:
            MD

            operation "getInvoice"
          end
        end

        def live_list_section
          DocsUI::Section("Live: listInvoices (filter the tabs)",
                          description: "A GET with query parameters; here we keep just the curl and Ruby tabs.") do
            md <<~'MD'
              Pass `clients:` to filter and order the generated client tabs — here
              `clients: %i[curl ruby]`:
            MD

            operation "listInvoices", clients: %i[curl ruby]
          end
        end

        def lookup_section
          DocsUI::Section("Lookup, prose, and errors",
                          description: "By id or verb+path; append prose with a block; unknown ids raise.") do
            DocsUI::Code(<<~RUBY)
              operation :delete, "/v1/invoices/{id}"            # verb + path (id-less specs)
              operation "createInvoice", clients: %i[curl ruby] # only these tabs
              operation "createInvoice" do |op|                 # append prose in the section
                op.md("Idempotency keys are honored for 24 hours.")
              end
            RUBY

            DocsUI::Callout(:warning) do
              plain "An unknown "
              code { "operationId" }
              plain " raises "
              code { "DocsKit::OpenApi::OperationNotFound" }
              plain " (naming the available ids); an external/remote "
              code { "$ref" }
              plain " raises "
              code { "DocsKit::OpenApi::UnsupportedRef" }
              plain ". Authoring or validating the spec itself is out of scope — bring your own."
            end
          end
        end
      end
    end
  end
end
