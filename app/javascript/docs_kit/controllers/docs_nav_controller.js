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
    // Debounce (ms) between a search keystroke and the fetch, so typing fast
    // doesn't fire a request per character.
    searchDebounce: { type: Number, default: 150 },
  }

  // tocLink: pre-rendered TOC links to spy on.
  // toc: a server-rendered container the controller fills with heading links.
  // tocRoot: the element hidden when the page has too few headings.
  // tocPopover: the collapsible card revealed by the floating toggle button.
  // codeGroup/codeTab/codePanel: a multi-language Docs::Example — the controller
  // shows the panel for the globally-remembered language and hides the others.
  // markdownLink: the "Markdown" masthead action; a plain link with JS off, the
  // controller upgrades its click into copy-the-page's-markdown-to-clipboard.
  // searchScope: the dropdown root (so a click outside closes the palette).
  // searchInput: the topbar query field ("/" and Cmd/Ctrl+K focus it).
  // searchResults: the empty <ul> the controller fills with fetched hits.
  static targets = [
    "tocLink", "toc", "tocRoot", "tocPopover",
    "codeGroup", "codeTab", "codePanel",
    "markdownLink",
    "searchScope", "searchInput", "searchResults",
  ]

  connect() {
    this.restoreCollapseState()
    this.onToggle = this.persistToggle.bind(this)
    // `toggle` doesn't bubble; capture it so one listener covers every <details>.
    this.element.addEventListener("toggle", this.onToggle, true)
    this.buildToc()
    this.startScrollSpy()
    this.applyLanguage(this.readLanguage())
    this.applyTheme(this.readTheme())
    this.connectSearch()
  }

  disconnect() {
    this.element.removeEventListener("toggle", this.onToggle, true)
    this.observer?.disconnect()
    this.disconnectSearch()
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
      const text = (heading?.textContent || el.textContent || "").replace(/#$/, "").trim()
      a.textContent = text
      a.title = text // full text on hover, since the label truncates
      // Truncate long headings to one line so the card stays tidy.
      a.className = "block truncate"
      a.setAttribute("data-docs-nav-target", "tocLink")
      li.appendChild(a)
      list.appendChild(li)
    })
    return list
  }

  // panel / toggle: fill EVERY server-rendered [data-docs-nav-target=toc] (a
  // :panel has two — the wide-screen card and the toggle popover — so clone the
  // built list into each).
  placeInSlot(list) {
    if (!this.hasTocTarget) return
    this.tocTargets.forEach((slot) => {
      slot.querySelector("ul[data-docs-nav-generated]")?.remove()
      slot.appendChild(list.cloneNode(true))
    })
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

  // --- 4. Theme (global sticky preference) -----------------------------------
  //
  // daisyUI swaps the theme visually via a CSS :has() selector with zero JS, but
  // that state lives only in the DOM and is lost on navigation (the flash). We
  // persist the chosen theme to localStorage here and re-apply it; the anti-flash
  // <head> script (DocsUI::Shell) restores it BEFORE first paint so there's no
  // flicker on load.

  get themeKey() {
    return `docs-kit:${this.storageKeyValue}:theme`
  }

  readTheme() {
    return this.read(this.themeKey)
  }

  // A theme radio changed: persist + apply. Wired via change->docs-nav#selectTheme.
  selectTheme(event) {
    const theme = event.target?.value
    if (!theme) return
    this.write(this.themeKey, theme)
    this.applyTheme(theme)
  }

  // Set data-theme on <html> and check the matching radio (so the switcher shows
  // the current theme after a navigation). No saved theme → leave the server
  // default in place.
  applyTheme(theme) {
    if (!theme) return
    document.documentElement.setAttribute("data-theme", theme)
    this.element
      .querySelectorAll('input.theme-controller[type="radio"]')
      .forEach((radio) => (radio.checked = radio.value === theme))
  }

  // --- 5. On-this-page toggle (mobile / :toggle mode popover) -----------------

  toggleToc() {
    this.tocPopoverTargets.forEach((el) => el.classList.toggle("hidden"))
  }

  // --- 6. Copy page as Markdown ----------------------------------------------
  //
  // The "Markdown" masthead action is an <a href="….md"> — with JS off it opens
  // the raw Markdown twin (a working fallback). Here we intercept the click,
  // fetch that same .md, and copy it to the clipboard so the reader can paste the
  // page into an LLM. No server round-trip beyond fetching the page that already
  // exists. Anything unavailable (no clipboard API, fetch fails) falls back to
  // the link's default navigation, so the affordance is never a dead end.

  async copyMarkdown(event) {
    const link = event.currentTarget
    const href = link.getAttribute("href")
    if (!href || !navigator.clipboard) return // let the browser follow the link

    event.preventDefault()
    try {
      const response = await fetch(href, { headers: { Accept: "text/markdown" } })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      const markdown = await response.text()
      await navigator.clipboard.writeText(markdown)
      this.flashCopied(link)
    } catch {
      // Fetch/clipboard failed — navigate to the raw .md as the plain link would.
      window.location.href = href
    }
  }

  // Briefly swap the link's label to confirm the copy, then restore it. Uses the
  // trailing text node so the leading icon (if any) is untouched.
  flashCopied(link) {
    const labelNode = Array.from(link.childNodes).reverse().find((n) => n.nodeType === 3)
    if (!labelNode) return
    const original = labelNode.textContent
    labelNode.textContent = "Copied!"
    setTimeout(() => (labelNode.textContent = original), 1500)
  }

  // --- 7. Search palette ------------------------------------------------------
  //
  // Progressive enhancement over the topbar search form (DocsUI::SearchBox). With
  // JS off the form GETs config.search_path and the server renders a full results
  // page. Here we upgrade it into a Cmd+K palette: "/" or Cmd/Ctrl+K focuses the
  // input, keystrokes fetch `<search_path>.json?q=` (debounced) and fill the
  // server-rendered dropdown, and arrow keys navigate. The native form submit is
  // always the fallback — if a fetch fails, Enter still lands on the results page.

  connectSearch() {
    if (!this.hasSearchInputTarget) return
    this.onSearchKeydown = this.handleSearchShortcut.bind(this)
    this.onSearchClickOut = this.closeOnClickOutside.bind(this)
    document.addEventListener("keydown", this.onSearchKeydown)
    document.addEventListener("click", this.onSearchClickOut)
  }

  disconnectSearch() {
    if (this.onSearchKeydown) document.removeEventListener("keydown", this.onSearchKeydown)
    if (this.onSearchClickOut) document.removeEventListener("click", this.onSearchClickOut)
    clearTimeout(this.searchTimer)
  }

  // "/" (when not already typing in a field) or Cmd/Ctrl+K focuses search.
  handleSearchShortcut(event) {
    const cmdK = (event.metaKey || event.ctrlKey) && event.key.toLowerCase() === "k"
    const slash = event.key === "/" && !this.isTypingField(event.target)
    if (!cmdK && !slash) return
    event.preventDefault()
    this.searchInputTarget.focus()
    this.searchInputTarget.select()
  }

  isTypingField(el) {
    const tag = (el?.tagName || "").toLowerCase()
    return tag === "input" || tag === "textarea" || el?.isContentEditable
  }

  // Debounced query → fetch JSON → render. An empty query just closes the palette.
  performSearch() {
    clearTimeout(this.searchTimer)
    const query = this.searchInputTarget.value.trim()
    if (!query) {
      this.closeResults()
      return
    }
    this.searchTimer = setTimeout(() => this.runSearch(query), this.searchDebounceValue)
  }

  async runSearch(query) {
    const url = `${this.searchEndpoint}?q=${encodeURIComponent(query)}`
    try {
      const response = await fetch(url, { headers: { Accept: "application/json" } })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      const data = await response.json()
      this.renderResults(data.results || [])
    } catch {
      // Fetch failed — leave the palette closed; the form still submits on Enter.
      this.closeResults()
    }
  }

  // The JSON endpoint is the form's action with a `.json` extension (same route,
  // json format), so a site that moved search_path is followed automatically.
  get searchEndpoint() {
    const action = this.searchInputTarget.form?.getAttribute("action") || "/docs/search"
    return `${action}.json`
  }

  renderResults(results) {
    const list = this.searchResultsTarget
    list.replaceChildren()
    if (results.length === 0) {
      list.appendChild(this.emptyRow())
    } else {
      results.forEach((hit) => list.appendChild(this.resultRow(hit)))
    }
    this.openResults()
    this.activeIndex = -1
  }

  emptyRow() {
    const li = document.createElement("li")
    li.className = "menu-title"
    li.textContent = "No results"
    return li
  }

  resultRow(hit) {
    const li = document.createElement("li")
    const a = document.createElement("a")
    a.href = hit.href
    const label = document.createElement("span")
    label.className = "font-medium"
    label.textContent = hit.label
    a.appendChild(label)
    // The snippet is server-produced, pre-escaped HTML (the match in <mark>); it's
    // the same trusted string the SearchResults page renders.
    if (hit.snippet) {
      const snip = document.createElement("span")
      snip.className = "block text-xs opacity-60"
      snip.innerHTML = hit.snippet
      a.appendChild(snip)
    }
    li.appendChild(a)
    return li
  }

  // Arrow/Enter/Escape navigation over the rendered result links.
  navigateResults(event) {
    const links = this.resultLinks
    if (event.key === "Escape") {
      this.closeResults()
      return
    }
    if (links.length === 0) return

    if (event.key === "ArrowDown") {
      event.preventDefault()
      this.moveActive(1, links)
    } else if (event.key === "ArrowUp") {
      event.preventDefault()
      this.moveActive(-1, links)
    } else if (event.key === "Enter" && this.activeIndex >= 0) {
      event.preventDefault()
      links[this.activeIndex].click()
    }
  }

  moveActive(delta, links) {
    this.activeIndex = (this.activeIndex + delta + links.length) % links.length
    links.forEach((link, i) => {
      const on = i === this.activeIndex
      link.classList.toggle("menu-active", on)
      if (on) link.scrollIntoView({ block: "nearest" })
    })
  }

  get resultLinks() {
    return Array.from(this.searchResultsTarget.querySelectorAll("a"))
  }

  // Let the native form submit proceed (goes to the full results page); just
  // close the palette so it doesn't linger over the new page.
  submitSearch() {
    this.closeResults()
  }

  openResults() {
    if (this.hasSearchResultsTarget) this.searchResultsTarget.classList.remove("hidden")
  }

  closeResults() {
    if (this.hasSearchResultsTarget) this.searchResultsTarget.classList.add("hidden")
    this.activeIndex = -1
  }

  closeOnClickOutside(event) {
    if (!this.hasSearchScopeTarget) return
    if (!this.searchScopeTarget.contains(event.target)) this.closeResults()
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
