# frozen_string_literal: true

module DocsUI
  # A titled doc section with an anchor (so the heading is linkable) and an
  # optional description rendered under the title, before the body. Use inside a
  # Page; compose with Prose for the text.
  #
  #   # plain section
  #   render DocsUI::Section.new("Add the gem") { render DocsUI::Prose.new { … } }
  #
  #   # with a one-line description (a muted lead under the title)
  #   render DocsUI::Section.new("Overview", description: "What this endpoint does.") do
  #     render DocsUI::Prose.new { … }
  #   end
  #
  #   # richer description (e.g. an API endpoint) — pass a block as `description:`
  #   render DocsUI::Section.new("Create a message", description: -> {
  #     code(class: "badge badge-sm") { "POST" }; plain " /v1/messages"
  #   }) { render DocsUI::Prose.new { … } }
  #
  # The description is rendered only when present, so plain sections are unchanged.
  class Section < Phlex::HTML
    def initialize(title, id: nil, description: nil)
      @title = title
      @id = id || slugify(title)
      @description = description
    end

    def view_template(&)
      section(id: @id, class: "mb-10 scroll-mt-20") do
        heading
        description
        yield
      end
    end

    private

    def heading
      h2(class: "group mb-2 text-2xl font-semibold tracking-tight") do
        a(href: "##{@id}", class: "no-underline") do
          plain @title
          span(class: "ml-2 text-base-content/30 opacity-0 transition group-hover:opacity-100") { "#" }
        end
      end
    end

    # The optional description: a String is rendered as text; a callable (proc/
    # lambda) is instance_exec'd so it can emit rich Phlex markup (code, badges).
    def description
      return unless @description

      p(class: "mb-4 text-base leading-relaxed text-base-content/70") do
        if @description.respond_to?(:call)
          instance_exec(&@description)
        else
          plain @description
        end
      end
    end

    # ActiveSupport's #parameterize when available (Rails host), else a minimal
    # ASCII slug so the component works in isolated Phlex tests too.
    def slugify(text)
      return text.parameterize if text.respond_to?(:parameterize)

      text.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
    end
  end
end
