# frozen_string_literal: true

# Guard spec for the OG image docs-kit ships. DocsKit.configuration.seo.og_image
# defaults to "og/og.png", so a consuming site's og:image points at this file
# until it regenerates its own with `bin/rails docs_kit:og`. If the default is
# deleted or corrupted, every fresh site would emit a broken og:image — so this
# fails loudly with the regeneration hint, mirroring phlex-reactive's
# vendored-client guard spec. It only stats the file (no browser), keeping the
# gem's own CI dependency-free.
# The subject is a shipped asset file, not a class — describe it by name.
RSpec.describe "the shipped default OG image" do # rubocop:disable RSpec/DescribeClass
  let(:path) { File.expand_path("../../app/assets/images/og/og.png", __dir__) }

  it "exists at app/assets/images/og/og.png" do
    expect(File.exist?(path)).to be(true),
                                 "Missing #{path}. Regenerate a site's own with `bin/rails docs_kit:og`, " \
                                 "or restore the shipped default (a 1200x630 PNG)."
  end

  it "is a non-empty PNG (valid magic bytes)" do
    expect(File.size(path)).to be > 0
    expect(File.binread(path, 8)).to eq("\x89PNG\r\n\x1A\n".b)
  end
end
