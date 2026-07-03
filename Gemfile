# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# The daisyui gem is published on rubygems. When the sibling checkout exists,
# track it so the kit develops against the same source the docs sites use;
# otherwise (CI, a fresh clone) fall back to the published gem via the gemspec's
# `daisyui >= 1.2` dependency.
gem "daisyui", path: "../daisyui" if File.directory?(File.expand_path("../daisyui", __dir__))

group :development, :test do
  gem "rake"
  gem "rspec"
  gem "rubocop", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rake", require: false
  gem "rubocop-rspec", require: false
  gem "simplecov", require: false
end
