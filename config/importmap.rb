# frozen_string_literal: true

# Auto-pins the gem's bundled Stimulus controllers for importmap-rails consumers.
# Exposes `docs_kit/controllers/docs_nav_controller`. Register it in the host app:
#
#   // app/javascript/controllers/index.js
#   import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
#   eagerLoadControllersFrom("docs_kit/controllers", application)
#
# Use eagerLoadControllersFrom (already imported in the default index.js), NOT
# lazyLoadControllersFrom — the latter isn't imported there, so calling it throws
# a ReferenceError that aborts the module and no controllers register at all.
pin_all_from DocsKit::Engine.root.join("app/javascript/docs_kit/controllers"),
             under: "docs_kit/controllers",
             to: "docs_kit/controllers"
