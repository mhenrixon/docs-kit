# frozen_string_literal: true

module Views
  module Landings
    # The home page. Renders inside DocsUI::Shell (the full document + drawer
    # shell); a short hero plus the authored docs, grouped like the sidebar.
    class Show < Phlex::HTML
      include Phlex::Rails::Helpers::Routes

      def view_template
        render DocsUI::Shell.new do
          hero
          doc_index
        end
      end

      private

      def hero
        div(class: "not-prose mb-10") do
          p(class: "mb-2 text-sm font-medium uppercase tracking-wide text-primary") { "docs-kit" }
          h1(class: "mb-4 text-4xl font-bold tracking-tight") { "Shared docs chrome for Rails, in Phlex." }
          p(class: "max-w-2xl text-lg text-base-content/70") do
            plain "A gem that gives you the shell, sidebar, theme switcher, syntax highlighting, "
            plain "multi-language examples, and an automatic table of contents — configure it once, "
            plain "write your pages, deploy with one workflow. "
            strong { "This site is built with docs-kit." }
          end
          div(class: "mt-6 flex flex-wrap gap-3") do
            a(href: "/docs/overview", class: "btn btn-primary") { "Get started" }
            a(href: "/docs/components", class: "btn btn-ghost") { "Browse components" }
          end
        end
      end

      def doc_index
        Doc.all.select(&:view_class).group_by(&:group).each do |group, docs|
          div(class: "not-prose mb-8") do
            h2(class: "mb-3 text-lg font-semibold") { group }
            div(class: "grid gap-3 sm:grid-cols-2") do
              docs.each { |doc| doc_card(doc) }
            end
          end
        end
      end

      def doc_card(doc)
        a(
          href: "/docs/#{doc.slug}",
          class: "block rounded-box border border-base-300 bg-base-200 p-4 transition hover:border-primary"
        ) do
          div(class: "font-medium") { doc.title }
        end
      end
    end
  end
end
