# frozen_string_literal: true

# In-memory registry of the reference docs. Each entry maps a URL slug to its
# title, sidebar group, and the Phlex page class that renders it. Add a page by
# adding an entry here and a class under app/views/docs/pages/.
#
# Uses DocsKit::Registry for the shared all/from_slug/grouped API.
class Doc
  extend DocsKit::Registry

  entries [
    { slug: "overview",      title: "Overview",       group: "Getting started", view: "Overview" },
    { slug: "installation",  title: "Installation",   group: "Getting started", view: "Installation" },
    { slug: "configuration", title: "Configuration",  group: "Getting started", view: "Configuration" },
    { slug: "authoring",     title: "Authoring pages", group: "Getting started", view: "Authoring" },
    { slug: "styling",       title: "Styling & CSS",  group: "Getting started", view: "Styling" },
    { slug: "components",    title: "Components",     group: "Reference", view: "Components" },
    { slug: "languages",     title: "Code languages", group: "Reference", view: "Languages" },
    { slug: "on-this-page",  title: "On this page",   group: "Reference", view: "OnThisPage" },
    { slug: "deploy",        title: "Deploy",         group: "Reference", view: "Deploy" }
  ]

  attr_reader :slug, :title, :group, :view_name

  def initialize(entry)
    @slug = entry[:slug]
    @title = entry[:title]
    @group = entry[:group]
    @view_name = entry[:view]
  end

  # The hand-authored Phlex page class (nil until the class exists — the sidebar
  # only links docs whose page is written, so no dead links).
  def view_class
    "Views::Docs::Pages::#{view_name}".safe_constantize
  end
end
