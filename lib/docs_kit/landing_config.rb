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
  end
end
