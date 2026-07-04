# frozen_string_literal: true

require "generators/docs_kit/install/migration"

# A Migration is one ordered, versioned transform: the release it belongs to
# (`to`), a human description, and a block run with (root, generator) that
# returns the list of manual-cleanup warnings it couldn't safely automate.
# Warn-only-safe by contract — the block does what it can idempotently and hands
# back strings for the rest (the #24 drift-report pattern).
RSpec.describe DocsKit::Generators::Migration do
  subject(:migration) do
    described_class.new(to: "1.2.0", description: "rename c.foo → c.bar") do |root, generator|
      ran << [root, generator]
      ["couldn't touch a hand-edited line"]
    end
  end

  let(:ran) { [] }

  it "coerces `to` into a Gem::Version (so the registry can order/compare)" do
    expect(migration.to).to eq(Gem::Version.new("1.2.0"))
  end

  it "exposes its description" do
    expect(migration.description).to eq("rename c.foo → c.bar")
  end

  it "runs its block with (root, generator) and returns the block's warnings" do
    warnings = migration.call("/site", :the_generator)

    expect(ran).to eq([["/site", :the_generator]])
    expect(warnings).to eq(["couldn't touch a hand-edited line"])
  end

  it "returns an empty array when the block returns nil (nothing to warn about)" do
    silent = described_class.new(to: "1.1.0", description: "no-op") { |_root, _gen| nil }

    expect(silent.call("/site", nil)).to eq([])
  end

  it "orders naturally by version" do
    a = described_class.new(to: "1.1.0", description: "a") { [] }
    b = described_class.new(to: "1.10.0", description: "b") { [] }

    # String sort would put "1.10.0" before "1.2.0"; Gem::Version must not.
    expect([b, a].sort_by(&:to).map(&:to)).to eq([Gem::Version.new("1.1.0"), Gem::Version.new("1.10.0")])
  end
end
