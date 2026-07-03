# frozen_string_literal: true

module DocsUI
  # A doc page header: an optional eyebrow (kicker), the title, and a lead
  # paragraph. Gives every doc page a consistent masthead.
  #
  #   render DocsUI::Header.new("Installation", eyebrow: "Guide") do
  #     plain "Add the gem and render your first component."
  #   end
  #
  # The primary argument (the title) is positional, matching Section/Code and the
  # kit-wide convention. The legacy `title:` kwarg still works so existing sites
  # keep rendering unchanged; the positional wins if both are given.
  class Header < Phlex::HTML
    # Positional title (the convention), with a silent `title:` kwarg fallback for
    # sites that still pass it by keyword. Positional wins when both are given.
    def initialize(title = nil, eyebrow: nil, **opts)
      @title = title || opts[:title]
      @eyebrow = eyebrow
    end

    def view_template(&block)
      header(class: "mb-8 border-b border-base-300 pb-6") do
        div(class: "mb-2 text-xs font-semibold uppercase tracking-wider text-primary") { @eyebrow } if @eyebrow
        h1(class: "text-3xl font-bold tracking-tight md:text-4xl") { @title }
        p(class: "mt-3 text-lg text-base-content/70", &block) if block
      end
    end
  end
end
