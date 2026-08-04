# frozen_string_literal: true

require "tmpdir"
require "fileutils"

RSpec.describe DocsKit::BrandLogo do
  describe ".from" do
    it "returns an already-built instance unchanged" do
      logo = described_class.from(paths: ["M0 0Z"])

      expect(described_class.from(logo)).to be(logo)
    end

    it "normalizes the single-path svg: form (the landing.logo shape)" do
      logo = described_class.from(svg: "M1 1H2Z", viewbox: "0 0 10 10", label: "Acme")

      expect(logo).to be_inline
      expect(logo.paths).to eq(["M1 1H2Z"])
      expect(logo.svg).to eq("M1 1H2Z")
      expect(logo.viewbox).to eq("0 0 10 10")
      expect(logo.label).to eq("Acme")
    end

    it "normalizes the multi-path paths: form" do
      logo = described_class.from(paths: ["M0 0Z", "M1 1Z"], label: "Acme")

      expect(logo).to be_inline
      expect(logo.paths).to eq(["M0 0Z", "M1 1Z"])
    end

    it "defaults the viewbox to a 24×24 box" do
      expect(described_class.from(svg: "M0 0Z").viewbox).to eq("0 0 24 24")
    end

    it "accepts string keys" do
      expect(described_class.from("svg" => "M0 0Z").paths).to eq(["M0 0Z"])
    end

    it "normalizes the raw markup: form" do
      logo = described_class.from(markup: %(<svg viewBox="0 0 2 2"><path d="M0 0Z"/></svg>))

      expect(logo).to be_markup
      expect(logo.svg_markup).to include('<path d="M0 0Z"/>')
    end

    it "rejects markup that is not an <svg> element" do
      expect { described_class.from(markup: "<script>alert(1)</script>") }
        .to raise_error(ArgumentError, /brand_logo/)
    end

    it "normalizes the image src: form" do
      logo = described_class.from(src: "logo.png", alt: "Acme")

      expect(logo).to be_image
      expect(logo.src).to eq("logo.png")
      expect(logo.alt).to eq("Acme")
    end

    it "raises when no logo form is given" do
      expect { described_class.from(label: "Acme") }.to raise_error(ArgumentError, /brand_logo/)
    end

    it "raises when several forms are mixed (ambiguous config)" do
      expect { described_class.from(svg: "M0 0Z", src: "logo.png") }
        .to raise_error(ArgumentError, /exactly one/)
    end
  end

  describe "the accessible name" do
    it "falls back label → alt and alt → label, so either knob names the mark" do
      expect(described_class.from(src: "logo.png", alt: "Acme").label).to eq("Acme")
      expect(described_class.from(markup: "<svg></svg>", label: "Acme").alt).to eq("Acme")
    end

    it "is nil when neither is set (the render-time config.brand fallback applies)" do
      expect(described_class.from(svg: "M0 0Z").label).to be_nil
    end
  end

  describe "the file: form" do
    let(:dir) { Dir.mktmpdir }

    after { FileUtils.remove_entry(dir) }

    def write_mark(content, name: "mark.svg")
      File.join(dir, name).tap { |path| File.write(path, content) }
    end

    it "embeds the file's markup" do
      path = write_mark(%(<svg viewBox="0 0 2 2"><path d="M0 0Z"/></svg>))
      logo = described_class.from(file: path, label: "Acme")

      expect(logo).to be_file
      expect(logo.svg_markup).to include('<path d="M0 0Z"/>')
    end

    it "raises on a missing file" do
      expect { described_class.from(file: File.join(dir, "nope.svg")) }
        .to raise_error(ArgumentError, /brand_logo/)
    end

    it "raises on a non-.svg extension (only inline-embeddable SVG is supported)" do
      path = write_mark("<svg></svg>", name: "mark.png")

      expect { described_class.from(file: path) }.to raise_error(ArgumentError, /\.svg/)
    end

    it "raises when the file content is not an <svg> element" do
      path = write_mark("<script>alert(1)</script>")

      expect { described_class.from(file: path) }.to raise_error(ArgumentError, /brand_logo/)
    end

    it "memoizes the content while the file's mtime is unchanged" do
      path = write_mark("<svg><path d=\"old\"/></svg>")
      logo = described_class.from(file: path)
      logo.svg_markup

      mtime = File.mtime(path)
      File.write(path, "<svg><path d=\"new\"/></svg>")
      File.utime(File.atime(path), mtime, path)

      expect(logo.svg_markup).to include("old")
    end

    it "re-reads the content when the file's mtime changes (dev edit, no restart)" do
      path = write_mark("<svg><path d=\"old\"/></svg>")
      logo = described_class.from(file: path)
      logo.svg_markup

      File.write(path, "<svg><path d=\"new\"/></svg>")
      File.utime(Time.now + 5, Time.now + 5, path)

      expect(logo.svg_markup).to include("new")
    end
  end
end
