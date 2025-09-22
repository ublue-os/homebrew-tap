cask "bluefin-wallpapers-plasma-dynamic" do
  version :latest
  sha256 :no_check

  url "https://github.com/renner0e/bluefin-wallpapers-plasma/releases/latest/download/wallpapers.tar.gz"
  name "bluefin-wallpapers-plasma-dynamic"
  desc "Bluefin Wallpapers for KDE"
  homepage "https://github.com/renner0e/bluefin-wallpapers-plasma"

  livecheck do
    url "https://github.com/ublue-os/packages/bluefin-wallpapers-plasma"
    strategy :github_latest
  end

  artifact staged_path, target: "#{Dir.home}/.local/share/wallpapers/bluefin-plasma-dynamic"
end
