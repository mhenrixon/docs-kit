# frozen_string_literal: true

require "system_helper"

# End-to-end guard for the SEO/social <head>, driven through a real browser +
# server (Puma) with the Propshaft asset pipeline. This is coverage the gem's
# isolated component specs CAN'T give: only a booted app resolves a logical
# og_image path to the served, digested /assets URL.
#
# Regression guard for the production bug where og:image pointed at the raw config
# path (https://…/og/og.png → 404) instead of the digested /assets URL Propshaft
# serves.
RSpec.describe "SEO / social meta tags", type: :system do
  it "renders a complete, valid SEO head on the landing page" do
    visit "/"

    expect(page).to have_css("meta[name='description']", visible: :all)
    expect(page).to have_css("meta[property='og:title']", visible: :all)
    expect(page).to have_css("meta[property='og:type'][content='website']", visible: :all)
    expect(page).to have_css("meta[property='og:site_name'][content='docs-kit']", visible: :all)
    expect(page).to have_css("meta[name='twitter:card'][content='summary_large_image']", visible: :all)
    expect(page).to have_css("link[rel='canonical']", visible: :all)
  end

  it "resolves og:image to a served /assets URL (never the raw 404-ing path)" do
    visit "/"

    og_image = find("meta[property='og:image']", visible: :all)["content"]

    # The bug: "og/og.png" is NOT a served URL — Propshaft serves the digested
    # asset under /assets. The tag must carry that, never the raw path.
    expect(og_image).to include("/assets/")
    expect(og_image).not_to match(%r{//[^/]+/og/og\.png\z})
  end

  it "serves the og:image asset it advertises (a 200, not a 404)" do
    visit "/"
    og_image = find("meta[property='og:image']", visible: :all)["content"]
    path = URI.parse(og_image).path

    # Fetch the asset path through the same running app. A served asset is 200; the
    # raw /og/og.png path (the bug) would 404. THIS is the assertion that catches
    # the production regression — a shared link's image must actually load.
    visit path
    expect(page.status_code).to eq(200)
  end

  it "points twitter:image at the same served asset as og:image" do
    visit "/"

    og = find("meta[property='og:image']", visible: :all)["content"]
    tw = find("meta[name='twitter:image']", visible: :all)["content"]

    expect(tw).to eq(og)
  end

  it "sets a per-page description on a doc page (derived or authored)" do
    visit "/docs/installation"

    description = find("meta[name='description']", visible: :all)["content"]
    expect(description).not_to be_empty
  end
end
