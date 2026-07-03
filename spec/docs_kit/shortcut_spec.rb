# frozen_string_literal: true

# DocsKit::Shortcut parses a keyboard-shortcut string ("mod+k", "/", "s",
# "ctrl+shift+f") into a key + modifier set, so the config surface, the
# server-rendered <kbd> hint, and the docs-nav matcher all reason about the same
# structure. "mod" is the platform modifier — ⌘ on mac, Ctrl elsewhere — resolved
# in the browser; the Ruby side keeps it abstract so the hint and matcher stay
# platform-agnostic until JS refines the label. Pure Ruby, no Rails.
RSpec.describe DocsKit::Shortcut do
  describe ".parse" do
    it "parses a bare key" do
      s = described_class.parse("/")

      expect(s.key).to eq("/")
      expect(s.mod?).to be(false)
      expect(s.ctrl?).to be(false)
      expect(s.shift?).to be(false)
      expect(s.alt?).to be(false)
    end

    it "parses a single-letter key, lowercased" do
      expect(described_class.parse("S").key).to eq("s")
    end

    it "parses the platform modifier (mod+k)" do
      s = described_class.parse("mod+k")

      expect(s.key).to eq("k")
      expect(s.mod?).to be(true)
    end

    it "parses explicit ctrl/shift/alt/meta modifiers" do
      s = described_class.parse("ctrl+shift+f")

      expect(s.key).to eq("f")
      expect(s.ctrl?).to be(true)
      expect(s.shift?).to be(true)
      expect(s.alt?).to be(false)
      expect(s.mod?).to be(false)
    end

    it "is whitespace- and case-insensitive on the modifiers" do
      s = described_class.parse("  Mod + K ")

      expect(s.key).to eq("k")
      expect(s.mod?).to be(true)
    end

    it "accepts cmd/command/meta as aliases for the meta modifier" do
      %w[cmd command meta].each do |alias_name|
        expect(described_class.parse("#{alias_name}+k").meta?).to be(true)
      end
    end

    it "accepts control as an alias for ctrl" do
      expect(described_class.parse("control+k").ctrl?).to be(true)
    end

    it "returns nil for a blank or modifier-only string (nothing to bind)" do
      expect(described_class.parse("")).to be_nil
      expect(described_class.parse("   ")).to be_nil
      expect(described_class.parse("mod+")).to be_nil
      expect(described_class.parse(nil)).to be_nil
    end
  end

  describe "#label — the <kbd> badge text" do
    it "shows a bare key as itself" do
      expect(described_class.parse("/").label).to eq("/")
      expect(described_class.parse("s").label).to eq("s")
    end

    it "renders the platform modifier abstractly as 'Ctrl' by default (JS swaps to ⌘)" do
      # The server can't know the OS, so it renders the majority default; docs-nav
      # replaces it with ⌘ on mac. The key is uppercased in the badge for legibility.
      expect(described_class.parse("mod+k").label).to eq("Ctrl K")
    end

    it "spells out explicit modifiers in order" do
      expect(described_class.parse("ctrl+shift+f").label).to eq("Ctrl Shift F")
    end
  end

  describe "#to_h — the shape docs-nav matches against" do
    it "serializes key + modifier flags" do
      expect(described_class.parse("mod+k").to_h).to eq(
        "key" => "k", "mod" => true, "ctrl" => false,
        "shift" => false, "alt" => false, "meta" => false
      )
    end

    it "serializes a bare key with all modifiers false" do
      expect(described_class.parse("/").to_h).to eq(
        "key" => "/", "mod" => false, "ctrl" => false,
        "shift" => false, "alt" => false, "meta" => false
      )
    end
  end

  describe ".parse_list" do
    it "maps a list of strings to Shortcuts, dropping the unparseable" do
      list = described_class.parse_list(["/", "mod+k", "", "s"])

      expect(list.map(&:key)).to eq(%w[/ k s])
    end

    it "is empty for nil or an empty list" do
      expect(described_class.parse_list(nil)).to eq([])
      expect(described_class.parse_list([])).to eq([])
    end
  end
end
