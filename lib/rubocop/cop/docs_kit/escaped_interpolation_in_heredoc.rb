# frozen_string_literal: true

module RuboCop
  module Cop
    module DocsKit
      # Flags an ESCAPED interpolation (`\#{...}`) inside a double-quoted heredoc
      # and steers to the single-quoted delimiter (`<<~'RUBY'`), where `#{...}` is
      # already literal so no backslash is needed.
      #
      # Docs pages constantly embed Ruby examples that themselves contain
      # `#{...}`. In a double-quoted heredoc every one of those has to be escaped
      # as `\#{...}` or Ruby interpolates it — the recurring "escape tax" every
      # audited docs site paid. A single-quoted heredoc delimiter turns the whole
      # body literal, so the examples read exactly as they will render.
      #
      # Ruby interpolates three sigils in a double-quoted string — `#{expr}`,
      # `#@ivar` (also `#@@cvar`), and `#$global` — so the cop treats all three
      # escape forms (`\#{`, `\#@`, `\#$`) as the escape tax, and a LIVE (unescaped)
      # occurrence of any of them blocks autocorrection.
      #
      # @example
      #   # bad — escape tax
      #   source = <<~RUBY
      #     puts "hello \#{name}"
      #   RUBY
      #
      #   # good — single-quoted delimiter, `#{...}` is literal
      #   source = <<~'RUBY'
      #     puts "hello #{name}"
      #   RUBY
      #
      # Autocorrection is UNSAFE and only offered when the heredoc has no LIVE
      # (unescaped) interpolation: switching the delimiter to single-quoted would
      # freeze a live interpolation into literal text, changing behaviour. When a
      # live interpolation is present the cop reports but leaves the fix to a human.
      class EscapedInterpolationInHeredoc < Base
        extend AutoCorrector

        MSG = "Use a single-quoted heredoc delimiter (`%<delimiter>s`) so " \
              "`\#{...}` is literal without escaping."
        MSG_LIVE = "#{MSG} This heredoc also has a live interpolation — fix by hand.".freeze

        # A backslash directly in front of an interpolation opener. Ruby opens an
        # interpolation with `#{`, `#@` (ivar/cvar), or `#$` (global), so an escape
        # is a backslash + `#` + one of those sigil characters. The lookahead keeps
        # the sigil out of the match, so de-escaping only strips the backslash.
        ESCAPED_INTERPOLATION = /\\#(?=[{@$])/

        def on_str(node)
          check_heredoc(node)
        end

        # A heredoc with a live `#{...}` parses as a dstr; the escaped ones inside
        # it still show up in the body source. Same check.
        def on_dstr(node)
          check_heredoc(node)
        end

        private

        def check_heredoc(node)
          return unless node.heredoc?

          opening = node.loc.expression
          return if single_quoted?(opening.source)
          return unless escaped_interpolation?(node)

          live = live_interpolation?(node)
          add_offense(opening, message: message(opening.source, live: live)) do |corrector|
            next if live # unsafe to autocorrect — a live #{...} would freeze

            autocorrect(corrector, node, opening)
          end
        end

        def message(delimiter, live:)
          format(live ? MSG_LIVE : MSG, delimiter: single_quote(delimiter))
        end

        # `<<~RUBY` → `<<~'RUBY'`. The prefix (`<<`, `<<~`, or `<<-`) is kept; only
        # the identifier gets wrapped in single quotes.
        def single_quote(delimiter)
          delimiter.sub(/(<<[~-]?)(\w+)\z/, "\\1'\\2'")
        end

        def single_quoted?(delimiter)
          delimiter.include?("'")
        end

        def escaped_interpolation?(node)
          node.loc.heredoc_body.source.match?(ESCAPED_INTERPOLATION)
        end

        # A live interpolation makes the heredoc a dstr whose children include a
        # non-`str` node: `#{expr}` → a `begin` child, `#@ivar` → an `ivar` child,
        # `#$global` → a `gvar` child. Escaped forms stay inside plain `str`
        # children, so a str heredoc — or a dstr of only `str` children — is safe
        # to convert. (Checking "not a str" rather than enumerating begin/ivar/gvar
        # covers every interpolation node the parser can emit.)
        def live_interpolation?(node)
          node.dstr_type? && node.children.any? { |child| !child.str_type? }
        end

        # Swap the opening delimiter for its single-quoted form and drop the
        # backslash from every escaped interpolation (`\#{`, `\#@`, `\#$`) in the
        # body — the single-quoted delimiter already makes each one literal, and
        # leaving a backslash behind would turn an escape-consumed byte into a
        # literal one, changing the string.
        def autocorrect(corrector, node, opening)
          corrector.replace(opening, single_quote(opening.source))

          body = node.loc.heredoc_body
          unescaped = body.source.gsub(ESCAPED_INTERPOLATION, "#")
          corrector.replace(body, unescaped)
        end
      end
    end
  end
end
