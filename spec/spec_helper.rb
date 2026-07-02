# frozen_string_literal: true

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
