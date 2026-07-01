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
    // What to collect for the TOC. Defaults to docs-kit's anchored sections
    // (Docs::Section renders <section id>) plus bare anchored headings, so it
    // works whether the id sits on the section or directly on the heading.
    headings: { type: String, default: "section[id], h2[id], h3[id]" },
    // Namespaces the localStorage keys so multiple docs sites don't collide.
    storageKey: { type: String, default: "docs" },
    // Auto-TOC placement: "panel" | "toggle" | "sidebar" | "" (off). Panel and
    // toggle fill a server-rendered [data-docs-nav-target=toc]; sidebar injects
    // the list under the active left-nav link (no server slot).
    onPage: { type: String, default: "" },
    // Fewer than this many headings → hide the TOC entirely (short pages).
    minHeadings: { type: Number, default: 2 },
  }

  // tocLink: pre-rendered TOC links to spy on.
  // toc: a server-rendered container the controller fills with heading links.
  // tocRoot: the element hidden when the page has too few headings.
  // codeGroup/codeTab/codePanel: a multi-language Docs::Example — the controller
  // shows the panel for the globally-remembered language and hides the others.
  static targets = ["tocLink", "toc", "tocRoot", "codeGroup", "codeTab", "codePanel"]

  connect() {
    this.restoreCollapseState()
    this.onToggle = this.persistToggle.bind(this)
    // `toggle` doesn't bubble; capture it so one listener covers every <details>.
    this.element.addEventListener("toggle", this.onToggle, true)
    this.buildToc()
    this.startScrollSpy()
    this.applyLanguage(this.readLanguage())
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

  // Build the "On this page" list from the page's headings — no server-side
  // knowledge of them needed — and place it per the on_page mode. Too few
  // headings hides the whole TOC (short pages show nothing).
  buildToc() {
    const content = document.querySelector(this.contentValue)
    if (!content) return
    const headings = Array.from(content.querySelectorAll(this.headingsValue))

    if (headings.length < this.minHeadingsValue) {
      this.hideToc()
      return
    }

    const list = this.buildList(headings)
    if (this.onPageValue === "sidebar") this.placeInSidebar(list)
    else this.placeInSlot(list)
  }

  buildList(headings) {
    const list = document.createElement("ul")
    list.className = "menu menu-sm w-full"
    list.setAttribute("data-docs-nav-generated", "")
    headings.forEach((el) => {
      // The anchor is the element's own id; the visible heading may be the
      // element itself (h2/h3) or its inner heading (a Docs::Section wrapper).
      const heading =
        el.matches("h1,h2,h3,h4") ? el : el.querySelector("h1,h2,h3,h4")
      const li = document.createElement("li")
      if ((heading?.tagName || el.tagName) === "H3") li.className = "ml-3"
      const a = document.createElement("a")
      a.href = `#${el.id}`
      a.textContent = (heading?.textContent || el.textContent || "")
        .replace(/#$/, "")
        .trim()
      a.setAttribute("data-docs-nav-target", "tocLink")
      li.appendChild(a)
      list.appendChild(li)
    })
    return list
  }

  // panel / toggle: fill the server-rendered [data-docs-nav-target=toc].
  placeInSlot(list) {
    if (!this.hasTocTarget) return
    this.tocTarget.querySelector("ul[data-docs-nav-generated]")?.remove()
    this.tocTarget.appendChild(list)
  }

  // sidebar: nest the list under the active left-nav link (.menu-active), so the
  // current page's sub-headings appear right under it (GitBook style).
  placeInSidebar(list) {
    const active = this.element.querySelector("a.menu-active")
    const host = active?.closest("li")
    if (!host) return
    host.querySelector("ul[data-docs-nav-generated]")?.remove()
    host.appendChild(list)
  }

  hideToc() {
    if (this.hasTocRootTarget) this.tocRootTargets.forEach((el) => (el.hidden = true))
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

    // Seed the highlight immediately (don't wait for the first scroll): the URL
    // hash if present, else the first section. Makes deep-links land highlighted.
    const hashId = decodeURIComponent((window.location.hash || "").slice(1))
    const initial = headings.find((h) => h.id === hashId) || headings[0]
    if (initial) this.highlight(initial.id)
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

  // --- 3. Multi-language code groups (Docs::Example) --------------------------

  get languageKey() {
    return `docs-kit:${this.storageKeyValue}:code-lang`
  }

  readLanguage() {
    return this.read(this.languageKey)
  }

  // Tab click: remember the language globally and re-apply to every code group.
  selectLanguage(event) {
    const lang = event.params.lang
    if (!lang) return
    this.write(this.languageKey, lang)
    this.applyLanguage(lang)
  }

  // Show the chosen language in each code group. A group without that language
  // falls back to its own first snippet, so switching never blanks a group.
  applyLanguage(preferred) {
    if (!this.hasCodeGroupTarget) return

    this.codeGroupTargets.forEach((group) => {
      const panels = this.groupPanels(group)
      if (panels.length === 0) return

      const chosen =
        panels.find((p) => p.dataset.lang === preferred) || panels[0]

      panels.forEach((p) => (p.hidden = p !== chosen))
      this.groupTabs(group).forEach((tab) =>
        tab.classList.toggle("tab-active", tab.dataset.docsNavLangParam === chosen.dataset.lang),
      )
    })
  }

  groupPanels(group) {
    return this.codePanelTargets.filter((p) => group.contains(p))
  }

  groupTabs(group) {
    return this.codeTabTargets.filter((t) => group.contains(t))
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
