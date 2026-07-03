# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)

# Lint only the gem's own source — NOT the dogfood docs/ site. docs/ is a separate
# consuming app with its own bundle and .rubocop.yml (it `inherit_gem`s
# rubocop-rails-omakase, absent from the gem's bundle). Passing explicit paths
# stops RuboCop from discovering and loading docs/.rubocop.yml, whose gem
# inheritance can't resolve here (and crashes CI). docs/ lints itself.
RuboCop::RakeTask.new do |task|
  task.patterns = %w[app lib spec Rakefile Gemfile docs-kit.gemspec]
end

task default: %i[spec rubocop]
