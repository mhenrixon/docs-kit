# frozen_string_literal: true

require "docs_kit/rubocop"
require_relative "../../cop_spec_helper"

# The new cop. Docs pages routinely embed Ruby examples that contain literal
# `#{...}` — inside a double-quoted heredoc that means every interpolation has to
# be escaped as `\#{...}`, an "escape tax" that recurred in every audited site.
# The fix is a single-quoted heredoc delimiter (`<<~'RUBY'`), where `#{...}` is
# already literal. The cop flags `\#{` in a double-quoted heredoc and, when the
# heredoc has no LIVE interpolation, autocorrects to the single-quoted delimiter
# with the backslashes stripped.
#
# NOTE: the fixtures under test use `RUBY` as their heredoc tag, so the outer
# expect_* heredocs use a DIFFERENT tag (`CODE`) — otherwise the inner `RUBY`
# terminator would close the outer heredoc early. They are single-quoted
# (`<<~'CODE'`) so `\#{` and `#{` in the fixtures stay literal.
RSpec.describe RuboCop::Cop::DocsKit::EscapedInterpolationInHeredoc do
  include_context "with cop spec support"

  context "with an escaped interpolation in a squiggly double-quoted heredoc" do
    it "registers an offense on the heredoc delimiter" do
      expect_offense(<<~'CODE')
        source = <<~RUBY
                 ^^^^^^^ Use a single-quoted heredoc delimiter (`<<~'RUBY'`) so `#{...}` is literal without escaping.
          puts "hello \#{name}"
        RUBY
      CODE
    end

    it "autocorrects to a single-quoted delimiter and strips the backslash" do
      expect_offense(<<~'CODE')
        source = <<~RUBY
                 ^^^^^^^ Use a single-quoted heredoc delimiter (`<<~'RUBY'`) so `#{...}` is literal without escaping.
          puts "hello \#{name}"
        RUBY
      CODE

      expect_correction(<<~'CODE')
        source = <<~'RUBY'
          puts "hello #{name}"
        RUBY
      CODE
    end
  end

  context "with an escaped interpolation in a dash double-quoted heredoc" do
    it "registers an offense and autocorrects the delimiter" do
      expect_offense(<<~'CODE')
        source = <<-RUBY
                 ^^^^^^^ Use a single-quoted heredoc delimiter (`<<-'RUBY'`) so `#{...}` is literal without escaping.
          val = \#{x}
        RUBY
      CODE

      expect_correction(<<~'CODE')
        source = <<-'RUBY'
          val = #{x}
        RUBY
      CODE
    end
  end

  context "when the heredoc also contains a LIVE (unescaped) interpolation" do
    it "reports the offense but does NOT autocorrect (delimiter swap would break the live one)" do
      expect_offense(<<~'CODE')
        source = <<~RUBY
                 ^^^^^^^ Use a single-quoted heredoc delimiter (`<<~'RUBY'`) so `#{...}` is literal without escaping. This heredoc also has a live interpolation — fix by hand.
          literal = \#{keep_me}
          live    = #{value}
        RUBY
      CODE

      expect_no_corrections
    end
  end

  # Ruby interpolates `#@ivar` and `#$global` in a double-quoted heredoc too, not
  # only `#{...}`. A delimiter swap would freeze those live interpolations into
  # literal text — the cop must recognise them as live and refuse to autocorrect.
  context "when the live interpolation is an ivar sigil form (not a brace)" do
    it "reports it as live and does NOT autocorrect" do
      expect_offense(<<~'CODE')
        source = <<~RUBY
                 ^^^^^^^ Use a single-quoted heredoc delimiter (`<<~'RUBY'`) so `#{...}` is literal without escaping. This heredoc also has a live interpolation — fix by hand.
          literal = \#{keep_me}
          live    = #@name
        RUBY
      CODE

      expect_no_corrections
    end
  end

  context "when the live interpolation is a global-variable sigil form" do
    it "reports it as live and does NOT autocorrect" do
      expect_offense(<<~'CODE')
        source = <<~RUBY
                 ^^^^^^^ Use a single-quoted heredoc delimiter (`<<~'RUBY'`) so `#{...}` is literal without escaping. This heredoc also has a live interpolation — fix by hand.
          literal = \#{keep_me}
          live    = #$stdout
        RUBY
      CODE

      expect_no_corrections
    end
  end

  # When converting to a single-quoted delimiter, EVERY escaped interpolation
  # form must lose its backslash — not just `\#{`. Otherwise `\#@name` keeps a
  # backslash that was escape-consumed in the double-quoted original, silently
  # changing the string bytes.
  context "with escaped brace AND escaped sigil interpolations in one body" do
    it "fires and de-escapes both when there is no live interpolation" do
      expect_offense(<<~'CODE')
        source = <<~RUBY
                 ^^^^^^^ Use a single-quoted heredoc delimiter (`<<~'RUBY'`) so `#{...}` is literal without escaping.
          braced = \#{x}
          ivar   = \#@name
        RUBY
      CODE

      expect_correction(<<~'CODE')
        source = <<~'RUBY'
          braced = #{x}
          ivar   = #@name
        RUBY
      CODE
    end
  end

  context "with only an escaped sigil interpolation (no escaped brace)" do
    it "still fires and de-escapes it" do
      expect_offense(<<~'CODE')
        source = <<~RUBY
                 ^^^^^^^ Use a single-quoted heredoc delimiter (`<<~'RUBY'`) so `#{...}` is literal without escaping.
          ivar = \#@name
        RUBY
      CODE

      expect_correction(<<~'CODE')
        source = <<~'RUBY'
          ivar = #@name
        RUBY
      CODE
    end
  end

  context "with a single-quoted heredoc delimiter (the recommended form)" do
    it "does not fire — interpolation is already literal, no escape needed" do
      expect_no_offenses(<<~'CODE')
        source = <<~'RUBY'
          puts "hello #{name}"
        RUBY
      CODE
    end
  end

  context "with a double-quoted heredoc that has no escaped interpolation" do
    it "does not fire (nothing to un-escape)" do
      expect_no_offenses(<<~'CODE')
        source = <<~RUBY
          puts "plain text, live #{value}"
        RUBY
      CODE
    end
  end
end
