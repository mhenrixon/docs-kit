# frozen_string_literal: true

require "erb"
require "rails/generators/base"

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
    # Everything is idempotent — re-running skips files that already exist.
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

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

      def create_initializer
        template "docs_kit.rb.erb", "config/initializers/docs_kit.rb"
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

      def create_registry_and_pages
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
        route %(get "docs/:doc(.:format)" => "docs#show", as: :doc)
        # Docs search, served from the registry by the gem's DocsKit::SearchController
        # (matches the default c.search_path). Thor's `route` PREPENDS, so this call
        # — after the docs route above — lands ABOVE `docs/:doc` in the file, where
        # it must be: otherwise `docs/:doc` would swallow /docs/search as :doc.
        route %(get "/docs/search" => "docs_kit/search#index", as: :docs_search)
        route %(root "landings#show")

        # AI-readable docs (llmstxt.org), served from the registry by the gem's
        # DocsKit::LlmsController — zero authoring. /llms.txt is the index;
        # /llms-full.txt concatenates every page's Markdown twin. Thor's `route`
        # skips a line already present, so re-running the generator is idempotent.
        route %(get "/llms.txt" => "docs_kit/llms#index", as: :llms)
        route %(get "/llms-full.txt" => "docs_kit/llms#full", as: :llms_full)

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

      def create_css_build
        template "application.tailwind.css.erb", "app/assets/stylesheets/application.tailwind.css"
        template "build-css", "bin/build-css"
        chmod "bin/build-css", 0o755
        template "build_css.rake", "lib/tasks/build_css.rake"
        create_file "app/assets/builds/.keep", ""
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

      def register_stimulus_controller
        index = stimulus_index_path
        return say_status(:skip, "no controllers/index.js — add: #{REGISTER_LINE}", :yellow) unless index
        return say_status(:identical, relative(index), :blue) if File.read(index).include?(REGISTER_LINE)

        inject_into_file index, after: /eagerLoadControllersFrom\([^\n]*\n/ do
          "#{REGISTER_LINE}\n"
        end
        append_to_file(index, "\n#{REGISTER_LINE}\n") unless File.read(index).include?(REGISTER_LINE)
      end

      def show_post_install
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

      # Render an ERB template from source_root against the generator binding, so
      # helpers like app_brand resolve — used where we need the rendered string in
      # memory (block extraction/merge) rather than Thor's file-to-file `template`.
      def render_template(name)
        source = File.read(File.join(self.class.source_root, name))
        ERB.new(source, trim_mode: "-").result(binding)
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
