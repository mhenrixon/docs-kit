# frozen_string_literal: true

module Views
  module Docs
    module Pages
      class Deploy < DocsUI::Page
        title "Deploy"
        eyebrow "Guide"

        def lead = "One reusable workflow deploys every docs-kit site to Kamal + GHCR."

        def content
          DocsUI::Section("Scaffold it", description: "docs-kit new writes the whole deploy for you.") do
            DocsUI::Prose() { p { "The CLI generates a complete, deployable app:" } }
            DocsUI::Code(<<~SHELL, lexer: :shell)
              docs-kit new my-docs --image mhenrixon/my-repo --service my-repo
            SHELL
          end

          DocsUI::Section("The caller workflow") do
            DocsUI::Prose() do
              p do
                plain "Each site's "
                code { ".github/workflows/deploy-docs.yml" }
                plain " is a thin caller of the reusable workflow — build + deploy live in one place."
              end
            end
            DocsUI::Code(<<~YAML, lexer: :yaml, filename: ".github/workflows/deploy-docs.yml")
              on:
                release: { types: [published] }
                workflow_dispatch:
              jobs:
                deploy:
                  uses: mhenrixon/docs-kit/.github/workflows/deploy.yml@main
                  with:
                    image: mhenrixon/my-repo
                    service: my-repo
                  secrets: inherit
            YAML
          end

          DocsUI::Section("Naming", description: "Use the repo name so the ghcr package links to the repo.") do
            DocsUI::Prose() do
              p do
                plain "Set "
                code { "image" }
                plain " / "
                code { "service" }
                plain " to the repo's OWNER/REPO. The pushed package then auto-links to the repo, so "
                code { "GITHUB_TOKEN" }
                plain " can push and pull it — no PAT."
              end
            end
          end

          DocsUI::Section("Secrets") do
            DocsUI::Prose() do
              p do
                plain "Add a "
                code { "docs" }
                plain " environment with "
                code { "SSH_PRIVATE_KEY" }
                plain ", "
                code { "DEPLOY_HOST" }
                plain ", "
                code { "DEPLOY_DOMAIN" }
                plain ". The registry password is the auto-provided GITHUB_TOKEN."
              end
            end
          end
        end
      end
    end
  end
end
