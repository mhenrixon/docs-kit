# frozen_string_literal: true

# Coverage. Start SimpleCov BEFORE requiring docs_kit so every lib/ file loaded
# below is tracked. CLAUDE.md sets the 80% floor; enforce it here so `rake` fails
# locally and in CI when coverage regresses. The generators/ tree is the install
# generator, exercised by spec/generators/**.
require "simplecov"
SimpleCov.start do
  enable_coverage :branch
  add_filter "/spec/"
  add_group "Config", "lib/docs_kit/configuration.rb"
  add_group "Registry", "lib/docs_kit/registry.rb"
  add_group "Components", "app/components"
  add_group "Generators", "lib/generators"
  minimum_coverage 80
end

# Component specs render DocsUI:: Phlex components in isolation (no Rails
# request). Shell and Code compose phlex-rails value helpers (e.g.
# content_security_policy_nonce), so load phlex-rails here — plus the two
# ActiveSupport core-exts it and the theme-restore script rely on
# (String#html_safe / SafeBuffer, and #to_json). Rails provides all of these in
# a real app; the suite loads just enough to render the chrome standalone.
require "active_support/core_ext/string/output_safety"
require "active_support/json"
require "phlex/rails"

require "docs_kit"

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed

  # Each example starts from a clean configuration.
  config.before { DocsKit.reset_configuration! }
end
