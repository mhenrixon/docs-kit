# frozen_string_literal: true

module Docs
  # A callout box (note / tip / warning) for the docs. daisyUI alert styling + a
  # lucide icon per level.
  #
  #   render Docs::Callout.new(:warning) { "Restart the server after…" }
  class Callout < Phlex::HTML
    LEVELS = {
      note: { klass: "alert-info", icon: "info" },
      tip: { klass: "alert-success", icon: "lightbulb" },
      warning: { klass: "alert-warning", icon: "triangle-alert" }
    }.freeze

    def initialize(level = :note, title: nil)
      @config = LEVELS.fetch(level, LEVELS[:note])
      @title = title
    end

    def view_template(&)
      div(class: "not-prose alert #{@config[:klass]} my-4 items-start", role: "note") do
        render Docs::Icon.new(@config[:icon], class: "size-5 shrink-0")
        div do
          div(class: "font-semibold") { @title } if @title
          div(class: "text-sm", &)
        end
      end
    end
  end
end
