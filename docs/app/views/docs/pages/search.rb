# frozen_string_literal: true

module Views
  module Docs
    module Pages
      # Server-rendered docs search + the ⌘K palette: a JS-off GET form, an
      # in-memory index built from the pages' Markdown twins, and the .json
      # endpoint the palette fetches. Renders the real SearchBox/SearchResults.
      class Search < DocsUI::Page
        title "Search"
        eyebrow "AI & tooling"

        def lead = "One index, two front-ends: a plain GET form that works with JavaScript off, and a ⌘K palette that enhances it. Both read the same twins that feed /llms-full.txt, so search can never drift from the pages."

        def content
          overview_section
          progressive_section
          index_section
          endpoint_section
          searchbox_section
          config_section
        end

        private

        def overview_section
          DocsUI::Section("How search fits together",
                          description: "Zero authoring, no external service, no build step — the pages ARE the index.") do
            md <<~'MD'
              docs-kit search has three moving parts and no second registry:

              - **`DocsKit::SearchIndex`** — an in-memory index built per request
                from each page's Markdown twin (the same twins
                [/llms-full.txt](/docs/ai) serves), split on its `## ` headings
                into searchable sections.
              - **`DocsKit::SearchController`** — one gem controller answering
                **both** formats off that index: HTML for the JS-off results page,
                JSON for the palette.
              - **`DocsUI::SearchBox`** — the topbar form the `docs-nav` controller
                enhances into a keyboard palette.

              Everything is driven by `DocsKit.configuration` — `search`,
              `search_path`, and `search_shortcuts` — so a site tunes it without
              touching a component.
            MD

            DocsUI::Callout(:note) do
              plain "The route is "
              strong { "not" }
              plain " added by the engine — the install generator draws "
              code { "get \"/docs/search\" => \"docs_kit/search#index\"" }
              plain " so a site can remount search elsewhere via "
              code { "config.search_path" }
              plain "."
            end
          end
        end

        def progressive_section
          DocsUI::Section("Works with JavaScript off",
                          description: "The GET form is the whole search UX; the palette is a pure enhancement over the same controller.") do
            md <<~'MD'
              The topbar affordance is a real `GET` form pointed at
              `config.search_path`. Press **Enter** and the browser lands on the
              server-rendered results page — no JavaScript required. `docs-nav`
              enhances that same form into a debounced palette; if JS never loads
              (or dies mid-typing) the form still submits normally.

              The results page IS `DocsUI::SearchResults` wrapped in
              `DocsUI::Shell` — a full working page, not a JSON blob. It echoes the
              query, groups hits by page (best-scoring page first), links each hit
              to its section anchor, and shows a pre-highlighted snippet.
            MD

            prose { p { "The JS-off results body, rendered live for a query that hits this very page:" } }
            render DocsUI::SearchResults.new(
              query: "search index",
              hits: DocsKit::SearchIndex.new(
                [
                  [
                    "Search", "/docs/search",
                    "The docs search index is built from each page's Markdown twin.\n\n" \
                    "## The search index\nDocsKit::SearchIndex splits a twin on its headings into sections."
                  ]
                ]
              ).search("search index")
            )

            prose { p { "The call that produced the block above (the controller does this for you):" } }
            DocsUI::Code(<<~RUBY)
              render DocsUI::SearchResults.new(
                query: params[:q],
                hits:  index.search(params[:q])
              )
            RUBY

            DocsUI::Callout(:tip) do
              plain "A blank query prompts the reader; a query with "
              strong { "no" }
              plain " hits renders guidance (“Try fewer or more general words”) instead of an empty list. A page-intro hit (no section) is labeled "
              code { "Overview" }
              plain "."
            end
          end
        end

        def index_section
          DocsUI::Section("The in-memory index",
                          description: "DocsKit::SearchIndex over the registry — pure Ruby, unit-testable with no Rails.") do
            md <<~'MD'
              The controller renders each registry page through
              `DocsKit::MarkdownExport` and hands `SearchIndex` a list of triples —
              `[page_title, page_href, markdown]`. The index splits every twin on
              its `## ` (level-2 ATX) headings into one entry per section, plus a
              **page-intro** entry for the text before the first heading.
            MD

            DocsUI::Code(<<~RUBY)
              index = DocsKit::SearchIndex.new(
                [["Overview", "/docs/overview", overview_markdown_twin],
                 ["Search",   "/docs/search",   search_markdown_twin]]
              )
              index.search("theme switcher") # => [DocsKit::SearchHit, ...]
            RUBY

            md <<~'MD'
              **Scoring** is weighted AND-token ranking: every whitespace-split
              query token must match somewhere in an entry, and each token scores
              the heaviest field it hit — title beats heading beats body
              (`100 > 10 > 1`). The entry's score is the per-token sum, so a section
              matching more tokens in heavier fields floats up. Matching is plain
              case-insensitive `String#include?` (so `gen` matches `Generators`) —
              no fuzzy matching, no stemming, by design. Results cap at 20.

              The page **title** is a searchable field only on the page-intro entry
              — never on every section — so a pure title match surfaces once rather
              than flooding the results with every section of that page.
            MD

            render DocsUI::PropTable.new(
              [
                [ "SearchIndex.new(triples)", "Array", "[]", "[[page_title, page_href, markdown], …] — the twins." ],
                [ "#search(query)", "String", "—", "Array<SearchHit>, best first, capped at 20. Blank → []." ],
                [ "#entries", "—", "—", "The indexed Entry list (one per section + page intro)." ],
                [ "TITLE/HEADING/BODY_WEIGHT", "Integer", "100 / 10 / 1", "Field weights a token scores against." ],
                [ "MAX_RESULTS", "Integer", "20", "Hard cap on returned hits." ]
              ],
              headers: [ "API", "Type", "Default", "Description" ]
            )

            md <<~'MD'
              Each hit is a `DocsKit::SearchHit` — an immutable value object with
              `page_title`, `section_title` (nil for a page-intro hit), `href`
              (the `page_href#anchor`), a pre-highlighted HTML-safe `snippet`, and
              a `score`. Its `#label` reads `"Page → Section"` (or just the page
              title), and `#as_json` is the `{ label, href, snippet }` shape the
              palette fetches (score is dropped — rank only matters server-side).

              The snippet is a `~80`-char window centered on the first match with
              the query terms wrapped in `<mark>`; everything else is HTML-escaped
              **first**, so a source angle bracket can never inject markup. That's
              why `SearchResults` can render it via `raw(safe(…))` — it's trusted
              gem-produced markup, the same idiom `DocsUI::Code` uses.
            MD

            DocsUI::Callout(:warning) do
              plain "The section anchor is recomputed as "
              code { "page_href#slug" }
              plain " using the SAME "
              code { "slugify" }
              plain " rule "
              code { "DocsUI::Section" }
              plain " stamps on its "
              code { "<section id>" }
              plain ". Section splitting is code-fence aware, but a "
              code { "## " }
              plain " with no space ("
              code { "##Nospace" }
              plain ") is not treated as a heading."
            end
          end
        end

        def endpoint_section
          DocsUI::Section("One endpoint, HTML + JSON",
                          description: "DocsKit::SearchController answers both formats off the same lazily-built index.") do
            md <<~'MD'
              The host draws the route (the engine adds none); the controller reads
              `params[:q]` and responds by format:

              - **HTML** — the JS-off path: `DocsUI::SearchResults` inside
                `DocsUI::Shell`, rendered `layout: false` (the Shell IS the whole
                document).
              - **JSON** — the enhancement path: `{ query, results: [...] }`, where
                each result is a `SearchHit#as_json`. The palette fetches this
                debounced as you type.

              The palette hits the `.json` variant of the same path:
            MD

            DocsUI::Code(<<~JSON, filename: "GET /docs/search.json?q=theme", lexer: :json)
              {
                "query": "theme",
                "results": [
                  {
                    "label": "Components → ThemeSwitcher",
                    "href": "/docs/components#themeswitcher",
                    "snippet": "…the <mark>theme</mark> dropdown in the topbar…"
                  }
                ]
              }
            JSON

            md <<~'MD'
              The index is rebuilt on **every** request (no caching) — fine for a
              tens-of-pages site, but `O(pages × markdown render)` per query.
              Because it renders through the controller's own view context, url
              helpers and CSRF resolve, and hrefs are absolutized against
              `request.base_url` — exactly as the [/llms-full.txt](/docs/ai)
              endpoint renders each twin.
            MD

            DocsUI::Callout(:note) do
              plain "The controller reads config via "
              code { "#docs_config" }
              plain ", never "
              code { "#config" }
              plain " — shadowing "
              code { "ActionController::Base#config" }
              plain " would break "
              code { "csrf_meta_tags" }
              plain " when the Shell renders."
            end
          end
        end

        def searchbox_section
          DocsUI::Section("The topbar SearchBox & ⌘K palette",
                          description: "The GET form docs-nav enhances — one <kbd> hint per configured shortcut, bound from JSON.") do
            md <<~'MD'
              `DocsUI::SearchBox` is the affordance in the topbar — `DocsUI::Shell`
              renders it whenever `DocsKit.configuration.search_enabled?`. It's a
              plain `GET` form to `config.search_path` with a `q` input, plus the
              hooks `docs-nav` needs to turn it into a palette:

              - one `<kbd>` badge per `config.search_shortcuts`, labeled by the
                parsed `DocsKit::Shortcut#label` (`/`, `Ctrl K`, …),
              - the parsed shortcut list emitted as JSON on the scope
                (`data-docs-nav-shortcuts-value`), so the visible badges and the
                key bindings share ONE source and can't drift,
              - an empty, hidden results dropdown `docs-nav` fills as you type.
            MD

            prose { p { "The real component (it's the same one in this site's topbar):" } }
            render DocsUI::SearchBox.new

            prose { p { "Render it yourself with:" } }
            DocsUI::Code(<<~RUBY)
              render DocsUI::SearchBox.new
              # Shell renders it automatically when config.search_enabled?
            RUBY

            md <<~'MD'
              Shortcuts are platform-agnostic strings. `mod` is the **platform
              modifier** — ⌘ on mac, Ctrl elsewhere — kept abstract server-side and
              resolved in the browser by `docs-nav`, which swaps only the badge
              label (never the binding). Modifier aliases: `mod`,
              `ctrl`/`control`, `shift`, `alt`/`option`, `cmd`/`command`/`meta`.
            MD

            render DocsUI::PropTable.new(
              [
                [ "mod+k", "Ctrl K", "Platform command chord — ⌘K on mac, Ctrl K elsewhere." ],
                [ "/", "/", "A bare key — shown exactly as authored." ],
                [ "s", "s", "A bare single char — not uppercased." ],
                [ "ctrl+shift+f", "Ctrl Shift F", "An explicit physical chord (no platform abstraction)." ]
              ],
              headers: [ "Shortcut string", "<kbd> label", "Meaning" ]
            )

            DocsUI::Callout(:tip) do
              plain "A modifier-only or empty string ("
              code { "mod+" }
              plain ", "
              code { "\"\"" }
              plain ", "
              code { "nil" }
              plain ") is unparseable — "
              code { "Shortcut.parse_list" }
              plain " silently drops it. With "
              code { "search_shortcuts" }
              plain " empty the form still works; it just renders no "
              code { "<kbd>" }
              plain " badges."
            end
          end
        end

        def config_section
          DocsUI::Section("Configuration",
                          description: "Three knobs — the affordance, where it submits, and the shortcuts.") do
            DocsUI::Code(<<~RUBY, filename: "config/initializers/docs_kit.rb")
              DocsKit.configure do |c|
                c.search           = true            # toggle the affordance (default true)
                c.search_path      = "/docs/search"  # where the form GETs; palette fetches .json here
                c.search_shortcuts = %w[/ mod+k]     # chord strings (default ["/", "mod+k"])
              end
            RUBY

            render DocsUI::PropTable.new(
              [
                [ "c.search", "Boolean", "true", "Toggles the topbar affordance + palette markup site-wide." ],
                [ "c.search_path", "String", '"/docs/search"', "Where the form GETs and the base the palette fetches .json from." ],
                [ "c.search_shortcuts", "Array<String>", '["/", "mod+k"]', "Chord strings that open the palette." ],
                [ "config.search_enabled?", "Boolean", "—", "search == true AND a non-blank search_path." ],
                [ "config.search_shortcuts", "Array<Shortcut>", "—", "The PARSED list (reader maps to Shortcut, drops unparseable)." ]
              ],
              headers: [ "Knob / reader", "Type", "Default", "Description" ]
            )

            md <<~'MD'
              `search_shortcuts` is asymmetric by design: you set raw **strings**,
              but `config.search_shortcuts` reads them back as parsed
              `DocsKit::Shortcut` objects (dropping anything unparseable) — read the
              parsed reader, never `@search_shortcuts`.

              Blanking `search_path` disables the affordance even with
              `search == true`: `search_enabled?` is false because there'd be
              nothing to submit to. That lets a site kill search without touching
              `c.search`.
            MD

            DocsUI::Callout(:note) do
              plain "See "
              a(href: "/docs/configuration") { "Configuration" }
              plain " for the full config surface, "
              a(href: "/docs/ai") { "AI & agents" }
              plain " for the twins search reads, and "
              a(href: "/docs/components") { "Components" }
              plain " for SearchBox / SearchResults alongside the rest of the kit."
            end
          end
        end
      end
    end
  end
end
