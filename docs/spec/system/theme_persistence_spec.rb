# frozen_string_literal: true

require "system_helper"

# The theme choice is a global sticky preference (the one docs-nav Stimulus
# controller + localStorage). Picking a theme applies it immediately and survives
# navigation with no flash of the server default — the anti-flash <head> script
# restores it before first paint.
RSpec.describe "Theme persistence", type: :system do
  it "applies a chosen theme immediately and keeps it across navigation" do
    visit "/docs/overview"
    expect(page).to have_css("html[data-theme]", visible: :all)

    open_theme_menu
    find("[data-testid='theme-synthwave']", visible: :all).click

    # Applied in place (daisyUI's theme-controller flips data-theme on <html>).
    expect(page).to have_css("html[data-theme='synthwave']", visible: :all)

    # Persisted: a fresh navigation keeps synthwave (no revert to the default,
    # no flash — the <head> restore script re-applies it before first paint).
    visit "/docs/installation"
    expect(page).to have_css("html[data-theme='synthwave']", visible: :all)
  end

  private

  def open_theme_menu
    find("div[role='button']", text: "Theme").click
  end
end
