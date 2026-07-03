# frozen_string_literal: true

module Views
  module Docs
    module Pages
      # How each site builds its own Tailwind + daisyUI stylesheet, keeps the
      # theme list in sync with the CSS, and drives the light/dark code-highlight
      # theme — all config, no per-site CSS surgery.
      class Styling < DocsUI::Page
        title "Styling & CSS"
        eyebrow "Getting started"

        def lead = "Each site builds its own Tailwind + daisyUI stylesheet so the chrome is themed to match — and code blocks restyle light↔dark with the switcher, CSS-only."

        def content
          canonical_build_section
          entry_point_section
          adding_a_theme_section
          code_theme_section
          custom_styles_section
        end

        private

        def canonical_build_section
          DocsUI::Section("The canonical build",
                          description: "docs-kit ships no compiled CSS — you build it.") do
            md <<~'MD'
              docs-kit ships **no compiled CSS**. Each site builds its own with
              the Tailwind CLI (run via Bun), so the `@source` globs can see
              **both** your app **and** the gem's Phlex components. Without the
              gem in scope, every class the shared chrome uses would be
              tree-shaken away.

              The bundled `bin/build-css` resolves the docs-kit (and daisyUI) gem
              paths and adds them as extra `@source` entries, so you never
              hand-write a gem's install location.
            MD

            DocsUI::Code(<<~SHELL, lexer: :shell)
              bun run build:css     # one-shot, for deploys
              bun run watch:css     # rebuild on change, for development
            SHELL
          end
        end

        def entry_point_section
          DocsUI::Section("application.tailwind.css",
                          description: "Your Tailwind entry point wires up daisyUI, the themes, and the sources.") do
            md <<~'MD'
              The `themes:` list here **must match** `c.themes` in your
              initializer — the CSS build ships exactly those themes and the
              `ThemeSwitcher` offers exactly those names. A theme in one list but
              not the other is either a dead switcher entry or an unreachable
              build. This is the single most important invariant on this page.
            MD

            DocsUI::Code(<<~CSS, filename: "app/assets/stylesheets/application.tailwind.css", lexer: :css)
              @import "tailwindcss";

              /* daisyUI — the theme list MUST match DocsKit.configuration.themes. */
              @plugin "daisyui" {
                themes: dark --default, light --prefersdark, synthwave, retro,
                  cyberpunk, dracula, night, nord, sunset;
              }

              /* Your app's views + components + the gem's Phlex chrome.
                 bin/build-css resolves the gem paths, so you never hard-code them. */
              @source "../../../app/views/**/*.{rb,erb,haml,html,slim}";
              @source "../../../app/components/**/*.rb";
              @import "./tailwind.sources.css";  /* gem @source lines, generated */
            CSS

            md <<~'MD'
              The `--default` modifier picks the theme applied on first paint and
              `--prefersdark` the one used when the OS asks for a dark scheme.
              That block above is this very site's — its nine themes are the nine
              in `c.themes`.
            MD

            DocsUI::Callout(:warning) do
              plain "Interpolated Tailwind class names get tree-shaken. Always write "
              strong { "literal" }
              plain " class strings — e.g. "
              code { 'class: "badge badge-primary"' }
              plain ", never "
              code { 'class: "badge badge-\#{color}"' }
              plain ". The scanner can't see the built name, so the style never ships. New render-time classes (like the Drawer) need an "
              code { "@source inline(...)" }
              plain " line."
            end
          end
        end

        def adding_a_theme_section
          DocsUI::Section("Adding a theme",
                          description: "Two edits and a rebuild — CSS block, config, done.") do
            md <<~'MD'
              Themes come from daisyUI. To add one, keep the two lists in step:

              1. Add the name to the `@plugin "daisyui" { themes: ... }` block in
                 `application.tailwind.css`.
              2. Add the same name to `c.themes` in
                 `config/initializers/docs_kit.rb`.
              3. Rebuild the CSS (`bun run build:css`).

              First entry in `c.themes` is the page default; override with
              `c.default_theme`. See [Configuration](/docs/configuration) for the
              full theme surface.
            MD

            DocsUI::Code(<<~RUBY, filename: "config/initializers/docs_kit.rb")
              DocsKit.configure do |c|
                c.themes = %w[dark light synthwave retro cyberpunk dracula night nord sunset]
              end
            RUBY
          end
        end

        def code_theme_section
          DocsUI::Section("Code highlighting: one light theme, one dark",
                          description: "Rouge highlights code; two config knobs make it follow the switcher.") do
            md <<~'MD'
              `DocsUI::Code` highlights with [Rouge](/docs/languages) and injects
              its **own** inline theme CSS — no separate stylesheet asset. Which
              theme that CSS uses is config:

              - `c.code_theme` — the **base** Rouge theme, emitted **un-scoped**
                so it applies under every daisyUI theme. Default
                `Rouge::Themes::Monokai`.
              - `c.code_theme_dark` — an **optional** second Rouge theme. When
                set, `Code` additionally emits that theme's CSS scoped under
                `[data-theme=X] .code-highlight` for each shipped dark theme.
                daisyUI's more-specific `[data-theme]` selector wins, so code
                blocks restyle when the switcher lands on a dark theme.
                **CSS-only — no JS, no flash.** Default `nil` (single-theme,
                byte-for-byte backwards compatible).
              - `c.dark_themes` — which theme names count as dark for that
                scoping. Defaults to the built-in daisyUI dark themes and is
                intersected with `c.themes` at render time, so only **shipped**
                dark themes emit CSS. A custom/branded dark theme must be listed
                here or its code CSS won't scope — docs-kit can't inspect the
                compiled daisyUI CSS to detect darkness.
            MD

            md <<~'MD'
              **This site sets both.** Its initializer picks a light base and a
              dark override, so every code block on the page you're reading
              restyles as you flip the theme switcher between a light theme
              (`light`, `retro`, `cyberpunk`, `nord`) and a dark one:
            MD

            DocsUI::Code(<<~RUBY, filename: "config/initializers/docs_kit.rb")
              DocsKit.configure do |c|
                c.code_theme      = "Rouge::Themes::Github"  # light themes
                c.code_theme_dark = "Rouge::Themes::Monokai" # dark themes
                # c.dark_themes defaults to daisyUI's dark set; override only
                # for a custom dark theme the built-in list doesn't know.
              end
            RUBY

            md <<~'MD'
              Try it: switch the theme in the topbar and watch this next block
              change palette. It's the same highlighter, two scoped stylesheets.
            MD

            DocsUI::Code(<<~RUBY, filename: "app/models/doc.rb")
              class Doc
                extend DocsKit::Registry

                path_prefix    "/docs"
                view_namespace "Views::Docs::Pages"

                page "Overview",       group: "Getting started"
                page "Styling & CSS",  group: "Getting started"
              end
            RUBY

            md <<~'MD'
              For this site, the shipped dark themes (the intersection of
              `c.dark_themes` and `c.themes`) are **dark, synthwave, dracula,
              night, sunset** — those five each get a `[data-theme=…]`-scoped
              Monokai block; the four light themes fall through to the un-scoped
              GitHub base.
            MD

            render DocsUI::PropTable.new(
              [
                [ "c.code_theme", "String or Class", "Rouge::Themes::Monokai", "Base (light) Rouge theme, emitted un-scoped." ],
                [ "c.code_theme_dark", "String, Class, nil", "nil", "Optional dark override, scoped per shipped dark theme. nil = single-theme." ],
                [ "c.dark_themes", "Array<String>", "daisyUI dark set", "Which theme names count as dark; intersected with c.themes at render." ]
              ]
            )

            DocsUI::Callout(:note) do
              plain "A String theme name is resolved to its Rouge constant. A typo'd or "
              plain "unloaded name "
              strong { "degrades gracefully" }
              plain " — the base theme falls back to the default and a bad "
              code { "code_theme_dark" }
              plain " simply emits no dark CSS, so a mistake never crashes a code block."
            end
          end
        end

        def custom_styles_section
          DocsUI::Section("Custom styles",
                          description: "Plain CSS, @apply, @layer, or extra stylesheets.") do
            md <<~'MD'
              Add your own CSS below the imports in `application.tailwind.css` —
              plain rules, `@apply`, or `@layer` all work.

              To pull in additional, separately-built stylesheets (linked after
              the Tailwind build), list their logical names via `c.stylesheets`
              in your initializer. Default is `%w[application]` — the Bun/Tailwind
              build.
            MD

            DocsUI::Code(<<~RUBY, filename: "config/initializers/docs_kit.rb")
              DocsKit.configure do |c|
                c.stylesheets = %w[application announcements]
              end
            RUBY

            md <<~'MD'
              Next: see [Languages](/docs/languages) for the Rouge lexer surface,
              [Components](/docs/components) for the kit `Code` and `Example`
              render live, and [Configuration](/docs/configuration) for every
              config knob in one place.
            MD
          end
        end
      end
    end
  end
end
