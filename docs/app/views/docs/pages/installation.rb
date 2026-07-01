# frozen_string_literal: true

module Views
  module Docs
    module Pages
      class Installation < DocsUI::Page
        title "Installation"
        eyebrow "Getting started"

        def lead = "Scaffold a new docs site in one command, or add docs-kit to an existing Rails app."

        def content
          new_site_section
          existing_app_section
          requirements_section
          verify_section
        end

        private

        def new_site_section
          DocsUI::Section("New site in one command", description: "The fastest path — a deployable app from scratch.") do
            DocsUI::Code(<<~SHELL, lexer: :shell)
              docs-kit new my-docs --image OWNER/REPO --service my-repo
            SHELL
            DocsUI::Prose() do
              p do
                plain "This runs "
                code { "rails new" }
                plain " (propshaft + importmap + turbo/stimulus, no database) and applies the docs-kit template, which:"
              end
              ul do
                li { "adds the gem and its dependencies," }
                li { "runs the install generator," }
                li { "syncs the lucide icons," }
                li { "builds the Tailwind CSS, and" }
                li { "scaffolds the Kamal deploy." }
              end
              p { "Then boot it:" }
            end
            DocsUI::Code(<<~SHELL, lexer: :shell)
              cd my-docs && bin/dev
            SHELL
            DocsUI::Callout(:tip) do
              plain "The generator path (docs-kit new) performs every step in the "
              plain "“Add to an existing Rails app” section below automatically. Reach for the manual steps only when adding docs-kit to an app you already have."
            end
          end
        end

        def existing_app_section
          DocsUI::Section("Add to an existing Rails app") do
            existing_app_gemfile
            existing_app_generator
            existing_app_icons
            existing_app_css
          end
        end

        def existing_app_gemfile
          DocsUI::Prose() { p { strong { "1. Add the gems." } } }
          DocsUI::Code(<<~RUBY, filename: "Gemfile")
            gem "docs-kit"
            gem "daisyui", require: "daisy_ui"
            gem "phlex-rails"
            gem "rails_icons", "~> 1.1"
            gem "rouge"
          RUBY
          DocsUI::Prose() do
            p do
              plain "Then run "
              code { "bundle install" }
              plain "."
            end
          end
        end

        def existing_app_generator
          DocsUI::Prose() { p { strong { "2. Run the install generator." } } }
          DocsUI::Code(<<~SHELL, lexer: :shell)
            rails g docs_kit:install
          SHELL
          DocsUI::Prose() do
            p do
              plain "It creates the initializers (phlex, rails_icons, docs_kit), includes "
              code { "DocsKit::Controller" }
              plain ", a "
              code { "Doc" }
              plain " registry with a sample page, the Bun/Tailwind CSS build ("
              code { "bin/build-css" }
              plain "), and registers the Stimulus controller. It is idempotent — safe to re-run."
            end
          end
        end

        def existing_app_icons
          DocsUI::Prose() { p { strong { "3. Sync the icons." } } }
          DocsUI::Code(<<~SHELL, lexer: :shell)
            rails g rails_icons:sync --library=lucide
          SHELL
        end

        def existing_app_css
          DocsUI::Prose() { p { strong { "4. Build the CSS." } } }
          DocsUI::Code(<<~SHELL, lexer: :shell)
            bun install && bun run build:css
          SHELL
        end

        def requirements_section
          DocsUI::Section("Requirements") do
            render PropTable.new(
              [ "Requirement", "Version/Note" ],
              [
                [ "Ruby", ">= 3.2" ],
                [ "Rails", ">= 7.1" ],
                [ "Bun", "for the Tailwind CSS build" ],
                [ "PostgreSQL", "not required (docs sites are stateless)" ]
              ]
            )
          end
        end

        def verify_section
          DocsUI::Section("Verify") do
            DocsUI::Prose() do
              p do
                plain "Boot the app with "
                code { "bin/dev" }
                plain " and visit "
                code { "/docs" }
                plain ". You should see the shell with the sidebar, the theme switcher, and this page's content."
              end
            end
          end
        end
      end
    end
  end
end
