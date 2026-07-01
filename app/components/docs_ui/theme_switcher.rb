# frozen_string_literal: true

module DocsUI
  # daisyUI theme switcher — a dropdown of radio inputs with the `theme-controller`
  # class. daisyUI swaps the page theme (data-theme on :root) with ZERO JavaScript
  # via a CSS :has() selector, so this fits a no-custom-JS docs site.
  #
  # The offered themes come from DocsKit.configuration.themes and MUST match the
  # themes enabled in the site's Tailwind @plugin "daisyui" { themes: ... } block.
  class ThemeSwitcher < Phlex::HTML
    def view_template
      div(class: "dropdown dropdown-end") do
        div(tabindex: "0", role: "button", class: "btn btn-sm btn-ghost gap-1") do
          render DocsUI::Icon.new("palette", class: "size-4")
          plain "Theme"
        end
        ul(tabindex: "0",
           class: "dropdown-content bg-base-300 rounded-box z-10 w-44 p-2 shadow-2xl max-h-96 overflow-y-auto") do
          themes.each { |theme| theme_option(theme) }
        end
      end
    end

    private

    def themes
      DocsKit.configuration.themes
    end

    def theme_option(theme)
      li do
        input(
          type: "radio",
          name: "theme-dropdown",
          value: theme,
          class: "theme-controller btn btn-sm btn-block btn-ghost justify-start",
          aria_label: theme.capitalize,
          data: { testid: "theme-#{theme}" }
        )
      end
    end
  end
end
