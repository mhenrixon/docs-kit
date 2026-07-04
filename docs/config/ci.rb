# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"

  step "Style: Ruby", "bin/rubocop"

  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: Importmap vulnerability audit", "bin/importmap audit"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

  # The RSpec suite: request specs (progressive enhancement, the .md/llms.txt
  # routes) + browser system specs (the SEO/OG head end-to-end, the chrome, theme
  # persistence) driven by a real Playwright chromium. Headless; the browser must
  # be installed (`bunx playwright install chromium`) — the CI workflow does this.
  step "Test: RSpec (request + system specs)", "bin/rspec"


  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
