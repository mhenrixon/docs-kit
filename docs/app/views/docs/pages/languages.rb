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
                          description: "Pick a tab — every example on the page (and the next) follows.") do
            DocsUI::Prose() do
              p do
                code { "DocsUI::Example" }
                plain " renders one example in several languages with tabs. The choice is a global "
                plain "sticky preference (localStorage) — switch once, get it everywhere."
              end
            end

            DocsUI::Example() do |ex|
              ex.code(:ruby, filename: "client.rb") do
                %(Anthropic::Client.new.messages.create(model: "claude-opus-4-8", messages: msgs))
              end
              ex.code(:python, filename: "client.py") do
                %(anthropic.Anthropic().messages.create(model="claude-opus-4-8", messages=msgs))
              end
              ex.code(:javascript, filename: "client.js") do
                %(await new Anthropic().messages.create({ model: "claude-opus-4-8", messages }))
              end
            end

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
              func main() { fmt.Println("go works") }
            GO
            DocsUI::Code(<<~RUST, lexer: :rust, filename: "main.rs")
              fn main() { println!("rust works"); }
            RUST
            DocsUI::Code(<<~ELIXIR, lexer: :elixir)
              defmodule Demo, do: def hello, do: :world
            ELIXIR
          end
        end

        def config_section
          DocsUI::Section("Configuring languages") do
            DocsUI::Prose() { p { "Add friendly aliases or labels if you use custom names:" } }
            DocsUI::Code(<<~RUBY)
              DocsKit.configure do |c|
                c.code_lexer_aliases   = { curl: "console" }
                c.code_language_labels = { elixir: "Elixir" }
              end
            RUBY
          end
        end
      end
    end
  end
end
