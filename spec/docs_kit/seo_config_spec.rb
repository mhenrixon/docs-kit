# frozen_string_literal: true

RSpec.describe DocsKit::SeoConfig do
  subject(:seo) { described_class.new }

  describe "defaults (a site that sets nothing is backwards-safe)" do
    it "defaults #description to nil (no meta-description tag site-wide)" do
      expect(seo.description).to be_nil
    end

    it "defaults #og_image to the shipped default path" do
      expect(seo.og_image).to eq("og/og.png")
    end

    it "defaults #og_type to \"website\"" do
      expect(seo.og_type).to eq("website")
    end

    it "defaults #twitter_card to \"summary_large_image\" (a proper banner card)" do
      expect(seo.twitter_card).to eq("summary_large_image")
    end

    it "defaults #twitter_site and #twitter_creator to nil (handles are opt-in)" do
      expect(seo.twitter_site).to be_nil
      expect(seo.twitter_creator).to be_nil
    end

    it "defaults #locale to \"en_US\"" do
      expect(seo.locale).to eq("en_US")
    end

    it "defaults #site_url to nil (canonical/og:image absolutization needs the request otherwise)" do
      expect(seo.site_url).to be_nil
    end

    it "defaults #robots, #favicon, #theme_color to nil" do
      expect(seo.robots).to be_nil
      expect(seo.favicon).to be_nil
      expect(seo.theme_color).to be_nil
    end
  end

  describe "assignment (every field round-trips)" do
    # One accessor per field: assign, read back. Table-driven so each knob is
    # covered without a single 11-expectation example.
    {
      description: "One-line summary.",
      og_image: "og/custom.png",
      og_type: "article",
      twitter_card: "summary",
      twitter_site: "@docs",
      twitter_creator: "@author",
      locale: "sv_SE",
      site_url: "https://docs.example.com",
      robots: "noindex, nofollow",
      favicon: "favicon.ico",
      theme_color: "#0f172a"
    }.each do |field, value|
      it "round-trips ##{field}" do
        seo.public_send("#{field}=", value)

        expect(seo.public_send(field)).to eq(value)
      end
    end
  end
end
