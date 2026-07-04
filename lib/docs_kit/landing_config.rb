# frozen_string_literal: true

module DocsKit
  # The per-site landing-page knobs, read by DocsUI::Landing to render a marketing
  # home page (hero + feature grid + doc index) without a site hand-rolling one.
  # Nested under DocsKit::Configuration#landing so a site configures it as a block:
  #
  #   DocsKit.configure do |c|
  #     c.landing.eyebrow = "Developer Docs"
  #     c.landing.title   = "Jobs & events on Postgres"   # highlight a run with **…**
  #     c.landing.lead    = "PostgreSQL-native job processing and event bus for Rails."
  #     c.landing.install = { code: 'gem "pgbus"', filename: "Gemfile", lexer: :ruby }
  #     c.landing.ctas = [
  #       { label: "Get started", href: "/docs/overview", style: :primary },
  #       { label: "GitHub",      href: "https://github.com/me/repo", style: :ghost, icon: :github },
  #     ]
  #     c.landing.features = [
  #       { icon: "database", title: "One database", body: "No Redis, no broker." },
  #       { icon: "zap",      title: "Fast",         body: "…" },
  #     ]
  #   end
  #
  # Every field is optional and defaults to a backwards-safe value: a site that
  # sets none still renders a minimal hero (the brand + a doc index), never a
  # broken page. Plain accessors (not Data.define) because each field is
  # individually assignable in the `c.landing.x = ...` block, mirroring
  # DocsKit::SeoConfig.
  class LandingConfig
    # An optional brand logo/mark rendered at the top of the hero (above the
    # eyebrow), like a product wordmark. A Hash in one of two forms:
    #   { svg: "<path d …>", viewbox: "0 0 81 45", label: "Brand" }  # inline mark
    #   { src: "logo.svg", alt: "Brand" }                            # image asset/URL
    # The inline `svg` form renders with `fill: currentColor` so it adapts to the
    # theme (light/dark) — best for a single-color mark. nil omits the logo.
    # See #hero_logo (the normalized Logo value object) and DocsUI::Landing.
    attr_writer :logo

    # A small uppercase kicker above the title (e.g. "Developer Docs"). nil omits it.
    attr_accessor :eyebrow

    # The hero <h1>. Wrap a run in **double asterisks** to render it in the primary
    # color (e.g. "Jobs & events on **Postgres**"). nil falls back to the brand.
    attr_accessor :title

    # The muted lead paragraph under the title. nil falls back to the tagline.
    attr_accessor :lead

    # An optional install/quickstart code block shown in the hero, as a Hash:
    #   { code: "gem \"x\"", filename: "Gemfile", lexer: :ruby }
    # nil omits the block. See #install_snippet for the normalized form.
    attr_accessor :install

    # Whether to render the registry-grouped documentation index below the hero
    # (the "Documentation" section linking every authored page). Default true.
    attr_writer :doc_index

    # The hero call-to-action buttons, each a Hash normalized into a Cta:
    #   { label:, href:, style: :primary|:ghost (default :ghost), icon: (brand/lucide token) }
    attr_writer :ctas

    # The feature cards shown in a grid under the hero, each a Hash normalized into
    # a Feature: { icon: (lucide name), title:, body: }.
    attr_writer :features

    def initialize
      @doc_index = true
      @ctas = []
      @features = []
    end

    # Whether the doc index is shown (default true).
    def doc_index? = @doc_index != false

    # The CTAs as normalized Cta value objects (empty when unset).
    def ctas
      Array(@ctas).map { |cta| Cta.from(cta) }
    end

    # The features as normalized Feature value objects (empty when unset).
    def features
      Array(@features).map { |feature| Feature.from(feature) }
    end

    # The install block normalized to { code:, filename:, lexer: } with a sensible
    # default lexer, or nil when unset.
    def install_snippet
      return if @install.nil?

      attrs = @install.to_h.transform_keys(&:to_sym)
      { code: attrs[:code].to_s, filename: attrs[:filename], lexer: (attrs[:lexer] || :shell).to_sym }
    end

    # The hero logo as a normalized Logo value object, or nil when unset.
    def hero_logo
      return if @logo.nil?

      Logo.from(@logo)
    end

    # One hero call-to-action button. `style` maps to a daisyUI btn variant
    # (:primary → btn-primary, anything else → btn-ghost). `icon` is an optional
    # brand/lucide token rendered before the label (DocsUI::BrandMark resolves it).
    Cta = Data.define(:label, :href, :style, :icon) do
      def initialize(label:, href:, style: :ghost, icon: nil)
        super(label:, href:, style: style&.to_sym, icon: icon)
      end

      def self.from(cta)
        return cta if cta.is_a?(self)

        attrs = cta.to_h.transform_keys(&:to_sym)
        new(label: attrs[:label], href: attrs[:href], style: attrs[:style] || :ghost, icon: attrs[:icon])
      end

      # The daisyUI button class for this CTA's style.
      def btn_class = style == :primary ? "btn btn-primary" : "btn btn-ghost"

      # Whether the href points off-site (absolute http/https) — the component adds
      # target=_blank + rel=noopener only for external links.
      def external? = href.to_s.match?(%r{\Ahttps?://}i)
    end

    # One feature card: a lucide icon name, a title, and a short body.
    Feature = Data.define(:icon, :title, :body) do
      def initialize(title:, icon: nil, body: nil)
        super
      end

      def self.from(feature)
        return feature if feature.is_a?(self)

        attrs = feature.to_h.transform_keys(&:to_sym)
        new(icon: attrs[:icon], title: attrs[:title], body: attrs[:body])
      end
    end

    # The hero brand logo — either an inline single-path SVG mark (`svg` = the
    # `<path d>` data, `viewbox` = its viewBox) rendered with fill: currentColor so
    # it adapts to the theme, OR an image (`src` = an asset path/URL, `alt` = its
    # accessible name). `label` is the accessible name for the inline mark.
    Logo = Data.define(:svg, :viewbox, :src, :alt, :label) do
      def initialize(svg: nil, viewbox: "0 0 24 24", src: nil, alt: nil, label: nil)
        super
      end

      def self.from(logo)
        return logo if logo.is_a?(self)

        attrs = logo.to_h.transform_keys(&:to_sym)
        new(
          svg: attrs[:svg], viewbox: attrs[:viewbox] || "0 0 24 24",
          src: attrs[:src], alt: attrs[:alt], label: attrs[:label]
        )
      end

      # An inline SVG mark (vs. an <img>). True when `svg` path data is present.
      def inline? = !svg.to_s.empty?
    end
  end
end
