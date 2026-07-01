# frozen_string_literal: true

module DocsUI
  # A multi-language code group: the same example shown in several languages, with
  # tabs to switch. The chosen language is a GLOBAL sticky preference (localStorage
  # via the docs-nav controller) — pick Ruby once and every code group on this and
  # future pages shows Ruby, falling back to an available language when a group
  # doesn't have the chosen one.
  #
  #   render DocsUI::Example.new do |ex|
  #     ex.code(:ruby, filename: "client.rb") do
  #       <<~RUBY
  #         Anthropic.messages.create(model: "claude-opus-4-8", ...)
  #       RUBY
  #     end
  #     ex.code(:python, filename: "client.py") do
  #       <<~PY
  #         client.messages.create(model="claude-opus-4-8", ...)
  #       PY
  #     end
  #   end
  #
  # With one snippet it degrades to a plain DocsUI::Code (no tabs). With JS off the
  # first language shows and the rest are visible below it (progressive
  # enhancement — no content is hidden without JS).
  class Example < Phlex::HTML
    def initialize
      @snippets = []
    end

    # Collect one language's snippet. `lang` is the language token (e.g. :ruby,
    # :python, :go) — Docs::Code resolves it against Rouge's full registry + the
    # configured aliases, so any language works. The tab label comes from the
    # configured language_labels (else the token capitalized). filename/lexer are
    # optional; lexer defaults to the language token. The block returns the source.
    def code(lang, filename: nil, lexer: nil)
      token = lang.to_sym
      @snippets << {
        lang: token,
        label: DocsKit.configuration.language_labels.fetch(token, token.to_s.capitalize),
        filename: filename,
        lexer: lexer || token,
        source: yield.to_s
      }
      nil
    end

    def view_template
      yield self if block_given?
      return if @snippets.empty?
      return render_single if @snippets.one?

      div(
        class: "not-prose my-4",
        data: { docs_nav_target: "codeGroup" }
      ) do
        language_tabs
        snippet_panels
      end
    end

    private

    def render_single
      snippet = @snippets.first
      render DocsUI::Code.new(snippet[:source], lexer: snippet[:lexer], filename: snippet[:filename])
    end

    def language_tabs
      div(role: "tablist", class: "tabs tabs-box w-fit mb-2") do
        @snippets.each do |snippet|
          button(
            role: "tab",
            class: "tab",
            data: {
              docs_nav_target: "codeTab",
              docs_nav_lang_param: snippet[:lang],
              action: "docs-nav#selectLanguage",
              testid: "code-lang-#{snippet[:lang]}"
            }
          ) { snippet[:label] }
        end
      end
    end

    def snippet_panels
      @snippets.each do |snippet|
        div(
          data: {
            docs_nav_target: "codePanel",
            docs_nav_lang_param: snippet[:lang],
            lang: snippet[:lang]
          }
        ) do
          render DocsUI::Code.new(snippet[:source], lexer: snippet[:lexer], filename: snippet[:filename])
        end
      end
    end
  end
end
