# frozen_string_literal: true

module DocsKit
  # The normalized brand mark for the shell chrome (config.brand_logo) and the
  # landing hero (config.landing.logo). A site configures a Hash in exactly one
  # of five forms; DocsUI::Logo renders the result:
  #
  #   { svg: "M0 0Z", viewbox: "0 0 24 24", label: "Acme" }   # one path-d (landing-compat)
  #   { paths: ["M0 0Z", "M4 4Z"], viewbox: "…", label: "…" } # multi-path wordmark
  #   { markup: "<svg …>…</svg>", label: "Acme" }             # raw SVG markup, embedded verbatim
  #   { file: "app/assets/images/mark.svg", label: "Acme" }   # a .svg file, embedded inline
  #   { src: "logo.png", alt: "Acme" }                        # an <img> (not theme-adaptive)
  #
  # The svg:/paths: forms render each `d` as an ordinary Phlex-escaped attribute.
  # The markup:/file: forms embed SITE-AUTHORED markup verbatim (see DocsUI::Logo
  # for the trust rationale); both are shape-checked here — the content must be an
  # <svg> element — so a mis-pasted snippet fails loudly at config time, never as
  # a silently broken (or script-bearing) header. Mixing forms, or giving none,
  # is ambiguous config and raises. `label`/`alt` fall back to each other so
  # either knob names the mark for assistive tech.
  #
  # A file: mark memoizes its content and re-reads on an mtime change (the
  # Configuration#openapi_document posture), so editing the SVG in development
  # shows up without a server restart.
  class BrandLogo
    # The config keys that each select a render form — exactly one must be given.
    FORM_KEYS = %i[svg paths markup file src].freeze

    # A loose "is this an <svg> element" shape check for the markup:/file: forms.
    SVG_SHAPE = /\A\s*<svg[\s>]/i

    DEFAULT_VIEWBOX = "0 0 24 24"

    attr_reader :paths, :viewbox, :markup, :file, :src

    # Coerce a config value (Hash with symbol or string keys, or an
    # already-normalized BrandLogo) into a BrandLogo.
    def self.from(logo)
      return logo if logo.is_a?(self)

      new(logo.to_h)
    end

    def initialize(attrs = {})
      attrs = attrs.transform_keys(&:to_sym)
      given = attrs.slice(*FORM_KEYS).compact
      unless given.size == 1
        raise ArgumentError,
              "brand_logo takes exactly one of #{FORM_KEYS.inspect} (got #{given.keys.inspect})"
      end

      @viewbox = attrs[:viewbox] || DEFAULT_VIEWBOX
      @label = attrs[:label]
      @alt = attrs[:alt]
      build_form(given.keys.first, attrs)
    end

    # The single path-d, for the landing-compat svg: shape (first of #paths).
    def svg = paths&.first

    def inline? = !paths.nil?
    def markup? = !markup.nil?
    def file? = !file.nil?
    def image? = !src.nil?

    # Whether the mark embeds site-authored markup verbatim (markup: or file:).
    def embed? = markup? || file?

    # The accessible name — label falls back to alt (and vice versa) so a site
    # setting either names the mark; nil defers to the render-time brand fallback.
    def label = @label || @alt
    def alt = @alt || @label

    # The markup to embed: the literal markup: string, or the file's content —
    # memoized per mtime so a dev edit re-reads without a restart.
    def svg_markup
      return @markup if markup?

      mtime = begin
        @file.mtime
      rescue StandardError
        nil
      end
      return @file_content if defined?(@file_content) && @file_mtime == mtime

      @file_mtime = mtime
      @file_content = check_svg_shape!(@file.read, "file #{@file}")
    end

    private

    # Store the one given form. file: primes #svg_markup immediately so a bad
    # file fails at config time (boot), not on first render.
    def build_form(form, attrs)
      case form
      when :svg, :paths then @paths = Array(attrs[:paths] || attrs[:svg]).map(&:to_s)
      when :markup then @markup = check_svg_shape!(attrs[:markup].to_s, "markup")
      when :src then @src = attrs[:src]
      when :file
        @file = resolve_file!(attrs[:file])
        svg_markup
      end
    end

    # Validate + resolve the file: form eagerly, so a bad path fails at config
    # time (boot), not on first render. Relative paths resolve against Rails.root
    # when Rails is loaded, else the process working directory.
    def resolve_file!(file)
      path = Pathname.new(file.to_s)
      path = Rails.root.join(path) if path.relative? && defined?(Rails) && Rails.respond_to?(:root) && Rails.root
      raise ArgumentError, "brand_logo file must be a .svg (got #{path.basename})" unless path.extname.casecmp?(".svg")
      raise ArgumentError, "brand_logo file not found: #{path}" unless path.file?

      path
    end

    # The markup:/file: shape guard — the content must BE an <svg> element.
    def check_svg_shape!(content, source)
      return content if content.match?(SVG_SHAPE)

      raise ArgumentError, "brand_logo #{source} must be an <svg> element (got #{content[0, 40].inspect})"
    end
  end
end
