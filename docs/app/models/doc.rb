# frozen_string_literal: true

# In-memory registry of the reference docs. One line per page — slug and view
# derive from the title (both overridable), and the sidebar nav derives from
# this registry with zero extra code (see config/initializers/docs_kit.rb's
# `nav_registries`). Add a page with `rails g docs_kit:page "Title" --group=…`,
# which appends the `page` line here and writes the class under
# app/views/docs/pages/.
#
# Uses DocsKit::Registry for the shared all/from_slug/grouped/nav_items API.
class Doc
  extend DocsKit::Registry
  path_prefix    "/docs"
  view_namespace "Views::Docs::Pages"

  page "Overview",        group: "Getting started"
  page "Installation",    group: "Getting started"
  page "Configuration",   group: "Getting started"
  page "Authoring pages", group: "Getting started", slug: "authoring", view: "Authoring"
  page "Styling & CSS",   group: "Getting started", slug: "styling", view: "Styling"
  page "Components",      group: "Reference"
  page "Code languages",  group: "Reference", slug: "languages", view: "Languages"
  page "On this page",    group: "Reference"
  page "Deploy",          group: "Reference"
end
