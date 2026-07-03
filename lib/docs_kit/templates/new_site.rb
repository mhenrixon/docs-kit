# frozen_string_literal: true

require "securerandom"

# Rails application template for a docs-kit docs site. Run via:
#
#   rails new my-docs --minimal -a propshaft -j importmap --skip-... -m new_site.rb
#
# or, more simply, via the `docs-kit new` CLI (exe/docs-kit) which supplies the
# right `rails new` flags. It:
#   * adds docs-kit + its runtime deps to the Gemfile,
#   * runs `docs_kit:install` (all the Ruby/CSS/Stimulus wiring),
#   * syncs the lucide icon set and builds the CSS,
#   * scaffolds a deployable Kamal setup that calls docs-kit's reusable workflow.
#
# The generated app is a complete, deployable standalone docs site.

# --- config the template reads ------------------------------------------------
# DOCS_KIT_GEM_SOURCE lets the dogfood site (docs-kit/docs) depend on the gem via
# path: ".." while a real new site depends on the released gem. Default: rubygems.
gem_source = ENV.fetch("DOCS_KIT_GEM_SOURCE", "") # e.g. 'path: "..", ' or 'github: "mhenrixon/docs-kit", '
# The GHCR image/service = the OWNER/REPO the site will live in (repo-linked pkg).
image = ENV.fetch("DOCS_KIT_IMAGE", "mhenrixon/#{app_name}")
service = ENV.fetch("DOCS_KIT_SERVICE", app_name)

# --- gems ---------------------------------------------------------------------
gem_line = "gem \"docs-kit\"#{", #{gem_source}" unless gem_source.empty?}"
inject_into_file "Gemfile", after: %r{source ["']https://rubygems\.org["']\n} do
  <<~RUBY

    # docs-kit shared docs chrome + its runtime deps
    #{gem_line}
    gem "daisyui", require: "daisy_ui"
    gem "phlex-rails"
    gem "rails_icons", "~> 1.1"
    gem "rouge"

    # Optional: expose these docs to AI agents over MCP (a read-only /mcp endpoint).
    # Uncomment this and the /mcp route in config/routes.rb. See the docs-kit README.
    # gem "mcp"
  RUBY
end

after_bundle do
  # The whole docs-kit wiring in one call (idempotent).
  generate "docs_kit:install"

  # Sync the lucide icons the chrome renders, then build the CSS.
  run "bin/rails g rails_icons:sync --library=lucide --force --quiet"
  run "bun install --silent" if system("command -v bun >/dev/null 2>&1")
  run "bun run build:css" if system("command -v bun >/dev/null 2>&1")

  # --- deploy scaffolding (Kamal + the reusable workflow) ---------------------
  create_file "config/deploy.yml", <<~YAML
    # Kamal deploy → the oss-infrastructure server (Cloudflare Tunnel + kamal-proxy).
    # service/image = the repo OWNER/REPO so the ghcr package auto-links to the
    # repo and GITHUB_TOKEN can push + pull it (no PAT). See docs-kit's README.
    service: #{service}
    image: #{image}

    servers:
      web:
        hosts:
          - <%= ENV["DEPLOY_HOST"] %>

    ssh:
      user: <%= ENV.fetch("DEPLOY_SSH_USER", "oss") %>

    proxy:
      host: <%= ENV["DEPLOY_DOMAIN"] %>
      app_port: 3000
      ssl: false
      healthcheck:
        path: /up
        interval: 5
        timeout: 30

    registry:
      server: ghcr.io
      username: mhenrixon
      password:
        - KAMAL_REGISTRY_PASSWORD

    builder:
      arch: amd64
      context: .
      dockerfile: Dockerfile

    env:
      clear:
        RAILS_SERVE_STATIC_FILES: "true"
        RAILS_LOG_TO_STDOUT: "true"
        # A stateless docs site: SECRET_KEY_BASE only signs cookies, so it's
        # inlined (no user data at risk). Rotate with `bin/rails secret`.
        SECRET_KEY_BASE: "#{SecureRandom.hex(64)}"
  YAML

  create_file ".kamal/secrets", <<~SH
    # In CI the deploy workflow sets this to the job's GITHUB_TOKEN. Locally,
    # export it (e.g. KAMAL_REGISTRY_PASSWORD=$(gh auth token)).
    KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD
  SH

  create_file "Dockerfile", <<~DOCKER
    # syntax = docker/dockerfile:1
    ARG RUBY_VERSION=3.4.2
    FROM ruby:$RUBY_VERSION-slim AS base

    ARG BUN_VERSION=1.3.2
    ENV BUN_INSTALL="/usr/local/bun"
    ENV PATH="/usr/local/bun/bin:$PATH"
    WORKDIR /rails
    ENV BUNDLE_WITHOUT="development:test" RAILS_ENV="production"

    RUN apt-get update -qq && \\
        apt-get install --no-install-recommends -y curl libjemalloc2 && \\
        rm -rf /var/lib/apt/lists /var/cache/apt/archives
    RUN gem update --system --no-document && gem install -N bundler

    FROM base AS build
    RUN apt-get update -qq && \\
        apt-get install --no-install-recommends -y build-essential git libyaml-dev pkg-config unzip
    RUN curl -fsSL https://bun.sh/install | bash -s "bun-v${BUN_VERSION}"
    COPY Gemfile Gemfile.lock ./
    RUN bundle install && rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache
    COPY . .
    RUN bun install --frozen-lockfile
    # assets:precompile runs bun run build:css via the css:build rake enhance.
    RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

    FROM base
    # Kamal verifies this label on --skip-push deploy; must equal `service:`.
    LABEL service="#{service}"
    COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
    COPY --from=build /rails /rails
    RUN groupadd --system --gid 1000 rails && \\
        useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \\
        chown -R 1000:1000 /rails/log /rails/tmp
    USER 1000:1000
    EXPOSE 3000
    CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
  DOCKER

  create_file ".github/workflows/deploy-docs.yml", <<~YAML
    name: Deploy docs
    # Build + deploy via docs-kit's reusable workflow (defined once for all sites).
    on:
      release: { types: [published] }
      workflow_dispatch:
    jobs:
      deploy:
        uses: mhenrixon/docs-kit/.github/workflows/deploy.yml@main
        with:
          image: #{image}
          service: #{service}
          build_context: "."
          dockerfile: "Dockerfile"
          working_directory: "."
        secrets: inherit
  YAML

  create_file "Procfile.dev", <<~PROC
    web: bin/rails server
    css: bun run watch:css
  PROC

  say "\n✅ docs-kit docs site scaffolded.", :green
  say <<~MSG
    Next:
      cd #{app_name}
      bin/dev                     # or bin/rails server
    Deploy: push, create a GitHub Release (or run the Deploy docs workflow).
      Set repo secrets: SSH_PRIVATE_KEY, DEPLOY_HOST, DEPLOY_DOMAIN (env: docs).
  MSG
end
