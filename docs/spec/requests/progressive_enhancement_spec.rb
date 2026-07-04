# frozen_string_literal: true

require "rails_helper"

# docs-kit's core invariant: the server renders a working, fully-usable page with
# NO JavaScript — the docs-nav controller only *enhances* (collapse persistence,
# auto-TOC, the search palette). These request specs assert the raw server HTML
# (no browser, no JS executed), so a regression that made the page JS-dependent
# would fail here.
RSpec.describe "Progressive enhancement (JS off)", type: :request do
  it "renders the landing page as a complete HTML document" do
    get "/"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("<!doctype html>").or include("<!DOCTYPE html>")
    expect(response.body).to include("Shared docs chrome for Rails")
  end

  it "renders every sidebar section expanded (details open) so no-JS readers see the full nav" do
    get "/docs/overview"

    expect(response).to have_http_status(:ok)
    # The sidebar renders <details open> — with JS off the nav is fully expanded,
    # not a collapsed, unusable list. docs-nav only PERSISTS collapse state.
    expect(response.body).to match(/<details[^>]*\bopen\b/)
  end

  it "marks the active nav link server-side (menu-active, no JS)" do
    get "/docs/configuration"

    expect(response.body).to include("menu-active")
  end

  it "serves the Markdown twin of a page at .md" do
    get "/docs/installation.md"

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/markdown")
    expect(response.body).to include("Installation")
  end

  it "serves llms.txt from the registry" do
    get "/llms.txt"

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("docs-kit")
  end
end
