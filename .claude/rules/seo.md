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

## The OG image is SITE content — the gem ships none

The social-share image is each **site's own** landing page, screenshotted by the
host-run `bin/rails docs_kit:og` task into the SITE'S `app/assets/images/`. The
gem ships **no** OG image and `c.seo.og_image` defaults to **nil** — a site's
landing page isn't docs-kit's to render.

- `og_image` is a **logical asset path in the site's pipeline** (`"og/og.png"`),
  resolved via `image_url` to the digested `/assets/og/og-<digest>.png` URL
  Propshaft serves. NEVER emit the raw config path — it 404s (this was the
  original bug). `image_url` (the Static resolver) needs the asset **precompiled**;
  a configured-but-missing image raises `MissingAssetError` at deploy
  (`assets:precompile`), which is the intended loud signal — do NOT rescue it into
  a silent 404.
- **Unset `og_image` → no `og:image` tag.** Same shape as every other opt-in tag
  (favicon/robots/theme-color): absent value → absent tag, never a broken one.
- Verify the whole chain in a **consuming site's** integration test (see
  `docs/test/integration/seo_meta_tags_test.rb`): boot the app, GET `/`, assert
  `og:image` is a `/assets/` URL AND that GETting it returns 200. Isolated
  component specs can't catch a precompile/pipeline break — only a booted app can.
- The screenshot tooling (shot-scraper / chromium) is resolved at **task
  runtime** and is **never** a docs-kit runtime dependency — the gem's own CI must
  stay browser-free. `DocsKit::OgGenerator` is zeitwerk-ignored and loaded only by
  the task.

## Never Do

- **NO** shipping an OG image (or any site-branded image) in the gem.
- **NO** emitting the raw `og_image` path as og:image — resolve it through the
  asset pipeline (`image_url`), or it 404s.
- **NO** `rescue`-ing `MissingAssetError` into a silent no-image — a broken
  `og_image` config must fail at deploy, not ship silently-broken cards.
- **NO** cron/CI job to refresh OG images — it's a manual, documented command.
- **NO** headless-browser dependency in the gemspec or the gem's CI.
- **NO** theme/robots/canonical value that isn't config-driven and defaulted.
