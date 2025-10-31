cask "winboat-linux" do
  version "0.8.7"
  sha256 "e0d57d9f214b609b7db73de29034dbd684a924600aaf5238f43d151eaa6dcb72"

  url "https://github.com/TibixDev/winboat/releases/download/v#{version}/winboat-#{version}-x64.tar.gz"
  name "Winboat"
  desc "Run Windows apps on Linux with seamless integration"
  homepage "https://www.winboat.app"

  livecheck do
    url :url
    strategy :github_latest
  end

  app "winboat-#{version}-x64/winboat"

  zap trash: [
    "~/.config/winboat",
    "~/.local/share/winboat",
  ]
end
