cask "bluefin-wallpapers-extra" do
  os macos: "darwin", linux: "linux"

  version "2026-04-28"

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
    sha256 "4dea7111f2a8ab3604f69bf67fdb2d300a61ecde845ad52e4fd47237790df261"
  end

  on_linux do
    if File.exist?("/usr/bin/plasmashell")
      url "https://github.com/ublue-os/artwork/releases/download/bluefin-extra-v#{version}/bluefin-wallpapers-extra-kde.tar.zstd"
      sha256 "ef6b20d66b8335bb1f3cc27e2be152187df8820e064f48106bb44c69c27a3ec7"
    elsif File.exist?("/usr/bin/gnome-shell") || File.exist?("/usr/bin/mutter")
      url "https://github.com/ublue-os/artwork/releases/download/bluefin-extra-v#{version}/bluefin-wallpapers-extra-gnome.tar.zstd"
      sha256 "722c7dcd4b8d6bb5156197b3167c0a005ca9e3cfdade29859c4ae63bdfd8afde"
    else
      url "https://github.com/ublue-os/artwork/releases/download/bluefin-extra-v#{version}/bluefin-wallpapers-extra-png.tar.zstd"
      sha256 "33e668befaa7e0aa2b70db3a46329588d45d05c298220af8aa7b5d6ceb881817"
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
      Dir.glob("#{staged_path}/*").each do |file|
        target = "#{Dir.home}/Library/Desktop Pictures/Bluefin-Extra/#{File.basename(file)}"
        FileUtils.ln_sf(file, target)
      end
      puts "Wallpapers installed to: #{Dir.home}/Library/Desktop Pictures/Bluefin-Extra"
      puts "To use: System Settings > Wallpaper > Add Folder"
    end

    if OS.linux?
      destination_dir = "#{Dir.home}/.local/share/backgrounds/bluefin"
      kde_destination_dir = "#{Dir.home}/.local/share/wallpapers/bluefin"

      if File.exist?("/usr/bin/plasmashell")
        Dir.glob("#{staged_path}/*").each do |file|
          target = "#{kde_destination_dir}/#{File.basename(file)}"
          FileUtils.ln_sf(file, target)
        end
      elsif File.exist?("/usr/bin/gnome-shell") || File.exist?("/usr/bin/mutter")
        Dir.glob("#{staged_path}/images/*").each do |file|
          folder = File.basename(file, File.extname(file)).gsub(/-night|-day/, "")
          FileUtils.mkdir_p "#{destination_dir}/#{folder}"
          target = "#{destination_dir}/#{folder}/#{File.basename(file)}"
          FileUtils.ln_sf(file, target)
        end

        Dir.glob("#{staged_path}/gnome-background-properties/*").each do |file|
          target = "#{Dir.home}/.local/share/gnome-background-properties/#{File.basename(file)}"
          FileUtils.ln_sf(file, target)
        end
      else
        Dir.glob("#{staged_path}/*").each do |file|
          target = "#{destination_dir}/#{File.basename(file)}"
          FileUtils.ln_sf(file, target)
        end
      end
    end
  end

  uninstall_postflight do
    FileUtils.rm_r "#{Dir.home}/Library/Desktop Pictures/Bluefin-Extra" if OS.mac?

    if OS.linux?
      bg_dir    = "#{Dir.home}/.local/share/backgrounds/bluefin"
      kde_dir   = "#{Dir.home}/.local/share/wallpapers/bluefin"
      props_dir = "#{Dir.home}/.local/share/gnome-background-properties"

      # Remove only the symlinks this cask created via postflight. During upgrade,
      # these point to the old staged path (now being removed) and become broken.
      # Symlinks from bluefin-wallpapers point to a separate Caskroom path that is
      # not being removed, so they remain valid and are intentionally left alone.
      [bg_dir, kde_dir].each do |dir|
        next unless Dir.exist?(dir)

        Dir.glob("#{dir}/**/*").reverse_each do |f|
          File.unlink(f) if File.symlink?(f) && !File.exist?(f)
          next unless File.directory?(f)
          next unless Dir.empty?(f)

          begin
            Dir.rmdir(f)
          rescue
            nil
          end
        end
      end

      if Dir.exist?(props_dir)
        Dir.glob("#{props_dir}/*.xml").each do |f|
          File.unlink(f) if File.symlink?(f) && !File.exist?(f)
        end
      end
    end
  end

  zap trash: [
    "#{Dir.home}/.local/share/backgrounds/bluefin",
    "#{Dir.home}/.local/share/gnome-background-properties/bluefin-*.xml",
    "#{Dir.home}/.local/share/wallpapers/bluefin",
    "#{Dir.home}/Library/Desktop Pictures/Bluefin-Extra",
  ]
end
