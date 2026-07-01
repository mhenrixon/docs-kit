import { Controller } from "@hotwired/stimulus"

// docs-nav — client-only UX polish for the docs sidebar. No server round-trip:
// collapse state is per-browser UI state (localStorage), and scroll-spy is a
// pure viewport concern (IntersectionObserver). Attach to the sidebar root:
//
//   <div data-controller="docs-nav"
//        data-docs-nav-content-value="#doc-content"
//        data-docs-nav-storage-key-value="phlex-reactive">
//     ...nested <details><summary>...</summary></details>...
//   </div>
//
// Two behaviors, each independent and each degrading to a harmless no-op:
//
//  1. Collapse persistence — remembers which <details> the reader opened/closed,
//     keyed by the summary's text, so the sidebar stays how they left it across
//     navigations. Server still renders every <details open> by default, so with
//     JS off the sidebar is fully expanded (progressive enhancement).
//
//  2. Scroll-spy — as the reader scrolls the page, the heading nearest the top is
//     "current"; the matching table-of-contents link (data-docs-nav-target=
//     "tocLink" whose href fragment equals the heading id) gets .menu-active, and
//     the heading itself gets [data-current]. No TOC on the page → no-op.
export default class extends Controller {
  static values = {
    // CSS selector for the page content whose headings drive scroll-spy.
    content: { type: String, default: "main" },
    // Heading selector within the content (anchored headings only).
    headings: { type: String, default: "h2[id], h3[id]" },
    // Namespaces the localStorage keys so multiple docs sites don't collide.
    storageKey: { type: String, default: "docs" },
  }

  // tocLink: pre-rendered TOC links to spy on.
  // toc: an empty container the controller fills with links built from the page's
  //      headings (so a page gets an "On this page" list with zero data wiring).
  static targets = ["tocLink", "toc"]

  connect() {
    this.restoreCollapseState()
    this.onToggle = this.persistToggle.bind(this)
    // `toggle` doesn't bubble; capture it so one listener covers every <details>.
    this.element.addEventListener("toggle", this.onToggle, true)
    this.buildToc()
    this.startScrollSpy()
  }

  disconnect() {
    this.element.removeEventListener("toggle", this.onToggle, true)
    this.observer?.disconnect()
  }

  // --- 1. Collapse persistence ------------------------------------------------

  get storagePrefix() {
    return `docs-kit:${this.storageKeyValue}:nav:`
  }

  // A stable key for a <details> from its summary text (position-independent, so
  // reordering the nav doesn't lose state).
  keyFor(details) {
    const summary = details.querySelector(":scope > summary")
    const label = (summary?.textContent || "").trim()
    return label ? this.storagePrefix + label : null
  }

  restoreCollapseState() {
    this.element.querySelectorAll("details").forEach((details) => {
      const key = this.keyFor(details)
      if (!key) return
      const saved = this.read(key)
      if (saved === "open") details.open = true
      else if (saved === "closed") details.open = false
    })
  }

  persistToggle(event) {
    const details = event.target
    if (details.tagName !== "DETAILS") return
    const key = this.keyFor(details)
    if (key) this.write(key, details.open ? "open" : "closed")
  }

  // --- 2. Scroll-spy ----------------------------------------------------------

  // Fill a toc target with a link per page heading, so an "On this page" panel
  // needs no server-side knowledge of the headings. Indents h3 under h2.
  buildToc() {
    if (!this.hasTocTarget) return
    const content = document.querySelector(this.contentValue)
    if (!content) return
    const headings = Array.from(content.querySelectorAll(this.headingsValue))
    if (headings.length === 0) return

    const list = document.createElement("ul")
    list.className = "menu menu-sm w-full"
    headings.forEach((h) => {
      const li = document.createElement("li")
      if (h.tagName === "H3") li.className = "ml-3"
      const a = document.createElement("a")
      a.href = `#${h.id}`
      a.textContent = h.textContent.replace(/#$/, "").trim()
      a.setAttribute("data-docs-nav-target", "tocLink")
      li.appendChild(a)
      list.appendChild(li)
    })
    // Append (don't replace) so a title/label already inside the toc survives.
    // Remove any list we built on a previous connect (Turbo re-render).
    this.tocTarget.querySelector("ul[data-docs-nav-generated]")?.remove()
    list.setAttribute("data-docs-nav-generated", "")
    this.tocTarget.appendChild(list)
  }

  startScrollSpy() {
    const content = document.querySelector(this.contentValue)
    if (!content) return
    const headings = Array.from(content.querySelectorAll(this.headingsValue))
    if (headings.length === 0) return

    this.visible = new Set()
    this.observer = new IntersectionObserver(
      (entries) => this.onIntersect(entries, headings),
      // A band near the top of the viewport: a heading is "current" once it
      // crosses into the top ~15%, staying current until the next one does.
      { rootMargin: "0px 0px -80% 0px", threshold: 0 },
    )
    headings.forEach((h) => this.observer.observe(h))
  }

  onIntersect(entries, headings) {
    entries.forEach((entry) => {
      if (entry.isIntersecting) this.visible.add(entry.target)
      else this.visible.delete(entry.target)
    })
    // The current heading is the topmost currently-visible one, or (when none is
    // in the band, e.g. between two) the last heading scrolled past.
    const current =
      headings.find((h) => this.visible.has(h)) ||
      headings.filter((h) => h.getBoundingClientRect().top < 0).at(-1)
    if (current) this.highlight(current.id)
  }

  highlight(id) {
    if (id === this.currentId) return
    this.currentId = id

    this.element
      .querySelectorAll("[data-current]")
      .forEach((el) => el.removeAttribute("data-current"))

    this.tocLinkTargets.forEach((link) => {
      const active = (link.getAttribute("href") || "").endsWith(`#${id}`)
      link.classList.toggle("menu-active", active)
      if (active) link.setAttribute("data-current", "")
    })
  }

  // --- storage (private, fails safe if localStorage is unavailable) -----------

  read(key) {
    try {
      return window.localStorage.getItem(key)
    } catch {
      return null
    }
  }

  write(key, value) {
    try {
      window.localStorage.setItem(key, value)
    } catch {
      // Private mode / quota — collapse just won't persist. Not fatal.
    }
  }
}
