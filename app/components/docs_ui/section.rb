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
  #   # or pass a renderable Phlex component directly (e.g. DocsUI::Endpoint)
  #   render DocsUI::Section.new("Create a message",
  #     description: DocsUI::Endpoint.new(:post, "/v1/messages")) { … }
  #
  # The description is rendered only when present, so plain sections are unchanged.
  class Section < Phlex::HTML
    def initialize(title, id: nil, description: nil)
      @title = title
      @explicit_id = id
      @description = description
    end

    def view_template(&)
      # Resolve the anchor id at render time so it can be de-duplicated against
      # sibling sections sharing this page's render context (see #resolve_id).
      @id = @explicit_id || unique_id(slugify(@title))
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

    # The optional description, rendered under the title. Three accepted forms:
    #   * a Phlex component instance (e.g. DocsUI::Endpoint) → rendered in place;
    #   * a proc/lambda → instance_exec'd so it can emit rich Phlex markup;
    #   * a String → plain, Phlex-escaped text.
    # A Phlex component also responds to #call, so it MUST be matched before the
    # callable branch (else it would be instance_exec'd, not rendered).
    def description
      return unless @description

      p(class: "mb-4 text-base leading-relaxed text-base-content/70") do
        case @description
        when Phlex::SGML then render @description
        else @description.respond_to?(:call) ? instance_exec(&@description) : plain(@description)
        end
      end
    end

    # ActiveSupport's #parameterize when available (Rails host), else a minimal
    # ASCII slug so the component works in isolated Phlex tests too.
    def slugify(text)
      return text.parameterize if text.respond_to?(:parameterize)

      text.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
    end

    # De-duplicate the anchor id across every Section on the page. Phlex's render
    # `context` is a Hash shared by the whole render tree, so sibling sections see
    # the same used-id counter without any shared parent state. A title that
    # slugifies to "" (e.g. "C++" → "c" is fine, but "+++" → "") falls back to
    # "section"; colliding bases get a "-1", "-2", … sequence suffix so in-page
    # anchors and the auto-TOC/scroll-spy resolve to distinct headings.
    def unique_id(base)
      base = "section" if base.empty?
      used = (context[:__docs_ui_section_ids__] ||= Hash.new(0))
      n = used[base]
      used[base] += 1
      n.zero? ? base : "#{base}-#{n}"
    end
  end
end
