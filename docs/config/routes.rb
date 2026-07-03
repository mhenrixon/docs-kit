Rails.application.routes.draw do
  root "landings#show"

  # Docs search — served from the registry by the gem's DocsKit::SearchController
  # (matches the default c.search_path). MUST come before `docs/:doc` or that
  # route swallows /docs/search as :doc.
  get "/docs/search" => "docs_kit/search#index", as: :docs_search
  get "docs/:doc(.:format)" => "docs#show", as: :doc

  # AI-readable docs (llmstxt.org) — served from the registry by the gem's
  # DocsKit::LlmsController, zero authoring. /llms.txt is the index; /llms-full.txt
  # concatenates every page's Markdown twin.
  get "/llms.txt" => "docs_kit/llms#index", as: :llms
  get "/llms-full.txt" => "docs_kit/llms#full", as: :llms_full

  # Read-only MCP endpoint (DocsKit::McpController) — dogfooding docs-kit's own
  # optional MCP server. POST speaks JSON-RPC (search_docs / get_page /
  # list_pages); GET/DELETE are 405 (read-only, stateless — no SSE session).
  post "/mcp" => "docs_kit/mcp#create", as: :mcp
  match "/mcp" => "docs_kit/mcp#method_not_allowed", via: %i[get delete]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
