# frozen_string_literal: true

module DocsUI
  # An HTTP endpoint reference line — a method badge followed by the path — in the
  # kit's daisyUI look. This is the `code(class: "badge …")` lambda every API page
  # was hand-rolling; compose it instead.
  #
  #   render DocsUI::Endpoint.new(:post, "/v1/messages")
  #   # => POST /v1/messages   (POST as a primary badge, path monospace)
  #
  # It renders INLINE (no block wrapper), so it drops straight into a Section
  # description or a run of prose:
  #
  #   DocsUI::Section("Create a message", description: DocsUI::Endpoint.new(:post, "/v1/messages"))
  #
  # The verb → badge-colour map is an explicit frozen Hash of LITERAL class
  # strings so the Tailwind scan (which reads the gem's Ruby) sees every badge
  # class and generates it. An unknown verb falls back to a neutral badge and
  # never raises — a typo degrades gracefully rather than blowing up a render.
  class Endpoint < Phlex::HTML
    # Each value is a single literal string (not interpolated) so Tailwind's
    # source scan generates the colour. Keep these literal — see Critical Rule 6.
    BADGE_CLASSES = {
      "GET" => "badge badge-sm badge-success",
      "POST" => "badge badge-sm badge-primary",
      "PUT" => "badge badge-sm badge-warning",
      "PATCH" => "badge badge-sm badge-warning",
      "DELETE" => "badge badge-sm badge-error"
    }.freeze

    NEUTRAL_BADGE = "badge badge-sm badge-neutral"

    def initialize(method, path)
      @method = method.to_s.upcase
      @path = path
    end

    def view_template
      code(class: BADGE_CLASSES.fetch(@method, NEUTRAL_BADGE)) { plain @method }
      whitespace
      code { plain @path }
    end
  end
end
