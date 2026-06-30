# frozen_string_literal: true

require "phlex"
require "rouge"
require "zeitwerk"

require_relative "docs_kit/version"
require_relative "docs_kit/configuration"

# DocsKit — a reusable docs-site component library: the shared Phlex chrome
# (shell, sidebar, code block, theme switcher, page kit) that lets several docs
# sites look identical while differing only in configuration.
#
# Components live under the `Docs::` namespace and are exposed as a Phlex::Kit,
# so a host base view can `include Docs` and call `Shell(...)`, `Page(...)`,
# `Code(...)`, etc., or always use the namespaced `render Docs::Shell.new(...)`.
module DocsKit
  class Error < StandardError; end

  class << self
    # The current configuration, memoized. Reset with DocsKit.reset_configuration!.
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
      configuration
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end

# The Docs namespace is a Phlex::Kit so `include Docs` exposes every component
# constant as a bare callable method (Shell, Page, Code, Menu, ...). Defined
# before loader.setup so zeitwerk autoloads its children (Docs::Shell, ...) into
# this already-extended module.
module Docs
  extend Phlex::Kit
end

loader = Zeitwerk::Loader.new
loader.tag = "docs_kit"
loader.inflector.inflect("docs_kit" => "DocsKit")
# DocsKit::* support code (registry mixin, engine helpers) under lib/docs_kit/,
# excluding the eagerly-required files below.
loader.push_dir(File.expand_path("docs_kit", __dir__), namespace: DocsKit)
# The shippable Phlex components under app/components/docs/ → Docs::*.
loader.push_dir(File.expand_path("../app/components/docs", __dir__), namespace: Docs)
loader.ignore(File.expand_path("docs_kit/version.rb", __dir__))
loader.ignore(File.expand_path("docs_kit/configuration.rb", __dir__))
# engine.rb is required explicitly below only under Rails, so zeitwerk never
# manages it (it would otherwise expect a DocsKit::Engine constant outside Rails).
loader.ignore(File.expand_path("docs_kit/engine.rb", __dir__))
loader.setup

require_relative "docs_kit/engine" if defined?(Rails::Engine)
