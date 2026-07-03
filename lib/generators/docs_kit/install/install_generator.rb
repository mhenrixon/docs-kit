# frozen_string_literal: true

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
        route %(root "landings#show")
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
