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
    artifact file, target: "#{Dir.home}/.local/share/backgrounds/bluefin/#{File.basename(file)}"
  end

  Dir.glob("#{staged_path}/packages-main/packages/bluefin/wallpapers/gnome-background-properties/*").each do |file|
    artifact file, target: "#{Dir.home}/.local/share/gnome-background-properties/#{File.basename(file)}"
  end

  preflight do
    subpath = "#{staged_path}/packages-main/packages/bluefin/wallpapers"
    Dir.glob("#{subpath}/images/*.xml").each do |file|
      # Use Ruby standard library for in-place editing
      content = File.read(file)
      content.gsub!("/usr/share/backgrounds/", "#{Dir.home}/.local/share/backgrounds/")
      File.write(file, content)
    end
    Dir.glob("#{subpath}/gnome-background-properties/*.xml").each do |file|
      content = File.read(file)
      content.gsub!("/usr/share/backgrounds/", "#{Dir.home}/.local/share/backgrounds/")
      File.write(file, content)
    end
  end
end
