# frozen_string_literal: true

module Views
  module Docs
    module Pages
      class Styling < DocsUI::Page
        title "Styling & CSS"
        eyebrow "Getting started"

        def lead = "Each site builds its own Tailwind + daisyUI stylesheet so the chrome is themed to match."

        def content
          DocsUI::Section("The canonical build", description: "docs-kit ships no compiled CSS — you build it.") do
            DocsUI::Prose() do
              p do
                plain "docs-kit ships "
                strong { "no compiled CSS" }
                plain ". Each site builds its own with the Tailwind CLI (run via Bun), so the "
                code { "@source" }
                plain " globs can see "
                strong { "both" }
                plain " your app "
                strong { "and" }
                plain " the gem's Phlex components. Without the gem in scope, every class the shared chrome uses would be tree-shaken away."
              end
              p do
                plain "The bundled "
                code { "bin/build-css" }
                plain " resolves the docs-kit gem path and adds it as an extra "
                code { "@source" }
                plain ", so you never hand-write the gem's location."
              end
            end
            DocsUI::Code(<<~SHELL, lexer: :shell)
              bun run build:css     # one-shot, for deploys
              bun run watch:css     # rebuild on change, for development
            SHELL
          end

          DocsUI::Section("application.tailwind.css", description: "Your Tailwind entry point wires up daisyUI and the sources.") do
            DocsUI::Prose() do
              p do
                plain "The "
                code { "themes:" }
                plain " list here "
                strong { "must match" }
                plain " "
                code { "c.themes" }
                plain " in your initializer — the CSS build ships those themes and the ThemeSwitcher offers them."
              end
            end
            DocsUI::Code(<<~CSS, filename: "app/assets/stylesheets/application.tailwind.css", lexer: :css)
              @import "tailwindcss";

              @plugin "daisyui" {
                themes: dark --default, light, synthwave;
              }

              /* Your app's templates + components */
              @source "../../../app/views/**/*.rb";
              @source "../../../app/components/**/*.rb";

              /* The docs-kit gem's Phlex chrome (bin/build-css injects this path) */
              @source "../../../../<docs-kit gem>/lib/**/*.rb";
            CSS
          end

          DocsUI::Section("Adding a theme") do
            DocsUI::Prose() do
              p { "Themes come from daisyUI. To add one:" }
              ol do
                li do
                  plain "Add it to the "
                  code { "@plugin \"daisyui\" { themes: ... }" }
                  plain " block in "
                  code { "application.tailwind.css" }
                  plain "."
                end
                li do
                  plain "Add the same name to "
                  code { "c.themes" }
                  plain " in "
                  code { "config/initializers/docs_kit.rb" }
                  plain "."
                end
                li do
                  plain "Rebuild the CSS ("
                  code { "bun run build:css" }
                  plain ")."
                end
              end
            end
            DocsUI::Callout(:warning) do
              plain "Interpolated Tailwind class names get tree-shaken. Always write "
              strong { "literal" }
              plain " class strings in components — e.g. "
              code { 'class: "badge badge-primary"' }
              plain ", never "
              code { 'class: "badge badge-\#{color}"' }
              plain ". The scanner can't see the built name, so the style never ships."
            end
          end

          DocsUI::Section("Custom styles") do
            DocsUI::Prose() do
              p do
                plain "Add your own CSS below the imports in "
                code { "application.tailwind.css" }
                plain " — plain rules, "
                code { "@apply" }
                plain ", or "
                code { "@layer" }
                plain " all work."
              end
              p do
                plain "To pull in additional stylesheets (loaded after the built one), list them via "
                code { "c.stylesheets" }
                plain " in your initializer."
              end
            end
            DocsUI::Code(<<~RUBY, filename: "config/initializers/docs_kit.rb")
              DocsKit.configure do |c|
                c.stylesheets = %w[custom announcements]
              end
            RUBY
          end
        end
      end
    end
  end
end
