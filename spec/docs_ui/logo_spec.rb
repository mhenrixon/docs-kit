# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe DocsUI::Logo do
  def logo(attrs)
    DocsKit::BrandLogo.from(attrs)
  end

  describe "the inline path forms (svg:/paths:)" do
    it "renders one <path d> per entry inside a currentColor svg" do
      html = described_class.new(logo(paths: ["M0 0Z", "M4 4Z"], label: "Acme")).call

      expect(html.scan("<path").count).to eq(2)
      expect(html).to include('d="M0 0Z"').and include('d="M4 4Z"')
      expect(html).to include('fill="currentColor"')
    end

    it "escapes the path data as an ordinary attribute (config free text stays escaped)" do
      html = described_class.new(logo(svg: %(M0 0Z" onload="alert(1)))).call

      expect(html).not_to include('onload="alert(1)"')
      expect(html).to include("&quot;")
    end

    it "carries the configured viewbox" do
      html = described_class.new(logo(svg: "M0 0Z", viewbox: "0 0 81 45")).call

      expect(html).to include('viewBox="0 0 81 45"')
    end

    it "names the mark for assistive tech (role=img + aria-label + <title>)" do
      html = described_class.new(logo(svg: "M0 0Z", label: "Acme")).call

      expect(html).to include('role="img"')
      expect(html).to include('aria-label="Acme"')
      expect(html).to include("<title>Acme</title>")
    end

    it "falls back to the label: param (the caller passes config.brand) when unlabeled" do
      html = described_class.new(logo(svg: "M0 0Z"), label: "Docs").call

      expect(html).to include('aria-label="Docs"')
    end

    it "threads class: through to the svg (per-surface sizing)" do
      html = described_class.new(logo(svg: "M0 0Z"), class: "h-6 w-auto").call

      expect(html).to include('class="h-6 w-auto"')
    end
  end

  describe "the markup: form" do
    it "embeds the site-authored <svg> verbatim inside a sized wrapper" do
      html = described_class.new(
        logo(markup: %(<svg viewBox="0 0 2 2"><path d="M0 0Z" fill="#f00"/></svg>), label: "Acme"),
        class: "h-6 w-auto"
      ).call

      expect(html).to include('<path d="M0 0Z" fill="#f00"/>')
      expect(html).to include('role="img"')
      expect(html).to include('aria-label="Acme"')
      # The wrapper carries the surface sizing; the inner svg fills it.
      expect(html).to include("h-6 w-auto")
      expect(html).to include("[&>svg]:h-full")
    end
  end

  describe "the file: form" do
    it "embeds the file's markup" do
      Dir.mktmpdir do |dir|
        path = File.join(dir, "mark.svg")
        File.write(path, %(<svg viewBox="0 0 2 2"><path d="M7 7Z"/></svg>))

        html = described_class.new(logo(file: path, label: "Acme")).call

        expect(html).to include('<path d="M7 7Z"/>')
      end
    end
  end

  describe "the image src: form" do
    it "renders an <img> with the alt naming the mark" do
      html = described_class.new(logo(src: "logo.png", alt: "Acme"), class: "h-6 w-auto").call

      expect(html).to include("<img")
      expect(html).to include('alt="Acme"')
      expect(html).to include('class="h-6 w-auto"')
    end

    it "falls back to the raw src with no view context (isolated render), like MetaTags" do
      html = described_class.new(logo(src: "logo.png", alt: "Acme")).call

      expect(html).to include('src="logo.png"')
    end
  end
end
