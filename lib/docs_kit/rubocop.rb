# frozen_string_literal: true

# Entry point for docs-kit's custom RuboCop cops. A consuming site loads them
# with a single line in its `.rubocop.yml`:
#
#   require:
#     - docs_kit/rubocop
#   inherit_gem:
#     docs-kit: config/rubocop/docs_kit.yml
#
# RuboCop is required LAZILY here — it is a development-time dependency of the
# HOST app (every generated docs site has `rubocop` in its Gemfile), never a
# runtime dependency of docs-kit itself. Requiring this file outside a RuboCop
# run (e.g. if a stray `require` reaches it) still works: it pulls in rubocop on
# demand rather than assuming it is already loaded.
require "rubocop"

require_relative "../rubocop/cop/docs_kit/render_component_preferred"
require_relative "../rubocop/cop/docs_kit/escaped_interpolation_in_heredoc"
