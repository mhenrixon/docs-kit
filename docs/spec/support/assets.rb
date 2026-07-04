# frozen_string_literal: true

require "rake"

# Compile assets ONCE before the suite. image_url (used for og:image) resolves
# through Propshaft's Static resolver, which reads the precompiled manifest — so
# the OG image, the built CSS, and the icons only resolve to served /assets URLs
# after a compile. This mirrors the deploy-time condition (the Dockerfile runs
# assets:precompile) and makes the SEO system spec self-sufficient regardless of
# whether assets were built beforehand.
#
# Runs only when the suite includes a spec that needs served assets (system or
# request specs that assert og:image) — a plain `--tag` run of unit specs skips
# it. Set SKIP_ASSET_PRECOMPILE=1 to force-skip (e.g. when CI precompiled first).
RSpec.configure do |config|
  config.before(:suite) do
    next if ENV["SKIP_ASSET_PRECOMPILE"] == "1"

    needs_assets = RSpec.world.example_groups.any? do |group|
      %i[system request].include?(group.metadata[:type])
    end
    next unless needs_assets

    Rails.application.load_tasks unless Rake::Task.task_defined?("assets:precompile")
    Rake::Task["assets:precompile"].invoke
  end
end
