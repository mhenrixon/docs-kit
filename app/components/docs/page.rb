# frozen_string_literal: true

module Docs
  # The base class for a hand-authored doc page. Subclasses set the title (and
  # optional eyebrow/lead) and implement #content with the page body, composing
  # the doc kit (Section/Prose/Code/Callout). Page renders it inside Docs::Shell
  # with a consistent masthead.
  #
  #   class Views::Docs::Pages::Installation < Docs::Page
  #     title "Installation"
  #     eyebrow "Guide"
  #     def lead = "Add the gem and render your first component."
  #     def content
  #       render Docs::Section.new("Add the gem") { … }
  #     end
  #   end
  class Page < Phlex::HTML
    include Phlex::Rails::Helpers::Routes

    class << self
      def title(value = nil)
        @title = value if value
        @title
      end

      def eyebrow(value = nil)
        @eyebrow = value if value
        @eyebrow
      end
    end

    def view_template
      render Docs::Shell.new(title: self.class.title) do
        nav(class: "mb-6") do
          a(href: root_path, class: "link link-hover text-sm opacity-70") { "← Home" }
        end

        render Docs::Header.new(title: self.class.title, eyebrow: self.class.eyebrow) do
          plain lead if lead
        end

        content
      end
    end

    # Override in subclasses for the lead paragraph (optional).
    def lead = nil

    # Override in subclasses with the page body.
    def content
      raise NotImplementedError, "#{self.class} must implement #content"
    end
  end
end
