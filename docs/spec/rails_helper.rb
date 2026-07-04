# frozen_string_literal: true

require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"

# Never run the suite against production.
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"

# Auto-require support files (custom matchers, shared contexts). System-driver
# setup lives under spec/system/support and is required by system_helper.rb, not
# here, so a non-system spec doesn't pay the Capybara/Playwright load.
Rails.root.glob("spec/support/**/*.rb").sort_by(&:to_s).each { |f| require f }

RSpec.configure do |config|
  # This site is DB-less (the docs registry is in-memory) — no ActiveRecord.
  config.use_active_record = false

  # Filter Rails internals out of failure backtraces.
  config.filter_rails_from_backtrace!
end
