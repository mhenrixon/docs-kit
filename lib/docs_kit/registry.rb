# frozen_string_literal: true

module DocsKit
  # A mixin for an in-memory docs registry (guides, demos, component references).
  # Each site defines a plain-Ruby class whose instances wrap a frozen entry Hash;
  # extending Registry gives the shared lookup/grouping API so every site's
  # registry behaves identically and the Sidebar can consume any of them.
  #
  #   class Doc
  #     extend DocsKit::Registry
  #     entries [
  #       { slug: "installation", title: "Installation", group: "Guide", view: "Installation" },
  #     ]
  #     group_by_attribute :group
  #     attr_reader :slug, :title, :group, :view_name
  #     def initialize(entry)
  #       @slug = entry[:slug]; @title = entry[:title]
  #       @group = entry[:group]; @view_name = entry[:view]
  #     end
  #     # Resolve the authored Phlex page; nil if not yet written.
  #     def view_class = "Views::Docs::Pages::#{view_name}".safe_constantize
  #   end
  #
  #   Doc.all                                    # => [Doc, ...]
  #   Doc.from_slug("installation")              # => Doc | nil
  #   Doc.grouped                                # => { "Guide" => [Doc, ...] }
  #   Doc.all.select(&:view_class).group_by(&:group)  # "authored" filter
  module Registry
    # Declares the frozen registry data. Called once at class definition.
    def entries(list = nil)
      return @entries if list.nil?

      @entries = list.map(&:freeze).freeze
    end

    # The attribute used by #grouped (default :group).
    def group_by_attribute(attr = nil)
      @group_by_attribute = attr if attr
      @group_by_attribute || :group
    end

    # All registry instances (built fresh each call — instances are cheap and a
    # site may resolve view classes that change under code reload in development).
    def all
      (entries || []).map { |entry| new(entry) }
    end

    # The instance whose slug matches, or nil.
    def from_slug(slug)
      all.find { |item| item.slug.to_s == slug.to_s }
    end

    # { group_value => [instances] }, preserving registry order within a group.
    def grouped
      all.group_by { |item| item.public_send(group_by_attribute) }
    end
  end
end
