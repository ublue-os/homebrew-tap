cask "bluefin-wallpapers" do
  version "2025-12-10"

  name "bluefin-wallpapers"
  desc "Wallpapers for Bluefin"
  homepage "https://github.com/projectbluefin/artwork"

  livecheck do
    url "https://github.com/ublue-os/artwork.git"
    regex(/bluefin-v?(\d{4}-\d{2}-\d{2})/)
    strategy :github_releases
  end

  on_macos do
    url "https://github.com/ublue-os/artwork/releases/download/bluefin-v#{version}/bluefin-wallpapers-macos.tar.zstd"
    sha256 "a391978425ee43aca090c76da1b9e05bd38a15d89115c59310cc951023142a5e"

    Dir.glob("#{staged_path}/*").each do |file|
      artifact file, target: "#{Dir.home}/Library/Desktop Pictures/Bluefin/#{File.basename(file)}"
    end
  end

  on_linux do
    destination_dir = "#{Dir.home}/.local/share/backgrounds/bluefin"
    kde_destination_dir = "#{Dir.home}/.local/share/wallpapers/bluefin"

    if File.exist?("/usr/bin/plasmashell")
      url "https://github.com/ublue-os/artwork/releases/download/bluefin-v#{version}/bluefin-wallpapers-kde.tar.zstd"
      sha256 "eb426ce1b7a738d838c1cc0db20d4d37137dff5bcd8911e38f1e6f813ce0d658"

      Dir.glob("#{staged_path}/*").each do |file|
        artifact file, target: "#{kde_destination_dir}/#{File.basename(file)}"
      end
    elsif File.exist?("/usr/bin/gnome-shell") || File.exist?("/usr/bin/mutter")
      url "https://github.com/ublue-os/artwork/releases/download/bluefin-v#{version}/bluefin-wallpapers-gnome.tar.zstd"
      sha256 "305ae1cef0cc60c498b12f1937fcfde85c81dcf9e979daaf8d843d94297b234c"

      Dir.glob("#{staged_path}/images/*").each do |file|
        artifact file, target: "#{destination_dir}/#{File.basename(file)}"
      end

      Dir.glob("#{staged_path}/gnome-background-properties/*").each do |file|
        artifact file, target: "#{Dir.home}/.local/share/gnome-background-properties/#{File.basename(file)}"
      end
    else
      url "https://github.com/ublue-os/artwork/releases/download/bluefin-v#{version}/bluefin-wallpapers-png.tar.zstd"
      sha256 "411f3997b0a73d991f81e88d495ad70a5a3b15ddcf5d73ffd1b3ef255b39689d"

      Dir.glob("#{staged_path}/*").each do |file|
        artifact file, target: "#{destination_dir}/#{File.basename(file)}"
      end
    end
  end

  preflight do
    FileUtils.mkdir_p "#{Dir.home}/Library/Desktop Pictures/Bluefin" if OS.mac?

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
      puts "Wallpapers installed to: #{Dir.home}/Library/Desktop Pictures/Bluefin"
      puts "To use: System Settings > Wallpaper > Add Folder"
    end
  end
end
