cask "winboat-linux" do
  arch arm: "arm64", intel: "x64"
  os linux: "linux"
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

  binary "winboat-#{version}-x64/winboat"

  preflight do
    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    
    desktop_file = <<~EOS
      [Desktop Entry]
      Name=Winboat
      Comment=Run Windows apps on Linux with seamless integration
      Exec=#{HOMEBREW_PREFIX}/bin/winboat %U
      Terminal=false
      Type=Application
      Icon=winboat
      Categories=Utility;
    EOS

    File.write("#{Dir.home}/.local/share/applications/winboat.desktop", desktop_file)
  end

  zap trash: [
    "~/.config/winboat",
    "~/.local/share/winboat",
    "~/.local/share/applications/winboat.desktop",
  ]
end
