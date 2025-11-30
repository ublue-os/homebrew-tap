cask "bluefin-wallpapers-extra" do
  version "2025-11-29"

  name "bluefin-wallpapers-extra"
  desc "Extra Wallpapers for Bluefin"
  homepage "https://github.com/ublue-os/artwork"

  livecheck do
    url "https://github.com/ublue-os/artwork.git"
    regex(/bluefin-extra-v?(\d{4}-\d{2}-\d{2})/)
    strategy :github_releases
  end

  destination_dir = "#{Dir.home}/.local/share/backgrounds/bluefin"
  kde_destination_dir = "#{Dir.home}/.local/share/wallpapers/bluefin"

  if File.exist?("/usr/bin/plasmashell")
    url "https://github.com/ublue-os/artwork/releases/download/bluefin-extra-v#{version}/bluefin-wallpapers-extra-kde.tar.zstd"
    sha256 "84f714825d61a0518421314b1afb3b7fcb19c7f5c213a06f5f8928a15be54a1c"

    Dir.glob("#{staged_path}/*").each do |file|
      artifact file, target: "#{kde_destination_dir}/#{File.basename(file)}"
    end
  elsif File.exist?("/usr/bin/gnome-shell") || File.exist?("/usr/bin/mutter")
    url "https://github.com/ublue-os/artwork/releases/download/bluefin-extra-v#{version}/bluefin-wallpapers-extra-gnome.tar.zstd"
    sha256 "b5fdfd634d007ea9bb2f6c8aa8ad783593741814337adbd94039c16d6bc1cf0b"

    Dir.glob("#{staged_path}/images/*").each do |file|
      folder = File.basename(file, File.extname(file)).gsub(/-night|-day/, "")
      artifact file, target: "#{destination_dir}/#{folder}/#{File.basename(file)}"
    end

    Dir.glob("#{staged_path}/gnome-background-properties/*").each do |file|
      artifact file, target: "#{Dir.home}/.local/share/gnome-background-properties/#{File.basename(file)}"
    end
  else
    url "https://github.com/ublue-os/artwork/releases/download/bluefin-extra-v#{version}/bluefin-wallpapers-extra-png.tar.zstd"
    sha256 "da8f98c11cea6f12bd75a13b58cf83f4b7f3d2dc4b620096b4448f9b5b7810de"

    Dir.glob("#{staged_path}/*").each do |file|
      artifact file, target: "#{destination_dir}/#{File.basename(file)}"
    end
  end

  preflight do
    Dir.glob("#{staged_path}/**/*.xml").each do |file|
      contents = File.read(file)
      contents.gsub!("~", Dir.home)
      File.write(file, contents)
    end
  end
end
