# frozen_string_literal: true

module DocsUI
  # A titled doc section with an anchor (so the heading is linkable). Body is the
  # block. Use inside a Page; compose with Prose for the text.
  #
  #   render DocsUI::Section.new("Add the gem") do
  #     render DocsUI::Prose.new { p { "…" } }
  #   end
  class Section < Phlex::HTML
    def initialize(title, id: nil)
      @title = title
      @id = id || slugify(title)
    end

    def view_template(&)
      section(id: @id, class: "mb-10 scroll-mt-20") do
        h2(class: "group mb-4 text-2xl font-semibold tracking-tight") do
          a(href: "##{@id}", class: "no-underline") do
            plain @title
            span(class: "ml-2 text-base-content/30 opacity-0 transition group-hover:opacity-100") { "#" }
          end
        end
        yield
      end
    end

    private

    # ActiveSupport's #parameterize when available (Rails host), else a minimal
    # ASCII slug so the component works in isolated Phlex tests too.
    def slugify(text)
      return text.parameterize if text.respond_to?(:parameterize)

      text.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
    end
  end
end
