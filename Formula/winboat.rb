class Winboat < Formula
  desc "Run Windows apps on Linux with seamless integration"
  homepage "https://www.winboat.app"
  url "https://github.com/TibixDev/winboat/releases/download/v0.8.7/winboat-0.8.7.tar.gz"
  sha256 "bf74ba69a303235d671a61b881dc42c9ce0dc99bcbcaab6713f43eb160984014"
  license "MIT"

  depends_on :linux

  livecheck do
    url :stable
    strategy :github_latest
  end

  def install
    bin.install "winboat"
  end

  test do
    assert_match "winboat", shell_output("#{bin}/winboat --help")
  end
end
