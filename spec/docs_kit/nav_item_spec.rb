# frozen_string_literal: true

RSpec.describe DocsKit::NavItem do
  it "carries href/label and an optional icon" do
    item = described_class.new(href: "/docs/x", label: "X")
    expect(item.href).to eq("/docs/x")
    expect(item.label).to eq("X")
    expect(item.icon).to be_nil

    expect(described_class.new(href: "/y", label: "Y", icon: "search").icon).to eq("search")
  end
end
