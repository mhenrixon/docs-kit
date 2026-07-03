# frozen_string_literal: true

# Cop-spec support, scoped to the cop specs only.
#
# We deliberately do NOT `require "rubocop/rspec/support"`: that file calls
# RSpec.configure and globally `config.include`s CopHelper + ExpectOffense into
# EVERY example group. CopHelper defines a `registry` method, which shadows the
# unrelated `let(:registry)` in spec/docs_kit/registry_spec.rb (DocsKit::Registry
# is a different Registry) and breaks it under random ordering. Requiring the
# modules directly and mixing them in LOCALLY keeps the rubocop-rspec harness
# contained to the groups that opt in via `include_context "cop spec"`.
require "rubocop"
require "rubocop/rspec/cop_helper"
require "rubocop/rspec/expect_offense"
require "rubocop/rspec/shared_contexts"

RSpec.shared_context "with cop spec support" do
  include CopHelper
  include RuboCop::RSpec::ExpectOffense

  include_context "config"
end
