cask "aurora-wallpapers" do
  version :latest
  sha256 :no_check

  url "https://github.com/ublue-os/packages/archive/refs/heads/main.tar.gz"
  name "aurora-wallpapers"
  desc "Wallpapers for Aurora"
  homepage "https://github.com/ublue-os/packages/tree/main/packages/aurora/wallpapers"

  livecheck do
    url "https://github.com/ublue-os/packages"
    strategy :git
  end

  Dir.glob("#{staged_path}/packages-main/packages/aurora/wallpapers/images/aurora-wallpaper-*").each do |dir|
    next if File.basename(dir) == "aurora-wallpaper-1"

    artifact dir, target: "#{Dir.home}/.local/share/backgrounds/aurora/#{File.basename(dir)}"
  end
end
