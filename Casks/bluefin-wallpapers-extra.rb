cask "bluefin-wallpapers-extra" do
  version "2025-12-10"

  name "bluefin-wallpapers-extra"
  desc "Extra Wallpapers for Bluefin"
  homepage "https://github.com/ublue-os/artwork"

  livecheck do
    url "https://github.com/ublue-os/artwork.git"
    regex(/bluefin-extra-v?(\d{4}-\d{2}-\d{2})/)
    strategy :github_releases
  end

  on_macos do
    url "https://github.com/ublue-os/artwork/releases/download/bluefin-extra-v#{version}/bluefin-wallpapers-extra-macos.tar.zstd"
    sha256 "bce247f55c0971c8b601b63c02a62cd8e66fc502cdd620b188e9306db60123b0"

    Dir.glob("#{staged_path}/*").each do |file|
      artifact file, target: "#{Dir.home}/Library/Desktop Pictures/Bluefin-Extra/#{File.basename(file)}"
    end
  end

  on_linux do
    destination_dir = "#{Dir.home}/.local/share/backgrounds/bluefin"
    kde_destination_dir = "#{Dir.home}/.local/share/wallpapers/bluefin"

    if File.exist?("/usr/bin/plasmashell")
      url "https://github.com/ublue-os/artwork/releases/download/bluefin-extra-v#{version}/bluefin-wallpapers-extra-kde.tar.zstd"
      sha256 "0e78c4772c9f03efa4f6a801081c82dd950ff5dffe69f2c30e9a58e64c4a2a42"

      Dir.glob("#{staged_path}/*").each do |file|
        artifact file, target: "#{kde_destination_dir}/#{File.basename(file)}"
      end
    elsif File.exist?("/usr/bin/gnome-shell") || File.exist?("/usr/bin/mutter")
      url "https://github.com/ublue-os/artwork/releases/download/bluefin-extra-v#{version}/bluefin-wallpapers-extra-gnome.tar.zstd"
      sha256 "3062c5d0ec576ce896b1fda73959423b1285151c68bca44e8216c3feb14d45ba"

      Dir.glob("#{staged_path}/images/*").each do |file|
        folder = File.basename(file, File.extname(file)).gsub(/-night|-day/, "")
        artifact file, target: "#{destination_dir}/#{folder}/#{File.basename(file)}"
      end

      Dir.glob("#{staged_path}/gnome-background-properties/*").each do |file|
        artifact file, target: "#{Dir.home}/.local/share/gnome-background-properties/#{File.basename(file)}"
      end
    else
      url "https://github.com/ublue-os/artwork/releases/download/bluefin-extra-v#{version}/bluefin-wallpapers-extra-png.tar.zstd"
      sha256 "1d5201c6cf33f64b7cdc7a11099f79cb311aa67fd6781c4158d614209e05133f"

      Dir.glob("#{staged_path}/*").each do |file|
        artifact file, target: "#{destination_dir}/#{File.basename(file)}"
      end
    end
  end

  preflight do
    FileUtils.mkdir_p "#{Dir.home}/Library/Desktop Pictures/Bluefin-Extra" if OS.mac?

    if OS.linux?
      FileUtils.mkdir_p "#{Dir.home}/.local/share/backgrounds/bluefin"
      FileUtils.mkdir_p "#{Dir.home}/.local/share/wallpapers/bluefin"
      FileUtils.mkdir_p "#{Dir.home}/.local/share/gnome-background-properties"

      Dir.glob("#{staged_path}/**/*.xml").each do |file|
        contents = File.read(file)
        contents.gsub!("~", Dir.home)
        File.write(file, contents)
      end
    end
  end

  postflight do
    if OS.mac?
      puts "Wallpapers installed to: #{Dir.home}/Library/Desktop Pictures/Bluefin-Extra"
      puts "To use: System Settings > Wallpaper > Add Folder"
    end
  end
end
