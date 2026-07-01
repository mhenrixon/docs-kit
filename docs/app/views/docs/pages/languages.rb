# frozen_string_literal: true

module Views
  module Docs
    module Pages
      # Demonstrates DocsUI::Example — multi-language code with a sticky, global
      # language choice — and that any Rouge language works out of the box.
      class Languages < DocsUI::Page
        title "Code languages"
        eyebrow "Reference"

        def lead = "Any language Rouge knows works. Multi-language examples remember your choice."

        def content
          multi_language_section
          any_language_section
          config_section
        end

        private

        def multi_language_section
          DocsUI::Section("Multi-language examples",
                          description: "Pick a tab — every example on the page follows.") do
            DocsUI::Prose() do
              p do
                code { "DocsUI::Example" }
                plain " renders one example in several languages with tabs. The choice is a "
                strong { "global sticky preference" }
                plain " — persisted in "
                code { "localStorage" }
                plain " and synced across every example group on the page "
                plain "and across pages. Switch Ruby → Python once and it sticks everywhere."
              end
            end

            DocsUI::Example() do |ex|
              ex.code(:ruby, filename: "client.rb") do
                <<~RUBY
                  client = Anthropic::Client.new(api_key: ENV["ANTHROPIC_API_KEY"])
                  msg = client.messages.create(
                    model: "claude-opus-4-8",
                    max_tokens: 1024,
                    messages: [{ role: "user", content: "Hello" }]
                  )
                  puts msg.content.first.text
                RUBY
              end
              ex.code(:python, filename: "client.py") do
                <<~PYTHON
                  client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
                  msg = client.messages.create(
                      model="claude-opus-4-8",
                      max_tokens=1024,
                      messages=[{"role": "user", "content": "Hello"}],
                  )
                  print(msg.content[0].text)
                PYTHON
              end
              ex.code(:javascript, filename: "client.js") do
                <<~JS
                  const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
                  const msg = await client.messages.create({
                    model: "claude-opus-4-8",
                    max_tokens: 1024,
                    messages: [{ role: "user", content: "Hello" }],
                  });
                  console.log(msg.content[0].text);
                JS
              end
            end

            DocsUI::Prose() { p { "Author it by handing each language a code block:" } }

            DocsUI::Code(<<~RUBY)
              DocsUI::Example() do |ex|
                ex.code(:ruby, filename: "client.rb")   { ruby_source }
                ex.code(:python, filename: "client.py") { python_source }
                ex.code(:javascript)                    { js_source }
              end
            RUBY
          end
        end

        def any_language_section
          DocsUI::Section("Any language", description: "No allowlist — Rouge's full registry (~200 lexers).") do
            DocsUI::Code(<<~GO, lexer: :go, filename: "main.go")
              package main

              import "fmt"

              func main() { fmt.Println("go works") }
            GO
            DocsUI::Code(<<~RUST, lexer: :rust, filename: "main.rs")
              fn main() {
                  println!("rust works");
              }
            RUST
            DocsUI::Code(<<~ELIXIR, lexer: :elixir, filename: "demo.ex")
              defmodule Demo do
                def hello, do: IO.puts("elixir works")
              end
            ELIXIR
          end
        end

        def config_section
          DocsUI::Section("Configuring languages") do
            DocsUI::Prose() do
              p do
                plain "Pass any Rouge lexer name to "
                code { "lexer:" }
                plain " directly. Register "
                strong { "aliases" }
                plain " to map a custom name onto a real lexer, and "
                strong { "labels" }
                plain " to control the tab caption an example shows:"
              end
            end

            DocsUI::Code(<<~RUBY, filename: "config/initializers/docs_kit.rb")
              DocsKit.configure do |c|
                c.code_lexer_aliases   = { curl: "console" }
                c.code_language_labels = { elixir: "Elixir" }
              end
            RUBY

            DocsUI::Prose() do
              p do
                plain "Now "
                code { "DocsUI::Code(src, lexer: :curl)" }
                plain " highlights with the "
                code { "console" }
                plain " lexer. An unknown lexer falls back to "
                code { "code_lexer_fallback" }
                plain " (plaintext) instead of raising."
              end
            end

            render PropTable.new(
              [ "Option", "Purpose" ],
              [
                [ "code_lexer_aliases",
                 "Map friendly names onto real Rouge lexers, e.g. { curl: \"console\" }. Merged over the built-in aliases." ],
                [ "code_lexer_fallback",
                 "Lexer used when a requested name is unknown. Defaults to \"plaintext\" — no highlighting, no error." ],
                [ "code_language_labels",
                 "Override the tab caption per language in DocsUI::Example, e.g. { elixir: \"Elixir\" }." ]
              ]
            )

            DocsUI::Callout(:tip) do
              "Aliases and labels are optional — every Rouge lexer already works by name. Reach for these only to " \
                "rename a lexer (curl → console) or polish a tab caption."
            end
          end
        end
      end
    end
  end
end
