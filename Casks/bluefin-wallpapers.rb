cask "bluefin-wallpapers" do
  version "2025-12-10"

  name "bluefin-wallpapers"
  desc "Wallpapers for Bluefin"
  homepage "https://github.com/hanthor/artwork"

  livecheck do
    url "https://github.com/ublue-os/artwork.git"
    regex(/bluefin-v?(\d{4}-\d{2}-\d{2})/)
    strategy :github_releases
  end

  on_macos do
    # macOS - install HEIC dynamic wallpapers
    destination_dir = "#{Dir.home}/Library/Desktop Pictures/Bluefin"

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

    destination_dir = "#{Dir.home}/.local/share/backgrounds/bluefin"
    kde_destination_dir = "#{Dir.home}/.local/share/wallpapers/bluefin"

    if is_gnome
      # GNOME - install JXL wallpapers
      Dir.glob("#{staged_path}/*.jxl").each do |file|
        artifact file, target: "#{destination_dir}/#{File.basename(file)}"
      end

      Dir.glob("#{staged_path}/*.xml").each do |file|
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

  preflight do
    if OS.mac?
      # Create macOS destination directory
      destination_dir = "#{Dir.home}/Library/Desktop Pictures/Bluefin"
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

      destination_dir = "#{Dir.home}/.local/share/backgrounds/bluefin"
      kde_destination_dir = "#{Dir.home}/.local/share/wallpapers/bluefin"

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
      destination_dir = "#{Dir.home}/Library/Desktop Pictures/Bluefin"
      puts "Wallpapers installed to: #{destination_dir}"
      puts "To use: System Settings > Wallpaper > Add Photo > Choose Folder > #{destination_dir}"
    end

    if OS.linux?
      is_gnome = ENV["XDG_CURRENT_DESKTOP"]&.include?("GNOME") ||
                 ENV["DESKTOP_SESSION"]&.include?("gnome") ||
                 (File.exist?("/usr/bin/gnome-shell") && `pgrep -x gnome-shell 2>/dev/null`.strip != "")

      is_kde = ENV["XDG_CURRENT_DESKTOP"]&.include?("KDE") ||
               ENV["DESKTOP_SESSION"]&.include?("kde") ||
               File.exist?("/usr/bin/plasmashell")

      if is_gnome
        puts "GNOME wallpapers installed to: #{Dir.home}/.local/share/backgrounds/bluefin"
      elsif is_kde
        puts "KDE wallpapers installed to: #{Dir.home}/.local/share/wallpapers/bluefin"
      else
        puts "Wallpapers installed to: #{Dir.home}/.local/share/wallpapers/bluefin"
      end
    end
  end
end
