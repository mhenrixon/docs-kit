# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require "rails/generators"
require "generators/docs_kit/install/install_generator"

# The install generator never touches a booted Rails app — it only reads/writes
# files under destination_root via Thor. So we exercise it against a throwaway
# destination root: a minimal fake app skeleton (routes.rb, application_controller,
# controllers/index.js, assets.rb) built per-example, run the generator, and assert
# the produced file manifest + key contents.
#
# These specs assert CURRENT behavior. Most steps guard against re-runs (Thor's
# `route`/`inject_into_file` skip a line that's already present; several methods
# `say_status(:skip)` when a target exists), so the generator is largely
# idempotent; `create_initializer` is the exception (it re-renders the template
# on every run). If a later change tightens idempotency, update these assertions.
RSpec.describe DocsKit::Generators::InstallGenerator do
  # A named destination dir so app_brand humanizes deterministically
  # ("my_app_docs" → "My app docs"). Rails isn't booted, so app_brand falls back
  # to the basename of destination_root.
  let(:app_name) { "my_app_docs" }
  let(:destination) { File.join(Dir.tmpdir, "docs-kit-gen-spec", app_name) }

  # A stock Stimulus controllers/index.js: only the eager-load line the generator
  # injects the docs_kit path after.
  def stimulus_index_source
    <<~JS
      import { application } from "controllers/application"
      eagerLoadControllersFrom("controllers", application)
    JS
  end

  # Build a minimal Rails-ish skeleton the generator's injections expect to find.
  def build_skeleton(routes: true, app_controller: true, stimulus_index: true, package_json: nil)
    FileUtils.mkdir_p(File.join(destination, "config/initializers"))
    FileUtils.mkdir_p(File.join(destination, "app/controllers"))
    FileUtils.mkdir_p(File.join(destination, "app/javascript/controllers"))

    write("config/initializers/assets.rb", %(Rails.application.config.assets.version = "1.0"\n))
    write("config/routes.rb", "Rails.application.routes.draw do\nend\n") if routes
    if app_controller
      write("app/controllers/application_controller.rb",
            "class ApplicationController < ActionController::Base\nend\n")
    end
    write("app/javascript/controllers/index.js", stimulus_index_source) if stimulus_index
    write("package.json", package_json) if package_json
  end

  def write(rel, content)
    path = File.join(destination, rel)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def read(rel) = File.read(File.join(destination, rel))
  def exist?(rel) = File.exist?(File.join(destination, rel))

  # Run the generator quietly against the skeleton.
  def run_generator
    generator = described_class.new([], {}, destination_root: destination)
    silence_stream { generator.invoke_all }
  end

  # Thor writes progress to $stdout; keep the suite output clean.
  def silence_stream
    original = $stdout
    $stdout = File.open(File::NULL, "w")
    yield
  ensure
    $stdout.close
    $stdout = original
  end

  before { FileUtils.rm_rf(destination) }
  after  { FileUtils.rm_rf(destination) }

  describe "the file manifest" do
    before do
      build_skeleton
      run_generator
    end

    it "creates the config initializers" do
      expect(exist?("config/initializers/docs_kit.rb")).to be(true)
      expect(exist?("config/initializers/phlex.rb")).to be(true)
      expect(exist?("config/initializers/rails_icons.rb")).to be(true)
    end

    it "creates the registry model + controllers + pages" do
      expect(exist?("app/models/doc.rb")).to be(true)
      expect(exist?("app/controllers/docs_controller.rb")).to be(true)
      expect(exist?("app/controllers/landings_controller.rb")).to be(true)
      expect(exist?("app/views/docs/pages/installation.rb")).to be(true)
      expect(exist?("app/views/landings/show.rb")).to be(true)
    end

    it "creates the CSS build files + keeps" do
      expect(exist?("app/assets/stylesheets/application.tailwind.css")).to be(true)
      expect(exist?("bin/build-css")).to be(true)
      expect(exist?("lib/tasks/build_css.rake")).to be(true)
      expect(exist?("app/assets/builds/.keep")).to be(true)
      expect(exist?("app/components/.keep")).to be(true)
    end
  end

  describe "config/initializers/docs_kit.rb" do
    before do
      build_skeleton
      run_generator
    end

    it "substitutes the humanized app name as the brand" do
      initializer = read("config/initializers/docs_kit.rb")

      expect(initializer).to include(%(c.brand        = "My app docs"))
      expect(initializer).to include(%(c.title_suffix = "My app docs"))
    end

    it "ships the theme list that matches the Tailwind @plugin block" do
      css = read("app/assets/stylesheets/application.tailwind.css")
      initializer = read("config/initializers/docs_kit.rb")

      %w[dark light synthwave retro cyberpunk dracula night nord sunset].each do |theme|
        expect(initializer).to include(theme)
        expect(css).to include(theme)
      end
    end
  end

  describe "route injection (add_routes)" do
    before do
      build_skeleton
      run_generator
    end

    it "adds the docs and root routes" do
      routes = read("config/routes.rb")

      expect(routes).to include(%(get "docs/:doc(.:format)" => "docs#show", as: :doc))
      expect(routes).to include(%(root "landings#show"))
    end

    it "allows an optional .:format on the docs route (so /docs/x.md serves the twin)" do
      routes = read("config/routes.rb")

      # The Markdown twin (GET /docs/x.md) needs the format segment enabled. The
      # docs route explicitly opts it in and must NOT pin format: 'html'.
      expect(routes).to include("(.:format)")
      expect(routes).not_to match(/defaults:\s*\{\s*format:/)
    end

    it "adds the llms.txt + llms-full.txt routes (AI-readable docs)" do
      routes = read("config/routes.rb")

      expect(routes).to include(%(get "/llms.txt" => "docs_kit/llms#index"))
      expect(routes).to include(%(get "/llms-full.txt" => "docs_kit/llms#full"))
    end

    it "adds the docs-search route (matches the default c.search_path)" do
      routes = read("config/routes.rb")

      expect(routes).to include(%(get "/docs/search" => "docs_kit/search#index"))
    end

    it "draws /docs/search ABOVE docs/:doc so it isn't swallowed as :doc" do
      routes = read("config/routes.rb")

      search_at = routes.index(%(get "/docs/search" => "docs_kit/search#index"))
      doc_at = routes.index(%(get "docs/:doc(.:format)" => "docs#show"))
      expect(search_at).to be < doc_at
    end

    it "does not duplicate routes on re-run (idempotent)" do
      run_generator # second invocation against the same destination

      routes = read("config/routes.rb")
      expect(routes.scan(%(get "/llms.txt" => "docs_kit/llms#index")).size).to eq(1)
      expect(routes.scan(%(get "/llms-full.txt" => "docs_kit/llms#full")).size).to eq(1)
      expect(routes.scan(%(get "docs/:doc(.:format)" => "docs#show", as: :doc)).size).to eq(1)
      expect(routes.scan(%(get "/docs/search" => "docs_kit/search#index")).size).to eq(1)
    end
  end

  describe "controller injection (include_controller_helper)" do
    it "injects include DocsKit::Controller into ApplicationController" do
      build_skeleton
      run_generator

      expect(read("app/controllers/application_controller.rb"))
        .to include("include DocsKit::Controller")
    end

    it "skips injection when ApplicationController is absent" do
      build_skeleton(app_controller: false)
      run_generator

      expect(exist?("app/controllers/application_controller.rb")).to be(false)
    end
  end

  describe "asset paths + package.json (wire_assets_and_package_json)" do
    it "appends the builds path to config/initializers/assets.rb" do
      build_skeleton
      run_generator

      expect(read("config/initializers/assets.rb"))
        .to include(%(Rails.application.config.assets.paths << Rails.root.join("app", "assets", "builds")))
    end

    it "creates a package.json stub with the build:css scripts when none exists" do
      build_skeleton
      run_generator

      package = read("package.json")
      expect(package).to include(%("build:css": "bin/build-css --minify"))
      expect(package).to include(%("watch:css": "bin/build-css --watch"))
    end

    it "does not overwrite an existing package.json that already has build:css" do
      existing = %({\n  "scripts": { "build:css": "custom" }\n}\n)
      build_skeleton(package_json: existing)
      run_generator

      expect(read("package.json")).to eq(existing)
    end
  end

  describe "Stimulus registration (register_stimulus_controller)" do
    it "registers the docs_kit controllers path in controllers/index.js" do
      build_skeleton
      run_generator

      expect(read("app/javascript/controllers/index.js"))
        .to include(%(eagerLoadControllersFrom("docs_kit/controllers", application)))
    end

    it "skips registration when there is no controllers/index.js" do
      build_skeleton(stimulus_index: false)
      run_generator

      expect(exist?("app/javascript/controllers/index.js")).to be(false)
    end
  end

  describe "bin/build-css" do
    it "is created executable (chmod 0755)" do
      build_skeleton
      run_generator

      mode = File.stat(File.join(destination, "bin/build-css")).mode & 0o777
      expect(mode).to eq(0o755)
    end
  end
end
