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
            md <<~'MD'
              This runs `rails new` (propshaft + importmap + turbo/stimulus, no
              database) and applies the docs-kit template, which:

              - adds the gem and its dependencies,
              - runs the install generator,
              - syncs the lucide icons,
              - builds the Tailwind CSS, and
              - scaffolds the Kamal deploy.

              Then boot it:
            MD
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
          md "**1. Add the gems.**"
          DocsUI::Code(<<~RUBY, filename: "Gemfile")
            gem "docs-kit"
            gem "daisyui", require: "daisy_ui"
            gem "phlex-rails"
            gem "rails_icons", "~> 1.1"
            gem "rouge"
          RUBY
          md "Then run `bundle install`."
        end

        def existing_app_generator
          md "**2. Run the install generator.**"
          DocsUI::Code(<<~SHELL, lexer: :shell)
            rails g docs_kit:install
          SHELL
          md <<~'MD'
            It creates the initializers (phlex, rails_icons, docs_kit), includes
            `DocsKit::Controller`, a `Doc` registry with a sample page, the
            Bun/Tailwind CSS build (`bin/build-css`), and registers the Stimulus
            controller. It is idempotent — safe to re-run.
          MD
        end

        def existing_app_icons
          md "**3. Sync the icons.**"
          DocsUI::Code(<<~SHELL, lexer: :shell)
            rails g rails_icons:sync --library=lucide
          SHELL
        end

        def existing_app_css
          md "**4. Build the CSS.**"
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

        # Kept as a Prose() block (not md) on purpose: this page mixes both
        # authoring styles to prove Prose stays fully supported alongside md.
        def verify_section
          DocsUI::Section("Verify") do
            prose do
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
