# frozen_string_literal: true

require "docs_kit/rubocop"
require_relative "../../cop_spec_helper"

# The cop is proven in the consuming sites; these specs pin its contract so the
# gem copy never regresses. It enforces the Phlex-kit helper form
# (`DocsUI::Code(...)`) over `render DocsUI::Code.new(...)` for the DocsUI and
# DaisyUI kit modules, keeping the namespace prefix so the rewrite is safe in
# every rendering context.
RSpec.describe RuboCop::Cop::DocsKit::RenderComponentPreferred do
  include_context "with cop spec support"

  context "with a plain `render Kit::Class.new(...)`" do
    it "registers an offense and autocorrects to the kit helper form" do
      expect_offense(<<~RUBY)
        render DocsUI::Code.new(source, filename: "a.rb")
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `DocsUI::Code(source, filename: "a.rb")` instead of `render DocsUI::Code.new(source, filename: "a.rb")`.
      RUBY

      expect_correction(<<~RUBY)
        DocsUI::Code(source, filename: "a.rb")
      RUBY
    end
  end

  context "with a no-argument component" do
    it "keeps the empty-parens helper form" do
      expect_offense(<<~RUBY)
        render DocsUI::OnThisPage.new
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `DocsUI::OnThisPage()` instead of `render DocsUI::OnThisPage.new`.
      RUBY

      expect_correction(<<~RUBY)
        DocsUI::OnThisPage()
      RUBY
    end
  end

  context "with a brace block glued onto .new" do
    it "moves the block onto the helper call" do
      expect_offense(<<~RUBY)
        render DocsUI::Section.new("Title") { text "body" }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `DocsUI::Section("Title")` instead of `render DocsUI::Section.new("Title")`.
      RUBY

      expect_correction(<<~RUBY)
        DocsUI::Section("Title") { text "body" }
      RUBY
    end
  end

  context "with a do...end block on the render call" do
    it "moves the block onto the helper call" do
      expect_offense(<<~RUBY)
        render DocsUI::Section.new("Title") do
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `DocsUI::Section("Title")` instead of `render DocsUI::Section.new("Title")`.
          text "body"
        end
      RUBY

      expect_correction(<<~RUBY)
        DocsUI::Section("Title") do
          text "body"
        end
      RUBY
    end
  end

  context "with a kit render nested inside another kit render's block" do
    # A very common Phlex idiom. Both offend; the outer correction must replace
    # only its own send (not the whole block, which spans the inner render), or
    # the two rewrites overlap and RuboCop raises a clobbering error.
    it "corrects both without overlapping rewrites" do
      expect_offense(<<~RUBY)
        render DocsUI::Section.new("Title") do
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `DocsUI::Section("Title")` instead of `render DocsUI::Section.new("Title")`.
          render DocsUI::Code.new(source)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `DocsUI::Code(source)` instead of `render DocsUI::Code.new(source)`.
        end
      RUBY

      expect_correction(<<~RUBY)
        DocsUI::Section("Title") do
          DocsUI::Code(source)
        end
      RUBY
    end
  end

  context "with the DaisyUI kit module" do
    it "also fires (DaisyUI is a recognised kit)" do
      expect_offense(<<~RUBY)
        render DaisyUI::Button.new(:primary) { "Save" }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `DaisyUI::Button(:primary)` instead of `render DaisyUI::Button.new(:primary)`.
      RUBY

      expect_correction(<<~RUBY)
        DaisyUI::Button(:primary) { "Save" }
      RUBY
    end
  end

  context "when the render target is not a recognised kit" do
    it "does not fire for a plain component" do
      expect_no_offenses(<<~RUBY)
        render SomeComponent.new(:x)
      RUBY
    end

    it "does not fire for an unqualified kit-looking constant" do
      # The cop requires the two-segment namespaced form (Kit::Class); a bare
      # constant may resolve to a different kit depending on inclusion order.
      expect_no_offenses(<<~RUBY)
        render Code.new(source)
      RUBY
    end
  end

  context "when the render argument is not a .new call" do
    it "ignores a class-method call like `render UI::Modal.clear`" do
      expect_no_offenses(<<~RUBY)
        render DocsUI::Modal.clear
      RUBY
    end
  end

  context "when the .new call is an element of an array literal" do
    it "ignores it (turbo_stream: [...] payloads are class-method calls, not instances)" do
      expect_no_offenses(<<~RUBY)
        render turbo_stream: [DocsUI::Code.new(source)]
      RUBY
    end
  end

  context "when render is given more than one argument" do
    it "does not fire (a single component instance is required)" do
      expect_no_offenses(<<~RUBY)
        render DocsUI::Code.new(source), layout: false
      RUBY
    end
  end
end
