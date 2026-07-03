# frozen_string_literal: true

require "test_helper"

# Boots the REAL docs site (Propshaft asset pipeline, the configured c.seo) and
# proves the SEO/social <head> is correct end-to-end — the coverage the gem's
# isolated component specs can't give, because only a booted app has the asset
# pipeline that turns a logical og_image path into a served /assets URL.
#
# This is the regression guard for the production bug where og:image pointed at
# the raw config path (https://…/og/og.png → 404) instead of the digested,
# Propshaft-served /assets URL.
class SeoMetaTagsTest < ActionDispatch::IntegrationTest
  # image_url uses Propshaft's Static resolver, which reads the precompiled
  # manifest — so og:image only resolves once assets are compiled (exactly the
  # deploy-time condition). Compile once for this suite so the test is
  # self-sufficient regardless of run order (no external `assets:precompile` step
  # needed). This is also what proves the fix: the compiled og.png IS served.
  def self.precompiled
    @precompiled ||= (Rails.application.load_tasks; Rake::Task["assets:precompile"].invoke; true)
  end

  setup { self.class.precompiled }

  test "the landing page emits a complete, valid SEO head" do
    get root_path

    assert_response :success
    description = css_select("meta[name=description]").first
    assert description, "expected a meta description"
    assert_match(/Shared Phlex/, description["content"])
    assert_select "meta[property='og:title']"
    assert_select "meta[property='og:type'][content=website]"
    assert_select "meta[property='og:site_name'][content='docs-kit']"
    assert_select "meta[name='twitter:card'][content='summary_large_image']"
    assert_select "link[rel=canonical]"
  end

  test "og:image is a served /assets URL, not the raw config path" do
    get root_path

    og_image = css_select("meta[property='og:image']").first
    assert og_image, "expected an og:image meta tag"
    url = og_image["content"]

    # The bug: the raw config path "og/og.png" is NOT a served URL. Propshaft
    # serves the DIGESTED asset under /assets. The tag must carry that, never the
    # raw path.
    assert_match %r{/assets/}, url, "og:image must be a pipeline /assets URL, got #{url}"
    refute_match %r{//[^/]+/og/og\.png\z}, url, "og:image must NOT be the raw, 404-ing path: #{url}"
  end

  test "the og:image URL actually resolves (the asset is served, not a 404)" do
    get root_path
    url = css_select("meta[property='og:image']").first["content"]

    # Fetch just the path component against the same app — a served asset returns
    # 200; the raw /og/og.png path (the bug) would 404. This is the assertion that
    # would have caught the production regression.
    path = URI.parse(url).path
    get path

    assert_response :success, "og:image asset did not resolve (#{path}) — a shared link would show a broken image"
    assert_equal "image/png", response.media_type
  end

  test "twitter:image matches og:image (both the served asset)" do
    get root_path

    og = css_select("meta[property='og:image']").first["content"]
    tw = css_select("meta[name='twitter:image']").first["content"]

    assert_equal og, tw
  end
end
