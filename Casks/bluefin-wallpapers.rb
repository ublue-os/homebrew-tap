cask "bluefin-wallpapers" do
  version "2025-11-17"

  name "bluefin-wallpapers"
  desc "Wallpapers for Bluefin"
  homepage "https://github.com/projectbluefin/artwork"

  livecheck do
    url "https://github.com/ublue-os/artwork.git"
    regex(/bluefin-v?(\d{4}-\d{2}-\d{2})/)
    strategy :github_releases
  end

  destination_dir = "#{Dir.home}/.local/share/backgrounds/bluefin"
  kde_destination_dir = "#{Dir.home}/.local/share/wallpapers/bluefin"

  if File.exist?("/usr/bin/plasmashell")
    url "https://github.com/ublue-os/artwork/releases/download/bluefin-v#{version}/bluefin-wallpapers-kde.tar.zstd"
    sha256 "d0c57affa270d6a8846f067341d69073c8469f8f97c2e60fbb7b51153483403e"

    Dir.glob("#{staged_path}/*").each do |file|
      artifact file, target: "#{kde_destination_dir}/#{File.basename(file)}"
    end
  elsif File.exist?("/usr/bin/gnome-shell") || File.exist?("/usr/bin/mutter")
    url "https://github.com/ublue-os/artwork/releases/download/bluefin-v#{version}/bluefin-wallpapers-gnome.tar.zstd"
    sha256 "b3aa0df9e6ba7380a797779e14ca58abd6c3d95a7e5e75f6e39a052494f792f1"

    Dir.glob("#{staged_path}/images/*").each do |file|
      artifact file, target: "#{destination_dir}/#{File.basename(file)}"
    end

    Dir.glob("#{staged_path}/gnome-background-properties/*").each do |file|
      artifact file, target: "#{Dir.home}/.local/share/gnome-background-properties/#{File.basename(file)}"
    end
  else
    url "https://github.com/ublue-os/artwork/releases/download/bluefin-v#{version}/bluefin-wallpapers-png.tar.zstd"
    sha256 "5f7536d53b6dbc97629ef8f4ab8cca92183d2ffd719490c660383f156e4295a7"

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
