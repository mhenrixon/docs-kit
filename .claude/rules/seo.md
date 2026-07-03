# SEO & Social-Share Rules

docs-kit emits a full SEO `<head>` (description, Open Graph, Twitter Card,
canonical, favicon, robots, theme-color) from **config**, never markup:
`DocsUI::MetaTags` reads `DocsKit.configuration.seo` + the per-page
title/description. The same invariants as the rest of the chrome apply.

## Always Do

1. **Read config, with a backwards-safe default** — a new SEO knob lives on
   `DocsKit::SeoConfig` with a default so a site that sets nothing still renders a
   valid minimal card. The `<head>` must stay a **strict superset** of the pre-SEO
   markup for an unconfigured site.
2. **Let Phlex escape config free text** — description/title/brand flow into
   `<meta content="...">` as ordinary Phlex attribute values (never `raw`/
   `html_safe`). A double-quote must be escaped so it can't break out of the
   attribute; that is the security property to preserve.
3. **Per-page description = `self.class.description || lead`** — authorable, with
   a `#lead`-derived fallback. Don't require every page to set one.
4. **Guard the no-request path** — `DocsUI::MetaTags` may render with no Rails
   request (an isolated Phlex render, a static build). Guard `view_context`
   presence like `Shell#csp_nonce` does; degrade (omit canonical, use the raw
   `og_image` path) rather than raise.

## The OG-image re-generation routine

The social-share image is each **site's own** landing page, screenshotted by the
host-run `bin/rails docs_kit:og` task — it is **not** committed into the gem
(the gem ships only a neutral default). This mirrors phlex-reactive's
vendored-client re-sync: a **documented manual command + a guard spec**, never a
cron.

- **When the landing page changes materially**, re-run `bin/rails docs_kit:og`
  (in a consuming site) so the OG image reflects it.
- `spec/docs_kit/og_image_spec.rb` guards the shipped default (present + valid
  PNG). If it fails, the default was deleted/corrupted — restore it, don't delete
  the spec.
- The screenshot tooling (shot-scraper / chromium) is resolved at **task
  runtime** and is **never** a docs-kit runtime dependency — the gem's own CI must
  stay browser-free. `DocsKit::OgGenerator` is zeitwerk-ignored and loaded only by
  the task.

## Never Do

- **NO** committing per-site OG screenshots into the gem (they're site content).
- **NO** cron/CI job to refresh OG images — it's a manual, documented command.
- **NO** headless-browser dependency in the gemspec or the gem's CI.
- **NO** theme/robots/canonical value that isn't config-driven and defaulted.
