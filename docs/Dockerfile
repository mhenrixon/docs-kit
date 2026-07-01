# syntax = docker/dockerfile:1
#
# docs-kit's own docs site dogfoods the gem via `gem "docs-kit", path: ".."`, so
# the build context is the REPO ROOT (gem at /app, docs app at /app/docs). Build
# from the repo root: the reusable workflow uses context "." + dockerfile
# "docs/Dockerfile".

ARG RUBY_VERSION=3.4.2
FROM ruby:$RUBY_VERSION-slim AS base

ARG BUN_VERSION=1.3.2
ENV BUN_INSTALL="/usr/local/bun"
ENV PATH="/usr/local/bun/bin:$PATH"

WORKDIR /app/docs

ENV BUNDLE_DEPLOYMENT="0" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_GEMFILE="/app/docs/Gemfile" \
    RAILS_ENV="production"

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives
RUN gem update --system --no-document && gem install -N bundler


# --- Build stage --------------------------------------------------------------
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libyaml-dev pkg-config unzip
RUN curl -fsSL https://bun.sh/install | bash -s "bun-v${BUN_VERSION}"

# The whole repo (gem at /app, app at /app/docs) — the path gem's gemspec runs
# `git ls-files`, so it needs the full checkout (incl .git) before bundle install.
COPY . /app/

RUN bundle config set frozen false && bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache

RUN bun install --frozen-lockfile
# assets:precompile runs bun run build:css via the css:build rake enhance.
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile


# --- Final stage --------------------------------------------------------------
FROM base

# Kamal verifies this label on the --skip-push deploy; must equal `service:` in
# config/deploy.yml (= the repo name, docs-kit).
LABEL service="docs-kit"

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /app /app

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R 1000:1000 /app/docs/log /app/docs/tmp
USER 1000:1000

EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
