# Homebrew formula for gather-cli
# To use this formula, create a tap:
#   brew tap ttscoff/thelab https://github.com/ttscoff/homebrew-thelab
# Then install:
#   brew install gather-cli

class GatherCli < Formula
  desc "Readability and Markdown utility for saving web urls and HTML text"
  homepage "https://brettterpstra.com/projects/gather-cli/"
  version "2.1.9"
  license "MIT"

  on_macos do
    url "https://github.com/ttscoff/gather-cli/releases/download/v#{version}/gather-cli-#{version}-macos-universal.tar.gz"
    sha256 "5a3d5922ebe5b5a936cd1276534c20811d184be68836526d54a9c036651df2e5"
  end

  def install
    bin.install "gather"
  end

  test do
    system "#{bin}/gather", "https://brettterpstra.com/2022/08/30/popclip-webmarkdown-fix-and-other-codesigning-adventures/"
  end
end

