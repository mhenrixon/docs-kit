# frozen_string_literal: true

# The browser suite runs under Puma (a real server — no webrick). docs-kit renders
# server-side (no reactive round trip), so one server is enough; the reactive
# transport matrix that the phlex-reactive docs run isn't needed here.
Capybara.server = [ :puma, { Silent: true } ]

# Run at several viewport widths so responsive layout regressions (a sidebar/TOC
# that's fine on desktop but breaks on a phone) are caught. Pick with
# CAPYBARA_SCREEN (default desktop); CI can run the matrix.
SCREEN_SIZES = {
  "mobile" => [ 390, 844 ],   # iPhone 12/13/14
  "tablet" => [ 820, 1180 ],  # iPad Air
  "desktop" => [ 1280, 800 ]
}.freeze

CAPYBARA_SCREEN = ENV.fetch("CAPYBARA_SCREEN", "desktop")
CAPYBARA_SCREEN_SIZE = SCREEN_SIZES.fetch(CAPYBARA_SCREEN) do
  raise "CAPYBARA_SCREEN must be one of #{SCREEN_SIZES.keys.join(', ')} (got #{CAPYBARA_SCREEN.inspect})"
end

RSpec.configure do |config|
  # Desktop-only layout (the sticky panel TOC is lg:block; the sidebar is an
  # always-open drawer) — skip those specs on a small viewport so the matrix
  # doesn't produce false failures.
  config.filter_run_excluding(:desktop_only) unless CAPYBARA_SCREEN == "desktop"

  config.before(:each, type: :system) do
    Capybara.configure do |c|
      c.default_max_wait_time = 5
      c.default_driver = :playwright
      c.javascript_driver = :playwright
      c.always_include_port = true
    end

    driven_by(:playwright, screen_size: CAPYBARA_SCREEN_SIZE)
  end
end
