# frozen_string_literal: true

module DocsKit
  # A parsed keyboard shortcut for the docs-search palette — one entry of
  # DocsKit.configuration.search_shortcuts. A site writes shortcut STRINGS
  # ("mod+k", "/", "s", "ctrl+shift+f") and this turns each into a key + modifier
  # set that three places share: the config surface, the server-rendered <kbd>
  # hint (#label), and the docs-nav matcher (#to_h, serialized to JSON).
  #
  #   DocsKit::Shortcut.parse("mod+k").label   # => "Ctrl K"  (JS swaps to "⌘K" on mac)
  #   DocsKit::Shortcut.parse("mod+k").to_h    # => { "key" => "k", "mod" => true, ... }
  #
  # "mod" is the PLATFORM modifier — ⌘ on mac, Ctrl elsewhere — left abstract here
  # (the server can't know the OS) and resolved in the browser by docs-nav. Use
  # "mod" for the "primary command" chord so one config works on every platform;
  # use explicit "ctrl"/"meta" only when you truly mean that physical key.
  #
  # Modifier tokens (case-insensitive): mod, ctrl/control, shift, alt/option,
  # cmd/command/meta. The final token is the key (single char or a named key like
  # "escape"); a string with no key (e.g. "mod+") is unparseable and yields nil.
  class Shortcut
    # Canonical modifier token → the flag it sets.
    MODIFIER_ALIASES = {
      "mod" => :mod,
      "ctrl" => :ctrl, "control" => :ctrl,
      "shift" => :shift,
      "alt" => :alt, "option" => :alt,
      "cmd" => :meta, "command" => :meta, "meta" => :meta
    }.freeze

    # The order modifiers appear in a #label (matches the common convention).
    LABEL_ORDER = %i[mod ctrl meta alt shift].freeze

    # Human labels for the modifier flags in a #label. "mod" renders as the
    # majority default "Ctrl"; docs-nav swaps it to "⌘" on mac.
    MODIFIER_LABELS = { mod: "Ctrl", ctrl: "Ctrl", meta: "Meta", alt: "Alt", shift: "Shift" }.freeze

    # Parse one shortcut string → a Shortcut, or nil when there's no key to bind.
    def self.parse(string)
      tokens = string.to_s.downcase.split("+").map(&:strip).reject(&:empty?)
      key = tokens.pop
      return if key.nil? || MODIFIER_ALIASES.key?(key)

      mods = tokens.filter_map { |token| MODIFIER_ALIASES[token] }.to_set
      new(key, mods)
    end

    # Parse a list of shortcut strings, dropping any that don't parse.
    def self.parse_list(strings)
      Array(strings).filter_map { |string| parse(string) }
    end

    attr_reader :key

    # key: the final key token (lowercased). mods: a Set of modifier flag symbols.
    def initialize(key, mods)
      @key = key
      @mods = mods
      freeze
    end

    def mod? = @mods.include?(:mod)
    def ctrl? = @mods.include?(:ctrl)
    def shift? = @mods.include?(:shift)
    def alt? = @mods.include?(:alt)
    def meta? = @mods.include?(:meta)

    # The <kbd> badge text: modifiers (in LABEL_ORDER) then the key. In a CHORD
    # (with a modifier) a single-char key is uppercased for legibility ("mod+k" →
    # "Ctrl K"); a BARE key is shown exactly as authored ("/", "s"). A named key
    # (e.g. "escape") is left as-is either way.
    def label
      mods = LABEL_ORDER.select { |flag| @mods.include?(flag) }.map { |flag| MODIFIER_LABELS[flag] }.uniq
      (mods << key_label(chord: !mods.empty?)).join(" ")
    end

    # The shape docs-nav matches a keydown against (booleans always present so the
    # JSON is uniform). String keys → clean JSON without symbol quoting.
    def to_h
      {
        "key" => key, "mod" => mod?, "ctrl" => ctrl?,
        "shift" => shift?, "alt" => alt?, "meta" => meta?
      }
    end
    alias as_json to_h

    def ==(other)
      other.is_a?(Shortcut) && to_h == other.to_h
    end

    private

    # The key as it appears in the badge — uppercased only in a chord, and only for
    # a single char; a named key (length > 1) is always left as authored.
    def key_label(chord:)
      chord && key.length == 1 ? key.upcase : key
    end
  end
end
