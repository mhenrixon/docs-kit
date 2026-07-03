# frozen_string_literal: true

require "erb"
require "yaml"
require "rails/generators/base"
require_relative "sync_report"

module DocsKit
  module Generators
    # `rails g docs_kit:install`
    #
    # Wires an existing Rails app into docs-kit: the config initializer, the
    # controller render helper, a Doc registry + a sample guide page + route, the
    # Bun/Tailwind CSS build, and the Stimulus + importmap registration. Run it in
    # a fresh `rails new` app (the new-site template does exactly this), or on top
    # of an existing app to add a docs section.
    #
    # Fully idempotent — safe on a fresh app AND a years-old site, which makes
    # re-running it the sanctioned upgrade path. Every step guards a re-run: the
    # config initializer is skipped (never clobbered); routes are skipped even
    # when the site wrote them in its own style (single quotes, `to:` vs `=>`);
    # file creations skip what already exists. `--sync` runs ONLY the additive
    # wiring (routes, initializer hint, importmap/stimulus, AGENTS.md, .rubocop)
    # and prints a checklist of manual drift it can't safely automate.
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      # `--sync`: the upgrade path for an existing site. Runs the wiring steps
      # (idempotent) and skips scaffolding site-owned content (the doc registry,
      # sample pages, the CSS build) — those already exist and are the site's.
      class_option :sync, type: :boolean, default: false,
                          desc: "Upgrade an existing site: re-run wiring only, report drift, scaffold no content"

      # eagerLoadControllersFrom (NOT lazy) — the default controllers/index.js only
      # imports eagerLoadControllersFrom; injecting a lazyLoadControllersFrom call
      # without its import throws a ReferenceError that aborts the whole module, so
      # NO controllers register. Eager-loading a few docs controllers is fine.
      REGISTER_LINE = 'eagerLoadControllersFrom("docs_kit/controllers", application)'

      # The delimiters bounding the gem-owned block inside AGENTS.md. Everything
      # outside them is the user's; a re-run only rewrites what's between them.
      AGENTS_BEGIN = "<!-- BEGIN docs-kit -->"
      AGENTS_END   = "<!-- END docs-kit -->"
      AGENTS_BLOCK_RE = /#{Regexp.escape(AGENTS_BEGIN)}.*#{Regexp.escape(AGENTS_END)}/m

      # The RuboCop wiring docs-kit injects. REQUIRE loads the cops;
      # INHERIT_GEM/INHERIT_PATH enable + scope them (see config/rubocop/docs_kit.yml).
      RUBOCOP_REQUIRE = "docs_kit/rubocop"
      RUBOCOP_INHERIT_GEM = "docs-kit"
      RUBOCOP_INHERIT_PATH = "config/rubocop/docs_kit.yml"

      # The .rubocop.yml written when a site has none yet.
      RUBOCOP_STARTER = <<~YAML.freeze
        # docs-kit ships its custom cops from the gem — load + enable them here.
        # (RuboCop is a development-time dependency; add `gem "rubocop"` to your
        # Gemfile if it isn't there.)
        require:
          - #{RUBOCOP_REQUIRE}

        inherit_gem:
          #{RUBOCOP_INHERIT_GEM}: #{RUBOCOP_INHERIT_PATH}

        AllCops:
          NewCops: enable
      YAML

      def create_phlex_initializer
        # Phlex autoload namespaces (Views:: / Components::). Skip if the app
        # already configures phlex-rails so we don't clobber a bespoke setup.
        existing = Dir[File.join(destination_root, "config/initializers/*.rb")]
                   .any? { |f| File.read(f).include?("push_dir") && File.read(f).match?(/namespace:\s*Views/) }
        return say_status(:skip, "phlex namespaces already configured", :blue) if existing

        empty_directory "app/components"
        create_file "app/components/.keep", "" unless File.exist?(File.join(destination_root, "app/components/.keep"))
        template "phlex.rb.erb", "config/initializers/phlex.rb"
      end

      def create_rails_icons_initializer
        icons = "config/initializers/rails_icons.rb"
        return say_status(:skip, icons, :blue) if File.exist?(File.join(destination_root, icons))

        template "rails_icons.rb.erb", icons
      end

      # The site's config (brand, themes, nav) lives here and is heavily edited,
      # so a re-run must NEVER clobber it. Skip when present and point an upgrader
      # at the current template for a manual diff. (create_rails_icons_initializer
      # and create_phlex_initializer already follow this skip-if-exists pattern.)
      def create_initializer
        initializer = "config/initializers/docs_kit.rb"
        if File.exist?(File.join(destination_root, initializer))
          template_path = File.join(self.class.source_root, "docs_kit.rb.erb")
          return say_status(:skip, "#{initializer} exists — compare with #{template_path} if upgrading", :blue)
        end

        template "docs_kit.rb.erb", initializer
      end

      def include_controller_helper
        controller = "app/controllers/application_controller.rb"
        return say_status(:skip, "#{controller} not found — include DocsKit::Controller manually", :yellow) \
          unless File.exist?(File.join(destination_root, controller))

        if File.read(File.join(destination_root, controller)).include?("DocsKit::Controller")
          return say_status(:identical, controller, :blue)
        end

        inject_into_class controller, "ApplicationController", "  include DocsKit::Controller\n"
      end

      # Site-owned content — the doc registry, its controllers, the sample guide
      # page, the landing. A `--sync` upgrade never scaffolds these: they exist
      # and are the site's to edit.
      def create_registry_and_pages
        return say_status(:skip, "site content (--sync: registry/pages are yours)", :blue) if options[:sync]

        template "doc.rb.erb", "app/models/doc.rb"
        template "docs_controller.rb.erb", "app/controllers/docs_controller.rb"
        template "landings_controller.rb.erb", "app/controllers/landings_controller.rb"
        template "installation_page.rb.erb", "app/views/docs/pages/installation.rb"
        template "landing.rb.erb", "app/views/landings/show.rb"
      end

      def add_routes
        # The `(.:format)` segment enables the Markdown twin: GET /docs/x.md hits
        # docs#show with request.format.md?, so DocsKit::Controller#render_page
        # returns the page's GFM. No `defaults: { format: "html" }` — that would
        # pin html and defeat the .md route.
        route_once %(get "docs/:doc(.:format)" => "docs#show", as: :doc)
        # Docs search, served from the registry by the gem's DocsKit::SearchController
        # (matches the default c.search_path). Thor's `route` PREPENDS, so this call
        # — after the docs route above — lands ABOVE `docs/:doc` in the file, where
        # it must be: otherwise `docs/:doc` would swallow /docs/search as :doc.
        route_once %(get "/docs/search" => "docs_kit/search#index", as: :docs_search)
        route_once %(root "landings#show")

        # AI-readable docs (llmstxt.org), served from the registry by the gem's
        # DocsKit::LlmsController — zero authoring. /llms.txt is the index;
        # /llms-full.txt concatenates every page's Markdown twin.
        route_once %(get "/llms.txt" => "docs_kit/llms#index", as: :llms)
        route_once %(get "/llms-full.txt" => "docs_kit/llms#full", as: :llms_full)

        add_mcp_route
      end

      # The read-only MCP endpoint (DocsKit::McpController), drawn COMMENTED OUT
      # because it needs the OPTIONAL `mcp` gem — the generator can't assume it's
      # bundled. A site opts in by adding `gem "mcp"` and uncommenting these. POST
      # speaks JSON-RPC; GET/DELETE 405 (read-only, stateless — no SSE session).
      # `route` prepends, so drawing `match` before `post` leaves `post` on top.
      def add_mcp_route
        route %(# match "/mcp" => "docs_kit/mcp#method_not_allowed", via: %i[get delete])
        route %(# post "/mcp" => "docs_kit/mcp#create")
        route %(# Add your docs to an agent over MCP (needs `gem "mcp"`):)
      end

      # The CSS build — its stylesheet carries the site's theme @plugin block, so
      # a `--sync` upgrade leaves it alone (an existing site has already built +
      # customized it).
      def create_css_build
        return say_status(:skip, "CSS build (--sync: application.tailwind.css is yours)", :blue) if options[:sync]

        template "application.tailwind.css.erb", "app/assets/stylesheets/application.tailwind.css"
        template "build-css", "bin/build-css"
        chmod "bin/build-css", 0o755
        template "build_css.rake", "lib/tasks/build_css.rake"
        create_file "app/assets/builds/.keep", ""
      end

      # Install the `docs_kit:og` rake task — gem-owned wiring, refreshed on every
      # run so a site picks up task fixes. It does NOT ship an OG image: the
      # social-share image is SITE content, generated into the site's OWN
      # app/assets/images/ by `bin/rails docs_kit:og`. Until a site runs it (and
      # sets c.seo.og_image), no og:image tag is emitted — a valid card, never a
      # 404 for an image the gem can't provide.
      def create_og_task
        template "docs_kit_og.rake", "lib/tasks/docs_kit_og.rake"
      end

      def wire_assets_and_package_json
        # Serve the bun-built CSS from app/assets/builds.
        inject_into_file "config/initializers/assets.rb",
                         %(\nRails.application.config.assets.paths << Rails.root.join("app", "assets", "builds")\n),
                         after: /Rails.application.config.assets.version.*\n/, verbose: false

        add_package_json_scripts
      end

      # AI-authoring scaffold: an AGENTS.md (the cross-tool authoring contract)
      # and a Claude Code skill (.claude/skills/write-docs-page/SKILL.md). Both
      # encode how to write a docs-kit page so "document this" works out of the
      # box. Idempotent: a fresh AGENTS.md is created whole; an existing one gets
      # only its delimited docs-kit block replaced (the user's own content is
      # never touched); the skill file is skipped if it already exists.
      def create_agent_docs
        write_agents_md
        write_write_docs_page_skill
      end

      # Wire docs-kit's shipped RuboCop cops into the site's .rubocop.yml: a
      # `require: docs_kit/rubocop` entry (loads the cops) plus an
      # `inherit_gem: { docs-kit: config/rubocop/docs_kit.yml }` entry (enables
      # + scopes them). RuboCop is a dev-time dependency the host already has —
      # docs-kit never requires it at runtime. Created minimal when absent,
      # MERGED into an existing config (a `rails new` app ships an omakase
      # inherit_gem we must not drop), and idempotent on re-run.
      def wire_rubocop_cops
        path = File.join(destination_root, ".rubocop.yml")
        return create_file(".rubocop.yml", RUBOCOP_STARTER) unless File.exist?(path)

        existing = File.read(path)
        merged = merge_rubocop_config(existing)
        return say_status(:identical, ".rubocop.yml", :blue) if merged == existing

        File.write(path, merged)
        say_status(:update, ".rubocop.yml (docs-kit cops)", :green)
      end

      def register_stimulus_controller
        index = stimulus_index_path
        return say_status(:skip, "no controllers/index.js — add: #{REGISTER_LINE}", :yellow) unless index
        # Skip if the docs_kit path is already registered via EITHER loader — a
        # site that wired it lazily is valid (the engine auto-pins it); injecting
        # our eager line would duplicate the registration. Quote-style tolerant.
        return say_status(:identical, relative(index), :blue) if stimulus_registered?(index)

        inject_into_file index, after: /eagerLoadControllersFrom\([^\n]*\n/ do
          "#{REGISTER_LINE}\n"
        end
        return if stimulus_registered?(index) # inject handled it

        # No eager anchor to inject after: only append the eager line if the file
        # actually imports eagerLoadControllersFrom — appending it to a lazy-only
        # index.js writes a call with no import, a ReferenceError that aborts the
        # module and registers ZERO controllers (the failure REGISTER_LINE warns
        # of). A lazy-only file is valid, so warn instead of breaking it.
        unless File.read(index).match?(/import\s*\{[^}]*eagerLoadControllersFrom/)
          return say_status(:skip, "#{relative(index)} doesn't eager-load — add: #{REGISTER_LINE}", :yellow)
        end

        append_to_file(index, "\n#{REGISTER_LINE}\n")
      end

      # Detect + print manual drift the generator can't safely automate (a
      # hand-written render_page, a dead IconHelper). String-level and
      # conservative — it warns, never deletes, and never fails the run. Runs on
      # every invocation; it's the headline deliverable of a `--sync` upgrade.
      def report_drift
        report = SyncReport.new(destination_root)
        return if report.clean?

        say_status :warn, "manual cleanup needed (docs-kit now provides these):", :yellow
        report.items.each { |item| say "  • #{item}" }
      end

      def show_post_install
        return show_sync_summary if options[:sync]

        say_status :info, "docs-kit installed.", :green
        say <<~MSG

          Next:
            1. bin/rails g rails_icons:sync --library=lucide  # sync the lucide icon set
            2. bun install && bun run build:css       # build the daisyUI/Tailwind CSS
            3. Edit config/initializers/docs_kit.rb   # brand, themes, nav
            4. Add pages under app/views/docs/pages/  # subclass DocsUI::Page
            5. bin/dev  (or bin/rails server)

          Requires importmap-rails (the shell loads assets via javascript_importmap_tags)
          and a Stimulus controllers/index.js — the new-site template sets both up.
        MSG
      end

      private

      def show_sync_summary
        say_status :info, "docs-kit synced.", :green
        say <<~MSG

          Next:
            1. Act on any drift warnings above (delete the flagged files).
            2. bun run build:css   # pick up any new emitted classes
            3. bundle exec rspec   # confirm the site still boots + renders
        MSG
      end

      # Create AGENTS.md whole when absent; otherwise replace only the delimited
      # docs-kit block (or append it if the file predates docs-kit), leaving the
      # user's own content intact.
      def write_agents_md
        path = File.join(destination_root, "AGENTS.md")
        rendered = render_template("agents_md.erb")

        return create_file("AGENTS.md", rendered) unless File.exist?(path)

        existing = File.read(path)
        block = extract_agents_block(rendered)
        updated = merge_agents_block(existing, block)
        return say_status(:identical, "AGENTS.md", :blue) if updated == existing

        File.write(path, updated)
        say_status(:update, "AGENTS.md (docs-kit block)", :green)
      end

      # The BEGIN…END docs-kit block (inclusive) sliced out of the rendered
      # template — the unit injected into a pre-existing AGENTS.md.
      def extract_agents_block(rendered)
        rendered[AGENTS_BLOCK_RE]
      end

      # Swap the existing delimited block for the fresh one, or append it when the
      # file has none yet. Idempotent: same block in → same file out.
      def merge_agents_block(existing, block)
        if existing.include?(AGENTS_BEGIN) && existing.include?(AGENTS_END)
          existing.sub(AGENTS_BLOCK_RE, block)
        else
          "#{existing.rstrip}\n\n#{block}\n"
        end
      end

      # Write the write-docs-page Claude Code skill, unless the site already has
      # one (a hand-customized skill is never clobbered).
      def write_write_docs_page_skill
        skill = ".claude/skills/write-docs-page/SKILL.md"
        return say_status(:skip, skill, :blue) if File.exist?(File.join(destination_root, skill))

        create_file skill, render_template("skill.md.erb")
      end

      # Merge docs-kit's require + inherit_gem entries into an existing
      # .rubocop.yml, preserving everything else. Idempotent: entries already
      # present are left untouched, so re-running yields byte-identical output.
      # Returns the (possibly unchanged) YAML string.
      def merge_rubocop_config(existing)
        config = YAML.safe_load(existing) || {}
        config = {} unless config.is_a?(Hash)

        config["require"] = ensure_in_list(config["require"], RUBOCOP_REQUIRE)

        inherit_gem = config["inherit_gem"].is_a?(Hash) ? config["inherit_gem"] : {}
        inherit_gem[RUBOCOP_INHERIT_GEM] = ensure_in_list(inherit_gem[RUBOCOP_INHERIT_GEM], RUBOCOP_INHERIT_PATH)
        config["inherit_gem"] = inherit_gem

        # Round-trip through the same load the merge started from: if nothing
        # changed, return the original text verbatim (so :identical is reported
        # and re-runs don't churn formatting).
        YAML.safe_load(existing) == config ? existing : YAML.dump(config)
      end

      # Normalise a RuboCop scalar-or-list field to an array and append `value`
      # unless already present. `nil` (absent key) becomes `[value]`; a bare
      # string is promoted to a list so we never drop the site's own entry.
      def ensure_in_list(current, value)
        list = Array(current)
        list.include?(value) ? list : list + [value]
      end

      # Render an ERB template from source_root against the generator binding, so
      # helpers like app_brand resolve — used where we need the rendered string in
      # memory (block extraction/merge) rather than Thor's file-to-file `template`.
      def render_template(name)
        source = File.read(File.join(self.class.source_root, name))
        ERB.new(source, trim_mode: "-").result(binding)
      end

      # Draw a route unless the site already has one for the same endpoint —
      # tolerant of the site's own style (single vs double quotes, `to:` vs `=>`,
      # extra whitespace). Thor's `route` only skips a BYTE-IDENTICAL line, so a
      # years-old hand-written routes.rb would get a duplicate; this guard makes
      # re-running a genuine no-op. We never rewrite the site's line — drift is
      # warned, not auto-edited.
      def route_once(routing_code)
        return route(routing_code) unless route_present?(routing_code)

        say_status(:identical, "route #{route_endpoint(routing_code)} (already drawn)", :blue)
      end

      # True if config/routes.rb already draws this route's endpoint. Matches the
      # `controller#action` string in any quote style, or — for `root` — the bare
      # `root` keyword (a file has at most one).
      def route_present?(routing_code)
        path = File.join(destination_root, "config/routes.rb")
        return false unless File.exist?(path)

        endpoint = route_endpoint(routing_code)
        routes = File.read(path)
        return routes.match?(/^\s*root\b/) if endpoint == :root

        routes.match?(/["']#{Regexp.escape(endpoint)}["']/)
      end

      # The endpoint a route targets: `:root` for a root route, else its
      # `controller#action` string (e.g. "docs#show", "docs_kit/search#index").
      def route_endpoint(routing_code)
        return :root if routing_code.match?(/\Aroot\b/)

        routing_code[%r{["']([\w/]+#\w+)["']}, 1]
      end

      def add_package_json_scripts
        pkg = File.join(destination_root, "package.json")
        return create_file("package.json", package_json_stub) unless File.exist?(pkg)

        json = File.read(pkg)
        return if json.include?('"build:css"')

        say_status :info, "add these scripts to package.json:\n#{package_json_scripts}", :yellow
      end

      def package_json_scripts
        <<~JSON.strip
          "build:css": "bin/build-css --minify",
          "watch:css": "bin/build-css --watch"
        JSON
      end

      def package_json_stub
        <<~JSON
          {
            "private": true,
            "scripts": {
              "build:css": "bin/build-css --minify",
              "watch:css": "bin/build-css --watch"
            },
            "devDependencies": {
              "@tailwindcss/cli": "^4.1.18",
              "daisyui": "^5.6.0",
              "tailwindcss": "^4.1.18"
            }
          }
        JSON
      end

      def stimulus_index_path
        %w[app/javascript/controllers/index.js]
          .map { |rel| File.join(destination_root, rel) }.find { |p| File.exist?(p) }
      end

      # True if the index already registers the docs_kit controllers path — via
      # eager OR lazy loading, any quote style. A site that wired it lazily is
      # valid; we must not inject a second (eager) registration on top.
      def stimulus_registered?(index)
        File.read(index).match?(%r{(?:eager|lazy)LoadControllersFrom\(\s*["']docs_kit/controllers["']})
      end

      def relative(path) = path.sub("#{destination_root}/", "")

      # The brand shown in the shell — the app's name, humanized (e.g. "my_gem_docs"
      # → "My gem docs"). Used in templates via <%= app_brand %>.
      def app_brand
        name = defined?(Rails) && Rails.respond_to?(:application) && Rails.application&.class&.module_parent_name
        (name || File.basename(destination_root)).to_s.underscore.humanize
      end
    end
  end
end
