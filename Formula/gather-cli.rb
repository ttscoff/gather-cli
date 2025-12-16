# Homebrew formula for gather-cli
# To use this formula, create a tap:
#   brew tap ttscoff/thelab https://github.com/ttscoff/homebrew-thelab
# Then install:
#   brew install gather-cli

class GatherCli < Formula
  desc "Readability and Markdown utility for saving web urls and HTML text"
  homepage "https://brettterpstra.com/projects/gather-cli/"
  version "2.1.10"
  license "MIT"

  on_macos do
    url "https://github.com/ttscoff/gather-cli/releases/download/v#{version}/gather-cli-#{version}-macos-universal.tar.gz"
    sha256 "55fe5e2243bfb0166a04f8e3234c02d012e510fe7776e7fc770231cee2884119"
  end

  def install
    bin.install "gather"
  end

  test do
    system "#{bin}/gather", "https://brettterpstra.com/2022/08/30/popclip-webmarkdown-fix-and-other-codesigning-adventures/"
  end
end

