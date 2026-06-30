# frozen_string_literal: true

RSpec.describe DocsKit::Registry do
  # A representative site registry built on the mixin.
  let(:registry) do
    Class.new do
      extend DocsKit::Registry

      entries [
        { slug: "installation", title: "Installation", group: "Guide", view: "Installation" },
        { slug: "security",     title: "Security",     group: "Guide", view: "Missing" },
        { slug: "counter",      title: "Counter",      group: "Examples", view: "Counter" }
      ]

      attr_reader :slug, :title, :group, :view_name

      def initialize(entry)
        @slug = entry[:slug]
        @title = entry[:title]
        @group = entry[:group]
        @view_name = entry[:view]
      end

      # Stand-in for safe_constantize: only "Installation"/"Counter" are "authored".
      def view_class
        %w[Installation Counter].include?(view_name) ? Object : nil
      end
    end
  end

  it "builds all instances from entries" do
    expect(registry.all.map(&:slug)).to eq(%w[installation security counter])
  end

  it "looks up by slug, nil when missing" do
    expect(registry.from_slug("counter").title).to eq("Counter")
    expect(registry.from_slug("nope")).to be_nil
  end

  it "groups by the group attribute, preserving order" do
    grouped = registry.grouped
    expect(grouped.keys).to eq(%w[Guide Examples])
    expect(grouped["Guide"].map(&:slug)).to eq(%w[installation security])
  end

  it "supports the 'authored' filter (only entries with a resolvable view)" do
    authored = registry.all.select(&:view_class).group_by(&:group)
    expect(authored["Guide"].map(&:slug)).to eq(%w[installation])
    expect(authored["Examples"].map(&:slug)).to eq(%w[counter])
  end

  it "freezes the entries so a site cannot mutate the registry" do
    expect(registry.entries).to be_frozen
    expect(registry.entries.first).to be_frozen
  end

  it "allows a custom grouping attribute" do
    klass = Class.new do
      extend DocsKit::Registry

      entries [{ slug: "a", category: "Actions" }]
      group_by_attribute :category
      attr_reader :slug, :category

      def initialize(entry)
        @slug = entry[:slug]
        @category = entry[:category]
      end
    end

    expect(klass.grouped.keys).to eq(%w[Actions])
  end
end
