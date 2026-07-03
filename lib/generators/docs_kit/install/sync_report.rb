# frozen_string_literal: true

module DocsKit
  module Generators
    # Detects manual drift in an existing docs site that the install generator
    # can't safely automate away — things docs-kit now provides, so the site's
    # own copy is dead weight. String-level and CONSERVATIVE by design: it reads
    # a few known files, reports what it finds, and never touches a byte. The
    # generator prints these as a checklist during a `--sync` upgrade; the site
    # owner deletes the flagged code by hand.
    #
    # Two drift items, both from the consumer audits:
    #   - ApplicationController hand-defines `render_page` — DocsKit::Controller
    #     (included by the generator for months) already provides it.
    #   - a dead IconHelper copy — the gem renders icons via rails_icons.
    class SyncReport
      APPLICATION_CONTROLLER = "app/controllers/application_controller.rb"
      ICON_HELPER = "app/helpers/icon_helper.rb"

      def initialize(destination_root)
        @root = destination_root
      end

      # The drift messages, in the order a site should act on them. Empty when
      # the site is clean.
      def items
        [render_page_drift, icon_helper_drift].compact
      end

      def clean?
        items.empty?
      end

      private

      # ApplicationController defines its own `render_page` — DocsKit::Controller
      # already provides it, so the hand-rolled method shadows the gem's and
      # fossilizes whatever `layout:`/render call the site copied years ago.
      def render_page_drift
        source = read(APPLICATION_CONTROLLER)
        return unless source&.match?(/def\s+render_page\b/)

        "#{APPLICATION_CONTROLLER} defines its own render_page — delete it; " \
          "DocsKit::Controller#render_page is included."
      end

      # A leftover IconHelper — docs-kit renders icons through rails_icons
      # (DocsUI::Icon), so a hand-written helper is dead code.
      def icon_helper_drift
        return unless exist?(ICON_HELPER)

        "#{ICON_HELPER} (IconHelper) is dead — docs-kit renders icons via " \
          "rails_icons (DocsUI::Icon); delete it."
      end

      def read(rel)
        path = File.join(@root, rel)
        File.exist?(path) ? File.read(path) : nil
      end

      def exist?(rel) = File.exist?(File.join(@root, rel))
    end
  end
end
