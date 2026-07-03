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

  # Getting started
  page "Overview",      group: "Getting started"
  page "Installation",  group: "Getting started"
  page "Configuration", group: "Getting started"
  page "Styling & CSS", group: "Getting started", slug: "styling", view: "Styling"

  # Authoring
  page "Authoring pages",    group: "Authoring", slug: "authoring", view: "Authoring"
  page "Markdown authoring", group: "Authoring", slug: "markdown", view: "Markdown"
  page "Code languages",     group: "Authoring", slug: "languages", view: "Languages"
  page "API reference",      group: "Authoring", slug: "api", view: "Api"

  # Reference
  page "Components",   group: "Reference"
  page "On this page", group: "Reference"

  # AI & tooling
  page "AI & agents", group: "AI & tooling", slug: "ai", view: "Ai"
  page "Search",      group: "AI & tooling"

  # Deploy
  page "Deploy", group: "Deploy"
end
