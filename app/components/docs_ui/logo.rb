# frozen_string_literal: true

module DocsUI
  # Renders a DocsKit::BrandLogo (config.brand_logo / config.landing.logo) as the
  # brand mark — an inline currentColor <svg> (theme-adaptive), a verbatim
  # site-authored <svg> embed, or an <img>.
  #
  #   render DocsUI::Logo.new(config.brand_logo, class: "h-6 w-auto", label: config.brand)
  #
  # label: is the accessible-name fallback when the logo itself carries none
  # (callers pass config.brand, so the mark always announces the site).
  #
  # The svg:/paths: forms emit each path-d as an ordinary Phlex-escaped
  # attribute — config free text never bypasses the escape. The markup:/file:
  # forms DO embed markup verbatim via raw(safe(...)): that content is the
  # site's own deliberately-configured SVG (its initializer / its asset file —
  # the same trust domain as the site's own views, which can already render
  # anything), not third-party free text, and DocsKit::BrandLogo shape-checks it
  # to be an <svg> element at config time. That authored-by-the-trusting-site
  # rationale is the same carve-out DocsUI::BrandMark uses for its gem-authored
  # path constants.
  class Logo < Phlex::HTML
    # For the src: image form — resolve the asset path through the site's
    # pipeline to its digested /assets URL, exactly like DocsUI::Landing's img.
    include Phlex::Rails::Helpers::ImageURL

    def initialize(logo, label: nil, **attributes)
      @logo = DocsKit::BrandLogo.from(logo)
      @label = label
      @attributes = attributes
    end

    def view_template
      if @logo.image?
        img(src: resolved_src, alt: accessible_name.to_s, **@attributes)
      elsif @logo.embed?
        embedded_svg
      else
        inline_svg
      end
    end

    private

    def accessible_name = @logo.label || @label

    # The svg:/paths: forms: a currentColor mark that recolors with the active
    # daisyUI theme; every path-d is an escaped attribute value.
    def inline_svg
      svg(viewBox: @logo.viewbox, fill: "currentColor", role: "img",
          aria_label: accessible_name, **@attributes) do |s|
        s.title { accessible_name } if accessible_name
        @logo.paths.each { |d| s.path(d: d) }
      end
    end

    # The markup:/file: forms: the site's own <svg> embedded verbatim (see the
    # class comment for the trust rationale) inside a wrapper that carries the
    # caller's sizing — the inner svg fills it. Literal arbitrary variants so
    # Tailwind scans them from this file.
    def embedded_svg
      classes = [@attributes[:class], "inline-flex [&>svg]:h-full [&>svg]:w-auto"].compact.join(" ")
      span(role: "img", aria_label: accessible_name, **@attributes, class: classes) do
        raw(safe(@logo.svg_markup))
      end
    end

    # The digested asset URL when a view context is present; off a request (an
    # isolated render) degrade to the raw src — the DocsUI::MetaTags posture.
    def resolved_src
      view_context ? image_url(@logo.src) : @logo.src
    end
  end
end
