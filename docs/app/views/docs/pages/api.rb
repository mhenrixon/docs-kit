# frozen_string_literal: true

module Views
  module Docs
    module Pages
      # How to build an API-reference page from the kit: an Endpoint line, a
      # FieldTable / ErrorTable, one RequestExample that fans out to every client
      # tab, and a JsonResponse — driven by three config knobs, shown live.
      class Api < DocsUI::Page
        title "API reference"
        eyebrow "Authoring"

        def lead = "Declare an endpoint once — method, path, fields, one request — and the kit renders the badge, the tables, and a code tab per client. Base URL, auth, and the client set are config."

        def content
          overview_section
          endpoint_section
          field_error_section
          request_example_section
          config_section
          clients_section
          live_section
        end

        private

        def overview_section
          DocsUI::Section("The API-reference kit",
                          description: "Six components compose a full endpoint reference — no hand-rolled badges or per-language heredocs.") do
            md <<~'MD'
              An API-reference page is the same page you'd write for anything else
              — a Phlex class of `DocsUI::Section`s (see [Authoring
              pages](/docs/authoring)). What's different is the vocabulary you
              reach for inside `#content`:

              - `DocsUI::Endpoint` — a verb badge + monospace path, inline;
              - `DocsUI::FieldTable` / `DocsUI::ErrorTable` — schema-driven tables;
              - `DocsUI::RequestExample` — one request declaration → one code tab
                per client;
              - `DocsUI::JsonResponse` — a Ruby Hash rendered as pretty JSON.

              Three config knobs — `api_base_url`, `api_auth_header`,
              `api_clients` — feed every `RequestExample`, so a snippet is
              authored once and points at the right host with the right auth. The
              [Components](/docs/components) reference lists every arg; this page
              walks the workflow.
            MD
          end
        end

        def endpoint_section
          DocsUI::Section("Endpoint — the method + path line",
                          description: "A colour-coded verb badge and a monospace path, rendered inline.") do
            md <<~'MD'
              `DocsUI::Endpoint.new(method, path)` renders an HTTP method badge
              coloured per verb — `GET` success, `POST` primary, `PUT`/`PATCH`
              warning, `DELETE` error, anything else neutral — followed by the
              path in a `<code>`. It renders **inline** (no wrapper), on purpose:
              drop it straight into a `Section`'s `description:`.
            MD

            DocsUI::Code(<<~RUBY)
              DocsUI::Section("List customers",
                description: DocsUI::Endpoint.new(:get, "/v1/customers")) do
                # fields, request example, response…
              end
            RUBY

            prose { p { "The badge live, for each verb:" } }
            div(class: "flex flex-wrap gap-4 not-prose") do
              render DocsUI::Endpoint.new(:get, "/v1/customers")
              render DocsUI::Endpoint.new(:post, "/v1/customers")
              render DocsUI::Endpoint.new(:patch, "/v1/customers/:id")
              render DocsUI::Endpoint.new(:delete, "/v1/customers/:id")
            end

            DocsUI::Callout(:note) do
              plain "The verb → badge map is a frozen Hash of "
              strong { "literal" }
              plain " class strings so Tailwind's Ruby scan generates each colour — never interpolate them. The path is Phlex-escaped, and an unknown verb (e.g. "
              code { ":trace" }
              plain ") degrades to a neutral badge rather than raising."
            end
          end
        end

        def field_error_section
          DocsUI::Section("FieldTable & ErrorTable — the schemas",
                          description: "Keyword-schema presets over DocsUI::Table for request fields and endpoint errors.") do
            md <<~'MD'
              `DocsUI::FieldTable` takes an Array of field Hashes and renders
              **Name / Type / Required / Description**. `name` is auto
              code-styled, `required:` defaults to `false` (a `✓` when true, the
              canonical `—` when not), and the description cell follows
              `DocsUI::Table`'s convention — a plain `String` is escaped text,
              `[:code, "x"]` is inline code, `[:md, "…"]` is inline Markdown.
            MD

            DocsUI::Code(<<~RUBY)
              render DocsUI::FieldTable.new([
                { name: "email", type: "string", required: true,
                  description: "The customer's email address." },
                { name: "metadata", type: "object",
                  description: [:md, "Up to 50 keys, e.g. `plan: pro`."] }
              ])
            RUBY

            md <<~'MD'
              `DocsUI::ErrorTable` renders **Scenario / Status / Type** — plus a
              **Param** column, but only when at least one error names a `param:`.
              An endpoint whose errors are all param-free renders a clean
              three-column table; when the column IS shown, a param-free row gets
              the em-dash. `type` and `param` are auto code-styled.
            MD

            DocsUI::Code(<<~RUBY)
              render DocsUI::ErrorTable.new([
                { scenario: "Missing or invalid API key", status: "401",
                  type: "authentication_error" },
                { scenario: "Email already taken", status: "422",
                  type: "validation_error", param: "email" }
              ])
            RUBY

            DocsUI::Callout(:tip) do
              plain "The "
              code { "—" }
              plain " placeholder is the kit's ONE canonical \"no value\" glyph (an em-dash, never an ASCII hyphen) — both tables share it, so a page never types a stray "
              code { "-" }
              plain "."
            end
          end
        end

        def request_example_section
          DocsUI::Section("RequestExample — one declaration, every client",
                          description: "Declare method/path/body once; get a syntax-highlighted tab per configured client.") do
            md <<~'MD'
              `DocsUI::RequestExample` is the payoff. Declare the request once and
              it renders one code tab per configured client — `curl`,
              `javascript`, `ruby`, `python` by default — wrapped in a
              `DocsUI::Example`, so the reader's sticky global language choice
              persists across every endpoint on the site.
            MD

            DocsUI::Code(<<~RUBY)
              render DocsUI::RequestExample.new(
                method: :post,
                path: "/v1/customers",
                body: { email: "ada@example.com", name: "Ada Lovelace" }
              )
            RUBY

            md <<~'MD'
              Under the hood each tab is fed a `DocsKit::ApiRequest` — an immutable
              value object carrying `method`/`path`/`url`/`query`/`headers`/`body`
              with display helpers (`#http_method`, `#body?`,
              `#pretty_body_json`, `#url_with_query`). Every shipped template
              guards its payload lines on `#body?`, so a body-less GET emits no
              dangling `-d` / `json=` / `request.body =` line.
            MD

            render DocsUI::PropTable.new(
              [
                [ "method: / path:", "Symbol/String, String", "—", "The verb and path; path is appended to c.api_base_url." ],
                [ "body:", "Hash, String, nil", "nil", "Payload — deep-stringified into each snippet. Omit for a GET." ],
                [ "query:", "Hash", "{}", "Query params, URL-encoded onto every snippet's URL." ],
                [ "headers:", "Hash", "{}", "Extra headers, merged over the config auth header (explicit wins)." ],
                [ "clients:", "Array<Symbol>, nil", "all configured", "Filter AND order the tabs, e.g. %i[curl ruby]." ]
              ]
            )

            DocsUI::Callout(:warning) do
              plain "A "
              strong { "lone" }
              plain " client renders no tabs — "
              code { "DocsUI::Example" }
              plain " needs at least two. When demoing one custom client, pair it (e.g. "
              code { "clients: %i[cli curl]" }
              plain "). An unknown token in "
              code { "clients:" }
              plain " is silently skipped — a typo yields fewer tabs, never a raise."
            end
          end
        end

        def config_section
          DocsUI::Section("Configure the base URL & auth",
                          description: "Two knobs point every snippet at your real host with a real auth line.") do
            md <<~'MD'
              `RequestExample` reads three config knobs. Set them once in the
              initializer (see [Configuration](/docs/configuration)) and every
              endpoint inherits them.

              - `c.api_base_url` — prefixed onto every `path:`. Defaults to the
                neutral `https://api.example.com`.
              - `c.api_auth_header` — an example `Authorization` line merged into
                every snippet. Defaults to `nil` → no auth line (clean snippets
                for a no-auth API). It's split on the first colon into a
                `{ name => value }` header, merged **under** any explicit
                `headers:` you pass (so your explicit header wins).
              - `c.api_clients` — override or extend the tab set (next section).
            MD

            DocsUI::Code(<<~RUBY, filename: "config/initializers/docs_kit.rb")
              DocsKit.configure do |c|
                c.api_base_url    = "https://api.acme.com"
                c.api_auth_header = "Authorization: Bearer sk_live_..."
              end
            RUBY

            render DocsUI::PropTable.new(
              [
                [ "c.api_base_url", "String", '"https://api.example.com"', "Host prefixed onto every RequestExample path." ],
                [ "c.api_auth_header", "String, nil", "nil", "Example Authorization line merged into every snippet." ],
                [ "c.api_clients", "Hash", "{}", "Overrides/extensions merged over the four defaults (writer only)." ]
              ]
            )
          end
        end

        def clients_section
          DocsUI::Section("Custom clients — SDK-flavored tabs",
                          description: "Replace a default tab with an SDK snippet, or append your own (a cli tab).") do
            md <<~'MD'
              The gem ships **generic HTTP** snippets because it can't know your
              SDK. A `DocsKit::ApiClient` describes one tab — a `label`, a Rouge
              `lexer`, an optional `filename` (a String or a `(request) -> String`
              proc), and a `template`: a `(DocsKit::ApiRequest) -> String`
              callable that renders the snippet.

              Set `c.api_clients` to a `{ token => ApiClient }` Hash. It merges
              **over** the four defaults (`curl`, `javascript`, `ruby`,
              `python`): reusing a default token **replaces** that tab with an
              SDK-flavored one; a new token **appends** a tab. Hash merge preserves
              order — reused tokens keep their slot, new ones append in
              declaration order.
            MD

            DocsUI::Code(<<~'RUBY', filename: "config/initializers/docs_kit.rb")
              DocsKit.configure do |c|
                c.api_clients = {
                  # Replace the generic Ruby tab with the SDK flavour:
                  ruby: DocsKit::ApiClient.new(
                    label: "Ruby", lexer: :ruby, filename: "acme.rb",
                    template: ->(req) { %(Acme.#{req.http_method.downcase}("#{req.path}")) }
                  ),
                  # Append a brand-new CLI tab:
                  cli: DocsKit::ApiClient.new(
                    label: "Acme CLI", lexer: :shell, filename: "cli.sh",
                    template: ->(req) { "acme #{req.http_method.downcase} #{req.path}" }
                  )
                }
              end
            RUBY

            DocsUI::Callout(:note) do
              plain "Read the effective map via "
              code { "DocsKit.configuration.api_clients" }
              plain " (which merges over the defaults), never the raw ivar. Because it merges, setting one "
              code { "cli:" }
              plain " client yields FIVE tabs, not one. Config can't "
              strong { "remove" }
              plain " a default tab — use "
              code { "RequestExample" }
              plain "'s "
              code { "clients:" }
              plain " to select a subset."
            end
          end
        end

        def live_section
          DocsUI::Section("A full endpoint, live",
                          description: DocsUI::Endpoint.new(:post, "/v1/customers")) do
            md <<~'MD'
              Everything above, composed — an `Endpoint` description, a
              `FieldTable`, an `ErrorTable`, a `RequestExample` (four real client
              tabs, on THIS site's config), and a `JsonResponse`. This is the real
              kit rendering, not a screenshot:
            MD

            render DocsUI::FieldTable.new(
              [
                { name: "email", type: "string", required: true, description: "The customer's email address." },
                { name: "name", type: "string", description: "The customer's full name." },
                { name: "metadata", type: "object", description: [ :md, "Up to 50 key/value pairs, e.g. `plan: pro`." ] }
              ]
            )

            render DocsUI::ErrorTable.new(
              [
                { scenario: "Missing or invalid API key", status: "401", type: "authentication_error" },
                { scenario: "Email already registered", status: "422", type: "validation_error", param: "email" }
              ]
            )

            prose { p { "Try it — one declaration renders every client tab:" } }
            render DocsUI::RequestExample.new(
              method: :post,
              path: "/v1/customers",
              body: { email: "ada@example.com", name: "Ada Lovelace", metadata: { plan: "pro" } }
            )

            prose { p { "A successful response:" } }
            render DocsUI::JsonResponse.new(
              {
                id: "cus_1a2b3c",
                object: "customer",
                email: "ada@example.com",
                name: "Ada Lovelace",
                metadata: { plan: "pro" },
                created: 1_720_000_000
              }
            )

            prose { p { "The calls that produced the block above:" } }
            DocsUI::Code(<<~RUBY)
              DocsUI::Section("Create a customer",
                description: DocsUI::Endpoint.new(:post, "/v1/customers")) do
                render DocsUI::FieldTable.new([
                  { name: "email", type: "string", required: true,
                    description: "The customer's email address." }
                ])
                render DocsUI::ErrorTable.new([
                  { scenario: "Email already registered", status: "422",
                    type: "validation_error", param: "email" }
                ])
                render DocsUI::RequestExample.new(
                  method: :post, path: "/v1/customers",
                  body: { email: "ada@example.com", name: "Ada Lovelace" }
                )
                render DocsUI::JsonResponse.new(
                  { id: "cus_1a2b3c", object: "customer", email: "ada@example.com" }
                )
              end
            RUBY

            DocsUI::Callout(:tip) do
              plain "See the "
              a(href: "/docs/components") { "Components" }
              plain " reference for every arg of every kit component, and "
              a(href: "/docs/markdown") { "Markdown authoring" }
              plain " for the "
              code { "md" }
              plain " prose used throughout this page."
            end
          end
        end
      end
    end
  end
end
