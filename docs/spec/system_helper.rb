# frozen_string_literal: true

# Boots the site app + Capybara + Playwright for the browser suite. A system spec
# requires this instead of rails_helper so the driver setup loads only when the
# browser is actually needed.
require "rails_helper"
require "capybara/rspec"

Dir[File.join(__dir__, "system/support/**/*.rb")].sort.each { |f| require f }
