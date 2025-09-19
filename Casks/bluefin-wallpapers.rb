cask "bluefin-wallpapers" do
  version :latest
  sha256 :no_check

  url "https://github.com/ublue-os/packages/archive/refs/heads/main.tar.gz"
  name "bluefin-wallpapers"
  desc "Wallpapers for Bluefin"
  homepage "https://github.com/ublue-os/packages/tree/main/packages/bluefin/wallpapers"

  livecheck do
    url "https://github.com/ublue-os/packages"
    strategy :git
  end

  Dir.glob("#{staged_path}/packages-main/packages/bluefin/wallpapers/images/*").each do |file|
    artifact file, target: "#{Dir.home}/.local/share/backgrounds/#{File.basename(file)}"
  end
end
