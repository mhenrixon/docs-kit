# frozen_string_literal: true

module DocsUI
  # The SEO / social-share <head> tags: description, Open Graph, Twitter Card,
  # canonical, favicon, robots, theme-color. Rendered by DocsUI::Shell inside
  # <head>, driven entirely by DocsKit.configuration (+ .seo) and the per-page
  # title/description — so every docs site is share-ready with zero markup, and a
  # site tunes it through config alone (no Shell subclass).
  #
  #   render DocsUI::MetaTags.new(title: "Installation", description: "…")
  #
  # All free text (title, description, brand) is emitted as normal Phlex
  # attribute values, so Phlex escapes it — config free text is never trusted
  # markup. og:image/og:url/canonical are absolutized against config.seo.site_url
  # when set, else the request base URL; with neither, og:image degrades to its
  # raw path and canonical/og:url are omitted (guarded like Shell#csp_nonce, so
  # an isolated render or a request-less static build never raises).
  class MetaTags < Phlex::HTML
    include Phlex::Rails::Helpers::Request

    # title:       the page title (nil on a page that sets none, e.g. the home
    #              page) — combined with config.title_suffix for og:title.
    # description: the page's resolved description (DocsUI::Page passes its own
    #              description or #lead); nil falls back to config.seo.description.
    def initialize(title: nil, description: nil)
      @title = title
      @description = description
    end

    def view_template
      description_meta
      open_graph
      twitter_card
      canonical_link
      favicon_link
      robots_meta
      theme_color_meta
    end

    private

    def config = DocsKit.configuration
    def seo = config.seo

    # The page description, falling back to the site-wide default. nil → the
    # description tags (meta description, og:description) are omitted.
    def description = @description || seo.description

    # The full title used for og:title, identical to what Shell puts in <title>:
    # "Page · Suffix", or just the suffix on a title-less page (the home page).
    def full_title
      [@title, config.title_suffix].compact.join(" · ")
    end

    def description_meta
      return unless description

      meta(name: "description", content: description)
    end

    # The always-present minimal OG block (title/type/site_name) plus the opt-in
    # description/image/url. A site that configures nothing still gets a valid
    # card — never a broken empty tag.
    def open_graph
      meta(property: "og:title", content: full_title)
      meta(property: "og:type", content: seo.og_type)
      meta(property: "og:site_name", content: config.brand)
      open_graph_optional
    end

    # The OG tags emitted only when their value resolves — kept separate so the
    # always-present block above stays a flat, obvious minimum.
    def open_graph_optional
      meta(property: "og:locale", content: seo.locale) if seo.locale
      meta(property: "og:description", content: description) if description
      meta(property: "og:image", content: og_image_url) if og_image_url
      meta(property: "og:url", content: canonical_url) if canonical_url
    end

    def twitter_card
      meta(name: "twitter:card", content: seo.twitter_card)
      meta(name: "twitter:site", content: seo.twitter_site) if seo.twitter_site
      meta(name: "twitter:creator", content: seo.twitter_creator) if seo.twitter_creator
      meta(name: "twitter:image", content: og_image_url) if og_image_url
    end

    def canonical_link
      return unless canonical_url

      link(rel: "canonical", href: canonical_url)
    end

    def favicon_link
      return unless seo.favicon

      link(rel: "icon", href: seo.favicon)
    end

    def robots_meta
      return unless seo.robots

      meta(name: "robots", content: seo.robots)
    end

    def theme_color_meta
      return unless seo.theme_color

      meta(name: "theme-color", content: seo.theme_color)
    end

    # The og:image as an absolute-when-possible URL: an already-absolute
    # og_image is returned as-is; a relative path is joined onto the resolved
    # base (config.seo.site_url or the request base); with no base it degrades to
    # the raw path so og:image is never empty.
    def og_image_url
      image = seo.og_image
      return if image.to_s.empty?
      return image if absolute?(image)

      base = base_url
      base ? "#{base}/#{image.delete_prefix('/')}" : image
    end

    # The canonical/og:url for this page. From config.seo.site_url when set (its
    # path is honored verbatim so a site can point canonical at a specific URL),
    # else the request's original URL. nil when neither is available (an isolated
    # render), so canonical/og:url are simply omitted.
    def canonical_url
      return seo.site_url if seo.site_url
      return unless request?

      request.original_url
    end

    # The base URL for absolutizing a relative og:image: config.seo.site_url's
    # origin, else the request base URL, else nil. site_url may include a path
    # (for canonical); strip it to an origin so the image path joins cleanly.
    def base_url
      return origin_of(seo.site_url) if seo.site_url
      return unless request?

      request.base_url
    end

    def absolute?(url) = url.to_s.match?(%r{\Ahttps?://}i)

    # Just the scheme+host(+port) of a URL, dropping any path — so joining an
    # image path onto it never doubles a path segment.
    def origin_of(url)
      uri = URI.parse(url)
      port = uri.port && uri.default_port != uri.port ? ":#{uri.port}" : ""
      "#{uri.scheme}://#{uri.host}#{port}"
    rescue URI::InvalidURIError
      url
    end

    # True only when there's a live Rails view context AND a request on it — the
    # phlex-rails #request helper delegates to view_context, which raises without
    # one. Mirrors Shell#csp_nonce's guard so an isolated Phlex render (the specs,
    # a request-less static build) degrades cleanly instead of raising.
    def request? = !view_context.nil? && !request.nil?
  end
end
