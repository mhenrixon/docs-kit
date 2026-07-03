# frozen_string_literal: true

module Views
  module Docs
    module Pages
      # Everything that makes a docs-kit site machine-readable: the automatic
      # `.md` twin per page (+ the "Markdown" masthead action), /llms.txt and
      # /llms-full.txt, and the built-in read-only MCP server. All derived from
      # the SAME render the HTML pages use — the author writes nothing extra.
      class Ai < DocsUI::Page
        title "AI & agents"
        eyebrow "AI & tooling"

        def lead = "Every page is machine-readable for free — a Markdown twin, an llms.txt index, and a read-only MCP endpoint, all built from the same render your readers see."

        def content
          overview_section
          md_twin_section
          markdown_action_section
          llms_section
          mcp_section
          agents_section
        end

        private

        def overview_section
          DocsUI::Section("Machine-readable, for free",
                          description: "Four surfaces, one render — the .md twin, llms.txt, llms-full.txt, and MCP all read from the page you already wrote.") do
            md <<~'MD'
              docs-kit derives its agent-facing surfaces from the **same render**
              the HTML pages use — so they never drift and you author nothing
              extra:

              - **The `.md` twin** — every page has a GFM Markdown copy at
                `GET /docs/x.md`, converted post-render from the page's own HTML.
                This page's twin is [/docs/ai.md](/docs/ai.md).
              - **The "Markdown" action** — the masthead button that copies (or
                opens) the current page's twin.
              - **[/llms.txt](/llms.txt) + [/llms-full.txt](/llms-full.txt)** — the
                llmstxt.org index and the full-text concatenation, built straight
                from the registry.
              - **The MCP endpoint** — an optional read-only `POST /mcp` server
                exposing `list_pages` / `get_page` / `search_docs`.

              None of it is a second source of truth. The `.md` twin is a
              conversion of the rendered `#docs-content`; llms.txt is the registry;
              MCP reads the same twins and the same [search](/docs/search) index.
            MD
          end
        end

        def md_twin_section
          DocsUI::Section("The .md twin",
                          description: "GET /docs/x.md returns faithful Markdown of exactly what /docs/x shows.") do
            md <<~'MD'
              A controller that includes `DocsKit::Controller` gets the twin
              automatically: `render_page(view)` serves the page's GFM Markdown
              instead of HTML when the request format is `.md` (or `.text` as an
              alias). Same page class, same render, `text/markdown` body — you
              write nothing extra.
            MD

            DocsUI::Code(<<~RUBY, filename: "app/controllers/docs_controller.rb")
              class DocsController < ApplicationController
                include DocsKit::Controller

                def show
                  render_page(Views::Docs::Pages.const_get(params[:page].classify).new)
                end
              end
            RUBY

            md <<~'MD'
              The conversion is `DocsKit::MarkdownExport`: it renders the page to
              HTML, extracts the `#docs-content` subtree that `DocsUI::Shell`
              stamps, strips `[data-md-skip]` / `<script>` / `<style>`, and walks
              the remaining DOM to GFM. Because it runs **after** the render,
              authoring style is irrelevant — Phlex components, `md` islands, and
              raw tags in `prose` all convert identically. A page with no
              `#docs-content` region yields an empty body (`200` with `""`), never
              a 404, and the HTML route is untouched.
            MD

            DocsUI::Callout(:note) do
              plain "The host must route the "
              code { ".md" }
              plain "/"
              code { ".text" }
              plain " format (a format-aware or catch-all route). "
              code { ".text" }
              plain " is accepted only so hosts whose routes permit the built-in "
              code { ":text" }
              plain " format still get the twin."
            end

            md <<~'MD'
              The page chrome never leaks into the twin: `DocsUI::Page` stamps
              `data-md-skip` on its top nav (the "← Home" link and the "Markdown"
              action), so the export drops it. Anything you want kept out of the
              `.md` can opt out the same way — wrap it in
              `data: { md_skip: true }`.
            MD

            render DocsUI::PropTable.new(
              [
                [ "GET /docs/x.md", "route", "—", "The page's GFM twin (.text is an alias)." ],
                [ "DocsKit::Controller#render_page", "method", "—", "Serves the twin on a .md/.text request, HTML otherwise." ],
                [ "DocsKit::MarkdownExport.new(view).to_md", "class", "—", "The HTML→GFM converter over #docs-content." ],
                [ "data: { md_skip: true }", "attribute", "—", "Opt any wrapper out of the exported Markdown." ]
              ],
              headers: [ "Surface", "Kind", "Default", "Description" ]
            )
          end
        end

        def markdown_action_section
          DocsUI::Section("The \"Markdown\" masthead action",
                          description: "The button at the top of this page — copy the page as Markdown, or open the raw twin with JS off.") do
            md <<~'MD'
              `DocsUI::MarkdownAction` renders the small "Markdown" button in the
              masthead (a clipboard icon + label), pointing at the current page's
              `.md` twin. `DocsUI::Page` renders it automatically when
              `DocsKit.configuration.page_markdown_action` is true (the default) —
              look at the top-right of this page.

              With **JS off** it simply opens the raw Markdown — a working
              fallback, never a dead end. With **JS on**, the one `docs-nav`
              Stimulus controller upgrades the click: it fetches the same `.md`
              URL with `Accept: text/markdown`, writes the body to the clipboard,
              and flashes the label to "Copied!" for 1500ms. Any failure (no
              clipboard API on an insecure context, a non-ok fetch) falls back to
              normal navigation to the raw `.md`.
            MD

            DocsUI::Code(<<~RUBY)
              # Rendered for you by DocsUI::Page; the href is request.path + ".md":
              render DocsUI::MarkdownAction.new(request.path)
            RUBY

            md <<~'MD'
              The href is built from the request path and is idempotent about the
              query string: `/x → /x.md`, `/x?q=1 → /x.md?q=1`, and an existing
              `/x.md` is left as-is. The affordance lives inside the page's
              `data-md-skip` nav, so it never appears in the exported twin.
            MD

            DocsUI::Callout(:tip) do
              plain "Hide the button site-wide with "
              code { "c.page_markdown_action = false" }
              plain " — the "
              code { ".md" }
              plain " route itself keeps serving the twin regardless; the knob only controls the UI."
            end

            render DocsUI::PropTable.new(
              [
                [ "DocsUI::MarkdownAction.new(path)", "String", "request.path", "The page whose .md twin the button targets." ],
                [ "docs-nav#copyMarkdown", "action", "—", "Fetches + copies the twin; falls back to opening it." ],
                [ "c.page_markdown_action", "Boolean", "true", "Show the masthead button (the .md route ignores this)." ]
              ],
              headers: [ "Surface", "Type", "Default", "Description" ]
            )
          end
        end

        def llms_section
          DocsUI::Section("/llms.txt and /llms-full.txt",
                          description: "The llmstxt.org index and full-text dump — built straight from the registry, zero authoring.") do
            md <<~'MD'
              docs-kit's engine ships **no routes** — it is glue-only, so a site
              keeps full control over path, auth, and omission. The install
              generator draws the two llms routes for you:
            MD

            DocsUI::Code(<<~RUBY, filename: "config/routes.rb")
              get "/llms.txt"      => "docs_kit/llms#index", as: :llms
              get "/llms-full.txt" => "docs_kit/llms#full",  as: :llms_full
            RUBY

            md <<~'MD'
              **[/llms.txt](/llms.txt)** is the llmstxt.org index, built by
              `DocsKit::LlmsText.index`:

              - an `# {brand}` H1 (`c.brand`, default `"Docs"` — always present),
              - a `> {tagline}` blockquote (`c.tagline`) right under it — this site
                sets it to the shell's one-line summary; nil or empty omits the line,
              - one `## {group}` section per nav group, a tight bullet list of each
                authored page's absolute `.md` link, in registry order,
              - a trailing `## MCP` block *only when the MCP endpoint is live*.

              **[/llms-full.txt](/llms-full.txt)** concatenates every authored
              page's Markdown twin — each as `# {title}` + its rendered Markdown,
              separated by a `---` rule.

              Both include **only pages with a resolvable `view_class`** — an
              unwritten registry entry is excluded from the links and the
              concatenation, so neither ever references a page that doesn't exist
              yet. Links are absolutized against `request.base_url`, so agent
              tooling fetches a portable URL.
            MD

            DocsUI::Callout(:note) do
              plain "Both endpoints are HTTP-cached: they revalidate on the rendered body plus "
              code { "DocsKit::VERSION" }
              plain " as the etag salt, so any registry, config, or page change busts the cache while an unchanged site serves a "
              code { "304 Not Modified" }
              plain "."
            end

            render DocsUI::PropTable.new(
              [
                [ "c.brand", "String", '"Docs"', "The # H1 of the index (always emitted)." ],
                [ "c.tagline", "String, nil", "nil", "The > blockquote under the H1; nil/empty omits it." ],
                [ "c.nav_registries", "Hash", "{}", "Registries → the ## group sections and their .md links." ],
                [ "DocsKit::LlmsText.index / .full", "class", "—", "The pure builders the LlmsController threads request.base_url into." ]
              ],
              headers: [ "Surface", "Type", "Default", "Description" ]
            )
          end
        end

        def mcp_section
          DocsUI::Section("The read-only MCP server",
                          description: "POST /mcp — list_pages / get_page / search_docs over JSON-RPC, gated on the optional mcp gem.") do
            md <<~'MD'
              docs-kit ships a built-in **read-only** MCP server so an agent can
              connect over the protocol instead of scraping. It exposes three
              tools over `POST /mcp` (JSON-RPC), all reading the same registry,
              `.md` twins, and [search](/docs/search) index the docs render from:

              - **`list_pages`** — every authored page as `{slug, title, group, url}`,
              - **`get_page`** — one page's GFM twin by slug (unknown slugs return
                the list of valid ones, so an agent self-corrects),
              - **`search_docs`** — ranked full-text search returning
                `{page_title, section_title, url, snippet}`.
            MD

            DocsUI::Callout(:warning) do
              plain "The endpoint is live only when BOTH the optional "
              code { "mcp" }
              plain " gem is loadable AND "
              code { "c.mcp" }
              plain " is true (the default). Off in either case → the controller 404s and the site is byte-identical to before the feature. A fresh site has "
              code { "c.mcp = true" }
              plain " but no live endpoint until you add the gem and uncomment the routes."
            end

            md <<~'MD'
              Enabling it is two steps. Add the gem:
            MD

            DocsUI::Code(<<~RUBY, filename: "Gemfile")
              gem "mcp" # optional — powers the built-in POST /mcp server
            RUBY

            md <<~'MD'
              …then uncomment the routes the install generator drew for you
              (commented out, because the gem is optional). `POST` speaks
              JSON-RPC; `GET`/`DELETE` return `405` — the server is stateless and
              read-only, so there is no SSE session to open or terminate:
            MD

            DocsUI::Code(<<~RUBY, filename: "config/routes.rb")
              match "/mcp" => "docs_kit/mcp#method_not_allowed", via: %i[get delete]
              post  "/mcp" => "docs_kit/mcp#create"
            RUBY

            md <<~'MD'
              The controller delegates the whole protocol to the official MCP SDK:
              `DocsKit::McpServer.build` constructs the `MCP::Server` (named from
              `c.brand`, versioned from `DocsKit::VERSION`) and registers the three
              tools; `server.handle_json(request.body.read)` parses, dispatches,
              and serializes the JSON-RPC response. All three tools' logic lives in
              `DocsKit::McpTools` as pure plain-Ruby functions with zero gem and
              zero JSON-RPC dependency — so the whole consumption story is
              unit-testable without booting Rails or the SDK.

              Once live, `/llms.txt` grows its trailing `## MCP` block advertising
              the endpoint, so an agent reading the index discovers it can also
              connect over the protocol.
            MD

            render DocsUI::PropTable.new(
              [
                [ "c.mcp", "Boolean", "true", "Toggle; the endpoint needs this AND the mcp gem present." ],
                [ "c.mcp_enabled?", "method", "—", "!!c.mcp && the gem loadable — the gate the controller + llms.txt read." ],
                [ "POST /mcp", "route", "—", "JSON-RPC; GET/DELETE 405 (stateless, read-only)." ],
                [ "list_pages / get_page / search_docs", "tools", "—", "The three read-only tools, over DocsKit::McpTools." ]
              ],
              headers: [ "Surface", "Type", "Default", "Description" ]
            )
          end
        end

        def agents_section
          DocsUI::Section("AGENTS.md + the write-docs-page skill",
                          description: "The install generator scaffolds an authoring contract every agent can read.") do
            md <<~'MD'
              So an agent (or a teammate) can *author* pages the docs-kit way, the
              install generator scaffolds two files into the consuming site:

              - **`AGENTS.md`** at the repo root — the cross-tool authoring
                contract. The generator owns a delimited block inside it (between
                `<!-- BEGIN docs-kit -->` / `<!-- END docs-kit -->`), so a re-run
                updates only that block and leaves the rest of your `AGENTS.md`
                alone. A fresh site gets the whole file.
              - **`.claude/skills/write-docs-page/SKILL.md`** — a Claude Code skill
                that scaffolds with `rails g docs_kit:page`, writes Markdown-first
                `#content`, and runs the verification gates. Written unless the site
                already has one.

              Both point at the same recipe: one `DocsUI::Section` per part of the
              page (Sections own structure and the TOC — never a Markdown `##`),
              prose via a single-quoted `md <<~'MD'` heredoc, and reference
              material via `DocsUI::PropTable` / `DocsUI::FieldTable` /
              `DocsUI::RequestExample`. See [Authoring pages](/docs/authoring) for
              the same contract written for humans.
            MD

            DocsUI::Callout(:tip) do
              plain "The skill's recipe is exactly what the "
              code { "docs_kit:page" }
              plain " generator produces — see "
              a(href: "/docs/authoring") { "Authoring pages" }
              plain " and "
              a(href: "/docs/components") { "Components" }
              plain " for the full kit."
            end
          end
        end
      end
    end
  end
end
