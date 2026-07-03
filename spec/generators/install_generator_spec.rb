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
  def build_skeleton(routes: true, app_controller: true, stimulus_index: true, package_json: nil, rubocop_yml: nil)
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
    write(".rubocop.yml", rubocop_yml) if rubocop_yml
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

    it "adds the MCP route COMMENTED OUT (opt-in: needs the optional mcp gem)" do
      routes = read("config/routes.rb")

      # The MCP endpoint is off by default (the `mcp` gem is optional). The
      # generator draws the route commented so a site opts in by uncommenting.
      expect(routes).to include(%(# post "/mcp" => "docs_kit/mcp#create"))
      expect(routes).to include(%(# match "/mcp" => "docs_kit/mcp#method_not_allowed", via: %i[get delete]))
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

  # The AI-authoring scaffold: an AGENTS.md (the cross-tool authoring contract)
  # and a Claude Code skill (.claude/skills/write-docs-page/SKILL.md). Both are
  # brand-substituted; AGENTS.md is injected between delimiters when one already
  # exists (user content preserved); the skill file is skipped when present.
  describe "AI-authoring scaffold (create_agent_docs)" do
    # The delimiters bounding the injected block in a pre-existing AGENTS.md.
    let(:begin_marker) { "<!-- BEGIN docs-kit -->" }
    let(:end_marker) { "<!-- END docs-kit -->" }

    context "when neither file exists" do
      before do
        build_skeleton
        run_generator
      end

      it "creates AGENTS.md at the site root" do
        expect(exist?("AGENTS.md")).to be(true)
      end

      it "creates the write-docs-page Claude Code skill" do
        expect(exist?(".claude/skills/write-docs-page/SKILL.md")).to be(true)
      end

      it "substitutes the humanized app brand into AGENTS.md" do
        expect(read("AGENTS.md")).to include("My app docs")
      end

      it "encodes the core authoring idioms in AGENTS.md" do
        agents = read("AGENTS.md")

        # The one-command page flow and the md-first prose idiom — the two
        # things an agent must know before it writes a page.
        expect(agents).to include("rails g docs_kit:page")
        expect(agents).to include("md <<~'MD'")
        # The invariant an agent must not break.
        expect(agents).to include("DocsUI::Section")
      end

      it "wraps the AGENTS.md body in the docs-kit delimiters (so a re-run can find it)" do
        agents = read("AGENTS.md")

        expect(agents).to include(begin_marker)
        expect(agents).to include(end_marker)
      end

      it "targets write/add/update documentation in the skill frontmatter" do
        skill = read(".claude/skills/write-docs-page/SKILL.md")

        expect(skill).to match(/^---$/) # YAML frontmatter present
        expect(skill).to match(/description:.*document/i)
        expect(skill).to include("rails g docs_kit:page")
      end
    end

    context "when AGENTS.md already exists with user content" do
      let(:user_content) { "# My project\n\nHand-written guidance the user owns.\n" }

      before do
        build_skeleton
        write("AGENTS.md", user_content)
        run_generator
      end

      it "preserves the user's existing content" do
        expect(read("AGENTS.md")).to include("Hand-written guidance the user owns.")
      end

      it "injects the docs-kit block between delimiters" do
        agents = read("AGENTS.md")

        expect(agents).to include(begin_marker)
        expect(agents).to include(end_marker)
        expect(agents).to include("rails g docs_kit:page")
      end
    end

    context "when re-run (idempotence)" do
      before do
        build_skeleton
        run_generator
        run_generator # second invocation against the same destination
      end

      it "does not duplicate the docs-kit block in AGENTS.md" do
        agents = read("AGENTS.md")

        expect(agents.scan(begin_marker).size).to eq(1)
        expect(agents.scan(end_marker).size).to eq(1)
      end

      it "leaves a hand-edited AGENTS.md's user sections intact" do
        # Simulate a user editing OUTSIDE the delimited block after install.
        agents = read("AGENTS.md")
        edited = "#{agents}\n## My own section\n\nDo not clobber me.\n"
        write("AGENTS.md", edited)

        run_generator

        result = read("AGENTS.md")
        expect(result).to include("Do not clobber me.")
        expect(result.scan(begin_marker).size).to eq(1)
      end
    end

    context "when the skill file already exists" do
      before do
        build_skeleton
        write(".claude/skills/write-docs-page/SKILL.md", "# custom skill, do not clobber\n")
        run_generator
      end

      it "does not overwrite the existing skill" do
        expect(read(".claude/skills/write-docs-page/SKILL.md")).to eq("# custom skill, do not clobber\n")
      end
    end
  end

  # The RuboCop wiring: the site's .rubocop.yml gets `require: docs_kit/rubocop`
  # and `inherit_gem: { docs-kit: config/rubocop/docs_kit.yml }` so the gem's
  # cops run. Created minimal when absent; merged (not clobbered) into an
  # existing one; idempotent on re-run.
  describe "RuboCop cop wiring (wire_rubocop_cops)" do
    def rubocop_config
      require "yaml"
      YAML.safe_load(read(".rubocop.yml"))
    end

    context "when the site has no .rubocop.yml" do
      before do
        build_skeleton
        run_generator
      end

      it "creates one that requires the gem cop entry point" do
        expect(rubocop_config["require"]).to include("docs_kit/rubocop")
      end

      it "inherits the shipped cop config from the gem" do
        expect(rubocop_config.dig("inherit_gem", "docs-kit")).to include("config/rubocop/docs_kit.yml")
      end
    end

    context "when the site already has a .rubocop.yml (e.g. rails new omakase)" do
      let(:omakase) do
        <<~YAML
          # Omakase Ruby styling for Rails
          inherit_gem: { rubocop-rails-omakase: rubocop.yml }
        YAML
      end

      before do
        build_skeleton(rubocop_yml: omakase)
        run_generator
      end

      it "adds the docs-kit cop require without dropping the existing inherit_gem" do
        config = rubocop_config
        expect(config["require"]).to include("docs_kit/rubocop")
        expect(config.dig("inherit_gem", "rubocop-rails-omakase")).to eq("rubocop.yml")
        expect(config.dig("inherit_gem", "docs-kit")).to include("config/rubocop/docs_kit.yml")
      end
    end

    context "when the site's .rubocop.yml already has a require list" do
      let(:existing) do
        <<~YAML
          require:
            - rubocop-rspec
          AllCops:
            NewCops: enable
        YAML
      end

      before do
        build_skeleton(rubocop_yml: existing)
        run_generator
      end

      it "appends to the existing require list rather than replacing it" do
        requires = rubocop_config["require"]
        expect(requires).to include("rubocop-rspec")
        expect(requires).to include("docs_kit/rubocop")
      end
    end

    context "when re-run (idempotence)" do
      before do
        build_skeleton
        run_generator
        run_generator
      end

      it "does not duplicate the docs_kit/rubocop require" do
        expect(rubocop_config["require"].count("docs_kit/rubocop")).to eq(1)
      end

      it "does not duplicate the docs-kit inherit_gem entry" do
        expect(rubocop_config.dig("inherit_gem", "docs-kit").count("config/rubocop/docs_kit.yml")).to eq(1)
      end
    end
  end
end
