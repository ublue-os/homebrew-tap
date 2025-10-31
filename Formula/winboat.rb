class Winboat < Formula
  desc "Run Windows apps on Linux with seamless integration"
  homepage "https://www.winboat.app"
  url "https://github.com/TibixDev/winboat/releases/download/v0.8.7/winboat-0.8.7-x64.tar.gz"
  sha256 "e0d57d9f214b609b7db73de29034dbd684a924600aaf5238f43d151eaa6dcb72"
  license "MIT"

  livecheck do
    url :stable
    strategy :github_latest
  end

  depends_on :linux

  def install
    bin.install "winboat"
  end

  test do
    assert_match "winboat", shell_output("#{bin}/winboat --help")
  end
end
