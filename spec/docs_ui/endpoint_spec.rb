# frozen_string_literal: true

RSpec.describe DocsUI::Endpoint do
  def render_endpoint(...)
    described_class.new(...).call
  end

  it "renders the HTTP method as a daisyUI badge" do
    html = render_endpoint(:post, "/v1/messages")

    expect(html).to include("badge")
    expect(html).to include("badge-sm")
    expect(html).to include("POST")
  end

  it "renders the path in a monospace <code>" do
    html = render_endpoint(:post, "/v1/messages")

    expect(html).to include("<code")
    expect(html).to include("/v1/messages")
  end

  it "upcases a lowercase method symbol for the badge label" do
    html = render_endpoint(:get, "/v1/messages")

    expect(html).to include(">GET<")
  end

  it "maps GET to badge-success" do
    expect(render_endpoint(:get, "/x")).to include("badge-success")
  end

  it "maps POST to badge-primary" do
    expect(render_endpoint(:post, "/x")).to include("badge-primary")
  end

  it "maps PATCH to badge-warning" do
    expect(render_endpoint(:patch, "/x")).to include("badge-warning")
  end

  it "maps PUT to badge-warning" do
    expect(render_endpoint(:put, "/x")).to include("badge-warning")
  end

  it "maps DELETE to badge-error" do
    expect(render_endpoint(:delete, "/x")).to include("badge-error")
  end

  it "accepts a String method (not only a Symbol)" do
    html = render_endpoint("POST", "/x")

    expect(html).to include("badge-primary")
    expect(html).to include(">POST<")
  end

  it "falls back to a neutral badge for an unknown verb, without raising" do
    html = nil
    expect { html = render_endpoint(:trace, "/x") }.not_to raise_error

    expect(html).to include("badge-neutral")
    expect(html).to include(">TRACE<")
    # No colored verb class leaks in for an unknown method.
    expect(html).not_to include("badge-success")
    expect(html).not_to include("badge-primary")
  end

  it "renders inline (no block wrapper) so it composes in a Section description" do
    html = render_endpoint(:get, "/x")

    # The badge sits directly next to the path — no surrounding <div>/<p> block.
    expect(html).not_to include("<div")
    expect(html).not_to include("<p>")
  end

  it "escapes HTML in the path (Phlex escaping, no html_safe)" do
    html = render_endpoint(:get, "/x?<script>")

    expect(html).to include("&lt;script&gt;")
    expect(html).not_to include("<script>")
  end
end
