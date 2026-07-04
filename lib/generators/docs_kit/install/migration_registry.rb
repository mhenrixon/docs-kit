# frozen_string_literal: true

require_relative "migration"
require_relative "../../../docs_kit/version"

module DocsKit
  module Generators
    # The ordered set of release-to-release migrations `--sync` applies. Given a
    # site's last-synced version, it selects the migrations the site hasn't run
    # yet — those in the half-open range `(from_version, upto]`: ABOVE the site
    # version (a migration AT the site version is already applied) and no newer
    # than the installed gem — and runs them in ascending order, collecting the
    # warn-only messages each couldn't safely automate.
    #
    # The `upto` ceiling (default: the installed gem version) matters because
    # `--sync` restamps the site to DocsKit::VERSION afterward. A migration whose
    # `to` sat ABOVE the gem version would then still exceed the new stamp and
    # re-run on EVERY sync forever. It can't legitimately exist anyway (a site
    # can't have "arrived" at a release it doesn't have), so it's filtered out.
    #
    # `.default` is the registry the generator uses. It SHIPS EMPTY at 1.0.x —
    # the mechanism (stamp the synced version, detect the gap, run ordered
    # transforms) is the deliverable; the first concrete `1.x → 1.y` transform is
    # a one-line `Migration.new(...)` addition here once a release needs one.
    class MigrationRegistry
      def initialize(migrations = [])
        @migrations = migrations.sort_by(&:to)
      end

      # The registry the install generator runs during `--sync`. Empty today.
      def self.default
        @default ||= new(MIGRATIONS)
      end

      # No migrations to register yet — the mechanism is the 1.0 deliverable.
      # Add ordered `Migration.new(to: "1.x.0", description: "...") { ... }`
      # entries here as future releases change config knobs, routes, or templates.
      MIGRATIONS = [].freeze

      # The migrations a site last synced at `from_version` still needs, ascending
      # by version — those in `(from_version, upto]`. `upto` defaults to the
      # installed gem version so a migration targeting an unreleased version never
      # applies (and never re-runs against the post-sync stamp).
      def applicable(from_version, upto: DocsKit::VERSION)
        from = Gem::Version.new(from_version.to_s)
        ceiling = Gem::Version.new(upto.to_s)
        @migrations.select { |migration| migration.to > from && migration.to <= ceiling }
      end

      # Run every applicable migration in order against the site, returning the
      # flattened list of manual-cleanup warnings they couldn't safely automate.
      def migrate!(from_version, root, generator, upto: DocsKit::VERSION)
        applicable(from_version, upto: upto).flat_map { |migration| migration.call(root, generator) }
      end
    end
  end
end
