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
    # macOS - install HEIC dynamic wallpapers
    destination_dir = "#{Dir.home}/Library/Desktop Pictures/Bluefin-Extra"

  if File.exist?("/usr/bin/plasmashell")
    url "https://github.com/ublue-os/artwork/releases/download/bluefin-extra-v#{version}/bluefin-wallpapers-extra-kde.tar.zstd"
    sha256 "84f714825d61a0518421314b1afb3b7fcb19c7f5c213a06f5f8928a15be54a1c"

    Dir.glob("#{staged_path}/*").each do |file|
      artifact file, target: "#{kde_destination_dir}/#{File.basename(file)}"
    end
  elsif File.exist?("/usr/bin/gnome-shell") || File.exist?("/usr/bin/mutter")
    url "https://github.com/ublue-os/artwork/releases/download/bluefin-extra-v#{version}/bluefin-wallpapers-extra-gnome.tar.zstd"
    sha256 "98b8a10a31f571a791f806a96d5f40287169d6fae223d5ae53dae065d377a4d6"

    Dir.glob("#{staged_path}/images/*").each do |file|
      folder = File.basename(file, File.extname(file)).gsub(/-night|-day/, "")
      artifact file, target: "#{destination_dir}/#{folder}/#{File.basename(file)}"
    end
  end

  on_linux do
    # Detect if GNOME is actually running
    is_gnome = ENV["XDG_CURRENT_DESKTOP"]&.include?("GNOME") ||
               ENV["DESKTOP_SESSION"]&.include?("gnome") ||
               (File.exist?("/usr/bin/gnome-shell") && `pgrep -x gnome-shell`.strip != "")

    # Detect if KDE is running
    is_kde = ENV["XDG_CURRENT_DESKTOP"]&.include?("KDE") ||
             ENV["DESKTOP_SESSION"]&.include?("kde") ||
             File.exist?("/usr/bin/plasmashell")

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

  preflight do
    if OS.mac?
      # Create macOS destination directory
      destination_dir = "#{Dir.home}/Library/Desktop Pictures/Bluefin-Extra"
      FileUtils.mkdir_p destination_dir
    end

    if OS.linux?
      # Detect if GNOME is actually running
      is_gnome = ENV["XDG_CURRENT_DESKTOP"]&.include?("GNOME") ||
                 ENV["DESKTOP_SESSION"]&.include?("gnome") ||
                 (File.exist?("/usr/bin/gnome-shell") && `pgrep -x gnome-shell 2>/dev/null`.strip != "")

      # Detect if KDE is running
      ENV["XDG_CURRENT_DESKTOP"]&.include?("KDE") ||
        ENV["DESKTOP_SESSION"]&.include?("kde") ||
        File.exist?("/usr/bin/plasmashell")

      destination_dir = "#{Dir.home}/.local/share/backgrounds/bluefin-extra"
      kde_destination_dir = "#{Dir.home}/.local/share/wallpapers/bluefin-extra"

      # Create destination directories
      FileUtils.mkdir_p kde_destination_dir unless is_gnome
      FileUtils.mkdir_p destination_dir if is_gnome
      FileUtils.mkdir_p "#{Dir.home}/.local/share/gnome-background-properties" if is_gnome

      # Update XML file paths for GNOME
      Dir.glob("#{staged_path}/**/*.xml").each do |file|
        next unless File.file?(file)

        contents = File.read(file)
        contents.gsub!("~", Dir.home)
        File.write(file, contents)
      end
    end
  end

  postflight do
    if OS.mac?
      destination_dir = "#{Dir.home}/Library/Desktop Pictures/Bluefin-Extra"
      puts "Wallpapers installed to: #{destination_dir}"
      puts "To use: System Settings > Wallpaper > Add Folder > #{destination_dir}"
    end

    if OS.linux?
      is_gnome = ENV["XDG_CURRENT_DESKTOP"]&.include?("GNOME") ||
                 ENV["DESKTOP_SESSION"]&.include?("gnome") ||
                 (File.exist?("/usr/bin/gnome-shell") && `pgrep -x gnome-shell 2>/dev/null`.strip != "")

      is_kde = ENV["XDG_CURRENT_DESKTOP"]&.include?("KDE") ||
               ENV["DESKTOP_SESSION"]&.include?("kde") ||
               File.exist?("/usr/bin/plasmashell")

      if is_gnome
        puts "GNOME wallpapers installed to: #{Dir.home}/.local/share/backgrounds/bluefin-extra"
      elsif is_kde
        puts "KDE wallpapers installed to: #{Dir.home}/.local/share/wallpapers/bluefin-extra"
      else
        puts "Wallpapers installed to: #{Dir.home}/.local/share/wallpapers/bluefin-extra"
      end
    end
  end
end
