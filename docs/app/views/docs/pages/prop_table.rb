# frozen_string_literal: true

module Views
  module Docs
    module Pages
      # A small, page-local helper for rendering an options/props reference table
      # (name · type · default · description). Used by the reference pages to
      # document component args and config options consistently. Not part of the
      # DocsUI kit — it's specific to these docs.
      #
      #   render PropTable.new(
      #     ["Option", "Type", "Default", "Description"],
      #     [
      #       ["brand", "String", '"Docs"', "Topbar + sidebar heading."],
      #       ["themes", "Array", "%w[dark light]", "ThemeSwitcher options."],
      #     ]
      #   )
      class PropTable < Phlex::HTML
        def initialize(headers, rows)
          @headers = headers
          @rows = rows
        end

        def view_template
          div(class: "not-prose my-4 overflow-x-auto rounded-box border border-base-300") do
            table(class: "table table-sm table-zebra") do
              thead do
                tr do
                  @headers.each { |h| th(class: "whitespace-nowrap") { h } }
                end
              end
              tbody do
                @rows.each do |cells|
                  tr do
                    cells.each_with_index do |cell, i|
                      # First column (the name) as inline code; the rest plain.
                      td { i.zero? ? code(class: "text-sm") { cell.to_s } : render_cell(cell) }
                    end
                  end
                end
              end
            end
          end
        end

        private

        # A cell may be a plain String, or a [:code, "x"] pair to render as code.
        def render_cell(cell)
          if cell.is_a?(Array) && cell.first == :code
            code(class: "text-sm") { cell.last.to_s }
          else
            plain cell.to_s
          end
        end
      end
    end
  end
end
