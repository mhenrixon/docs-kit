# frozen_string_literal: true

# Auto-pins the gem's bundled Stimulus controllers for importmap-rails consumers.
# Exposes `docs_kit/controllers/docs_nav_controller`. Register it in the host app:
#
#   // app/javascript/controllers/index.js
#   import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
#   lazyLoadControllersFrom("docs_kit/controllers", application)
pin_all_from DocsKit::Engine.root.join("app/javascript/docs_kit/controllers"),
             under: "docs_kit/controllers",
             to: "docs_kit/controllers"
