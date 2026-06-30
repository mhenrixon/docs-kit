# frozen_string_literal: true

require "docs_kit"

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed

  # Each example starts from a clean configuration.
  config.before { DocsKit.reset_configuration! }
end
