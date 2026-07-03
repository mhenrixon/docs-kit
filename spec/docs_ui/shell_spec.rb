# frozen_string_literal: true

# The full document uses OUTPUT helpers (csrf_meta_tags, stylesheet_link_tag,
# importmap tags) that require a live Rails view context, so — like a real
# isolated Phlex render with no request — we exercise the theme-restore fragment
# through a tiny subclass whose view_template renders only that method.
# (phlex-rails and its ActiveSupport core-exts are loaded in spec_helper.)
RSpec.describe DocsUI::Shell do
  # Renders ONLY the theme-restore <script>. In isolation (no Rails request)
  # #csp_nonce returns nil, exactly as it would on a host that doesn't nonce
  # script-src.
  let(:script_only) do
    Class.new(described_class) do
      def view_template = theme_restore_script
    end
  end

  # Same fragment, but with a nonce present — mirrors a host app enforcing a
  # nonce-based script-src. In a real request #csp_nonce reads the request's CSP
  # nonce off the view context; here (no request) we override that seam so the
  # nonce path is exercised exactly as production would render it.
  let(:script_with_nonce) do
    Class.new(described_class) do
      def view_template = theme_restore_script
      def csp_nonce = "testnonce"
    end
  end

  describe "the theme-restore script" do
    it "renders the theme-restore JS" do
      html = script_only.new.call

      expect(html).to include("<script")
      expect(html).to include("localStorage.getItem")
      expect(html).to include('setAttribute("data-theme"')
      expect(html).to include('addEventListener("turbo:load"')
    end

    context "when there is no CSP nonce (isolated render / host without a nonce)" do
      it "emits a <script> with NO nonce attribute" do
        html = script_only.new.call

        expect(html).to include("<script>")
        expect(html).not_to include("nonce")
      end
    end

    context "when a CSP nonce is present (nonce-based script-src)" do
      it "carries the nonce on the <script> so the browser does not block it" do
        html = script_with_nonce.new.call

        expect(html).to include('<script nonce="testnonce">')
        # Still the same theme-restore behavior — the nonce is additive only.
        expect(html).to include("localStorage.getItem")
      end
    end
  end

  # The topbar brand link is a config knob so a site can point it at /docs
  # instead of / without subclassing Shell to copy-paste #topbar.
  describe "the topbar brand link" do
    # Renders ONLY the topbar so we don't need a live Rails view context for the
    # rest of the document (importmap/csrf tags require a real request).
    let(:topbar_only) do
      Class.new(described_class) do
        def view_template = topbar
      end
    end

    it "defaults the brand href to \"/\"" do
      html = topbar_only.new.call

      expect(html).to include('href="/"')
    end

    it "follows config.brand_href when a site overrides it" do
      DocsKit.configure { |c| c.brand_href = "/docs" }
      html = topbar_only.new.call

      expect(html).to include('href="/docs"')
    end
  end

  # The topbar search form is the JS-off search entry point: a plain GET form to
  # config.search_path with an input named "q". It renders only when search is
  # enabled, so a site can opt out with c.search = false.
  describe "the topbar search form" do
    let(:topbar_only) do
      Class.new(described_class) do
        def view_template = topbar
      end
    end

    it "renders a GET form to config.search_path with a q input by default" do
      html = topbar_only.new.call

      expect(html).to include('action="/docs/search"')
      expect(html).to include('method="get"')
      expect(html).to include('name="q"')
    end

    it "points the form at config.search_path when a site overrides it" do
      DocsKit.configure { |c| c.search_path = "/guides/search" }
      html = topbar_only.new.call

      expect(html).to include('action="/guides/search"')
    end

    it "omits the form when search is disabled (c.search = false)" do
      DocsKit.configure { |c| c.search = false }
      html = topbar_only.new.call

      expect(html).not_to include('name="q"')
    end

    it "wires the input as a docs-nav target so the palette can enhance it" do
      html = topbar_only.new.call

      # The one docs-nav controller enhances the form into a Cmd+K palette; the
      # input is a target and typing triggers performSearch.
      expect(html).to include("docs-nav-target")
      expect(html).to include("docs-nav#")
    end
  end

  # The topbar renders config.topbar_links (DocsUI::TopbarLinks) BEFORE the theme
  # switcher. The link rendering itself is covered in topbar_links_spec; here we
  # only prove the Shell wires them into the topbar in the right position.
  describe "the topbar links (repo/social)" do
    let(:topbar_only) do
      Class.new(described_class) do
        def view_template = topbar
      end
    end

    it "renders configured links before the theme switcher" do
      DocsKit.configure do |c|
        c.topbar_links = [{ href: "https://github.com/me/repo", label: "GitHub", icon: :github }]
      end
      html = topbar_only.new.call

      link = html.index('href="https://github.com/me/repo"')
      theme = html.index("theme-dropdown")
      expect(link).to be_truthy
      expect(link).to be < theme
    end

    it "leaves the topbar unchanged when no links are configured" do
      html = topbar_only.new.call

      expect(html).not_to include("<title>GitHub</title>")
    end
  end

  # The head renders DocsUI::MetaTags from the page title/description + config.
  # The tag rendering itself is covered in meta_tags_spec; here we only prove the
  # Shell threads title/description through. render_head calls output helpers that
  # need a live request (csrf/importmap), so render ONLY the meta-tags fragment via
  # a subclass that exposes it — the same fragment-render approach as above.
  describe "the SEO/social meta tags" do
    let(:meta_only) do
      Class.new(described_class) do
        def view_template
          render DocsUI::MetaTags.new(title: @title, description: @description)
        end
      end
    end

    it "threads the page title into og:title (page · suffix)" do
      DocsKit.configure { |c| c.brand = "Docs" }
      html = meta_only.new(title: "Installation").call

      expect(html).to include('<meta property="og:title" content="Installation · Docs">')
    end

    it "threads a page description into the description meta" do
      html = meta_only.new(title: "Installation", description: "Add the gem.").call

      expect(html).to include('<meta name="description" content="Add the gem.">')
    end

    it "still renders a valid OG block when no description is given (backwards compat)" do
      html = meta_only.new(title: "Installation").call

      expect(html).to include('property="og:title"')
      expect(html).not_to include('name="description"')
    end
  end

  # A focused proof of the primitive the whole fix relies on: Phlex omits an
  # attribute whose value is nil (it does NOT render nonce=""), so the
  # no-nonce path degrades cleanly to the pre-fix, un-nonced markup.
  describe "Phlex nil-attribute omission (the graceful-degradation primitive)" do
    let(:nil_vs_value) do
      Class.new(Phlex::HTML) do
        def view_template
          script(nonce: nil) { plain "a" }
          style(nonce: "n") { plain "b" }
        end
      end
    end

    it "omits a nil-valued attribute and renders a real one" do
      html = nil_vs_value.new.call

      expect(html).to include("<script>a</script>")
      expect(html).to include('<style nonce="n">b</style>')
    end
  end
end
