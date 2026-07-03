# frozen_string_literal: true

require "open3"

# DocsUI::Page's `on_page` class-level accessor is the per-page auto-TOC knob.
# Page cannot autoload in the Rails-free suite (it includes
# Phlex::Rails::Helpers::Routes, whose body runs Rails.* at class-load time — see
# the "page-not-loadable-in-suite" note and spec/docs_ui/page_helpers_spec.rb).
# A global Rails stub would break icon_spec/the generator spec under random
# ordering, so exercise the REAL DocsUI::Page.on_page in an isolated child
# process (a minimal Rails routes stub lets Page load there without polluting the
# suite) and assert the contract: an unset on_page resolves to
# DocsKit.configuration.on_page_default, never a bare `true`.
# The subject is DocsUI::Page, but describing it by name (not the constant) is
# deliberate — referencing the constant would autoload Page and break the suite.
RSpec.describe "DocsUI::Page.on_page" do # rubocop:disable RSpec/DescribeClass
  gem_root = File.expand_path("../..", __dir__)

  # Load the real DocsUI::Page in a child process and return the inspected
  # `on_page` of a subclass, after applying `config` (a Configuration block body)
  # and `on_page` (statements against the subclass `klass`).
  define_method(:resolve) do |config: "", on_page: ""|
    script = <<~RUBY
      $LOAD_PATH.unshift "#{gem_root}/lib"
      require "active_support/all"
      require "action_dispatch"
      require "phlex/rails"
      require "daisy_ui"
      module Rails
        def self.application
          @app ||= Class.new do
            def routes = @routes ||= ActionDispatch::Routing::RouteSet.new
          end.new
        end
      end
      require "docs_kit"
      DocsKit.configure { |c| #{config} }
      klass = Class.new(DocsUI::Page)
      #{on_page}
      print klass.on_page.inspect
    RUBY
    stdout, stderr, status = Open3.capture3(RbConfig.ruby, "-e", script)
    raise "child process failed: #{stderr}" unless status.success?

    stdout
  end

  context "when no per-page value is set" do
    it "defaults to the configured on_page_default, not a bare true" do
      expect(resolve(config: "c.on_page_default = :panel")).to eq(":panel")
    end
  end

  context "when set to an explicit mode" do
    it "returns that mode" do
      expect(resolve(on_page: "klass.on_page :toggle")).to eq(":toggle")
    end
  end

  context "when opted out with false" do
    it "returns false" do
      expect(resolve(on_page: "klass.on_page false")).to eq("false")
    end
  end
end
