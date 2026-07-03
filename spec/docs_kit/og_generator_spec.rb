# frozen_string_literal: true

require "docs_kit/og_generator"

# DocsKit::OgGenerator screenshots a URL into OG images. It is loaded only by the
# host-installed docs_kit:og rake task (never at gem runtime), so it's required
# explicitly here. These specs cover the pure logic — shooter resolution and the
# per-tool command it builds — WITHOUT launching a browser or booting a server.
RSpec.describe DocsKit::OgGenerator do
  let(:out_dir) { "/tmp/og-test" }
  let(:sizes) { { "og.png" => [1200, 630], "twitter.png" => [1024, 512] } }

  describe "shooter resolution" do
    it "honors an explicit shooter override" do
      gen = described_class.new(url: "http://x", out_dir:, sizes:, shooter: "shot-scraper")

      expect(gen.shooter_name).to eq("shot-scraper")
    end

    it "raises a helpful error when no shooter is available" do
      gen = described_class.new(url: "http://x", out_dir:, sizes:, shooter: nil)
      allow(gen).to receive(:which).and_return(nil) # nothing on PATH

      expect do
        gen.resolve_shooter!
      end.to raise_error(DocsKit::OgGenerator::NoShooterError, /shot-scraper|chromium|chrome/)
    end

    it "auto-detects shot-scraper when present on PATH" do
      gen = described_class.new(url: "http://x", out_dir:, sizes:, shooter: nil)
      allow(gen).to receive(:which) { |cmd| cmd == "shot-scraper" ? "/usr/bin/shot-scraper" : nil }

      expect(gen.resolve_shooter!).to eq("shot-scraper")
    end

    it "falls back to a chromium binary when shot-scraper is absent" do
      gen = described_class.new(url: "http://x", out_dir:, sizes:, shooter: nil)
      allow(gen).to receive(:which) { |cmd| cmd == "chromium" ? "/usr/bin/chromium" : nil }

      expect(gen.resolve_shooter!).to eq("chromium")
    end
  end

  describe "command building" do
    it "builds a shot-scraper command with the URL, size, and output path" do
      gen = described_class.new(url: "http://localhost:3210", out_dir:, sizes:, shooter: "shot-scraper")
      cmd = gen.command_for("shot-scraper", "http://localhost:3210", [1200, 630], "#{out_dir}/og.png")

      expect(cmd).to include("shot-scraper")
      expect(cmd).to include("http://localhost:3210")
      expect(cmd).to include("1200")
      expect(cmd).to include("630")
      expect(cmd).to include("#{out_dir}/og.png")
    end

    it "builds a headless-chromium command with --screenshot, --window-size, and the URL" do
      gen = described_class.new(url: "http://localhost:3210", out_dir:, sizes:, shooter: "chromium")
      cmd = gen.command_for("chromium", "http://localhost:3210", [1024, 512], "#{out_dir}/twitter.png")

      expect(cmd).to include("chromium")
      expect(cmd.join(" ")).to include("--headless")
      expect(cmd.join(" ")).to include("--screenshot=#{out_dir}/twitter.png")
      expect(cmd.join(" ")).to include("--window-size=1024,512")
      expect(cmd).to include("http://localhost:3210")
    end
  end
end
