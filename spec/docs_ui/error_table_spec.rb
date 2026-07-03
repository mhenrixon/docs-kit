# frozen_string_literal: true

RSpec.describe DocsUI::ErrorTable do
  def render_error_table(...)
    described_class.new(...).call
  end

  let(:errors_with_param) do
    [
      { scenario: "Missing or invalid API key", status: "401", type: "authentication_error" },
      { scenario: "Non-HTTPS URL", status: "422", type: "validation_error", param: "url" }
    ]
  end

  let(:errors_without_param) do
    [
      { scenario: "Missing or invalid API key", status: "401", type: "authentication_error" },
      { scenario: "Endpoint not found", status: "404", type: "not_found_error" }
    ]
  end

  it "uses Scenario / Status / Type headers" do
    html = render_error_table(errors_without_param)

    expect(html).to include(">Scenario")
    expect(html).to include(">Status")
    expect(html).to include(">Type")
  end

  it "renders the scenario and status as plain cells" do
    html = render_error_table(errors_without_param)

    expect(html).to include("Missing or invalid API key")
    expect(html).to include("401")
  end

  it "renders the error type in inline <code>" do
    html = render_error_table(errors_without_param)

    expect(html).to include(">authentication_error</code>")
  end

  context "when at least one row has a param" do
    it "shows the Param column" do
      html = render_error_table(errors_with_param)

      expect(html).to include(">Param")
    end

    it "renders a present param in inline <code>" do
      html = render_error_table(errors_with_param)

      expect(html).to include(">url</code>")
    end

    it "fills the canonical em-dash placeholder for a row with no param" do
      html = render_error_table(errors_with_param)

      expect(html).to include("—")
    end
  end

  context "when a param is a blank string" do
    it "treats it as absent — no Param column when every param is blank" do
      html = render_error_table([{ scenario: "x", status: "422", type: "validation_error", param: "" }])

      expect(html).not_to include(">Param")
    end

    it "fills the em-dash placeholder for a blank param when the column is shown" do
      html = render_error_table(
        [
          { scenario: "Non-HTTPS URL", status: "422", type: "validation_error", param: "url" },
          { scenario: "Blank param", status: "422", type: "validation_error", param: "" }
        ]
      )

      expect(html).to include("—")
      expect(html).not_to include(%(<code class="text-sm"></code>))
    end
  end

  context "when no row has a param" do
    it "hides the Param column entirely" do
      html = render_error_table(errors_without_param)

      expect(html).not_to include(">Param")
    end

    it "renders exactly three columns (no trailing param cell)" do
      html = render_error_table(errors_without_param)

      # Two data rows, three columns each → six <td>. A stray param column
      # would push this to eight.
      expect(html.scan("<td").length).to eq(6)
    end
  end

  it "reuses DocsUI::Table's wrapper (composition, not duplicated markup)" do
    html = render_error_table(errors_without_param)

    expect(html).to include("not-prose")
    expect(html).to include("rounded-box")
    expect(html).to include("table table-sm table-zebra")
  end

  it "renders headers only for an empty errors array" do
    html = render_error_table([])

    expect(html).to include(">Scenario")
    expect(html).not_to include("<td")
  end

  it "escapes HTML in a plain-string scenario" do
    html = render_error_table([{ scenario: "bad <title>", status: "422", type: "validation_error" }])

    expect(html).to include("&lt;title&gt;")
    expect(html).not_to include("<title>")
  end

  context "when a row omits the type (OpenAPI has no canonical error-type field)" do
    it "fills the canonical em-dash placeholder instead of code-styling an empty type" do
      html = render_error_table([{ scenario: "Not found", status: "404" }])

      expect(html).to include("—")
      # No empty <code> cell for the missing type.
      expect(html).not_to include(%(<code class="text-sm"></code>))
    end

    it "still renders a present type in inline <code> alongside a type-less row" do
      html = render_error_table(
        [
          { scenario: "Bad key", status: "401", type: "authentication_error" },
          { scenario: "Not found", status: "404" }
        ]
      )

      expect(html).to include(">authentication_error</code>")
      expect(html).to include("—") # the type-less row's placeholder
    end
  end
end
