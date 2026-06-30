# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# The daisyui gem is published on rubygems, but track the local checkout so the
# kit develops against the same source the docs sites use.
gem "daisyui", path: "../daisyui"

group :development, :test do
  gem "rake"
  gem "rspec"
  gem "rubocop", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rake", require: false
  gem "rubocop-rspec", require: false
end
