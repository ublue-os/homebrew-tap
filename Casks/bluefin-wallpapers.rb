cask "bluefin-wallpapers" do
  version "2025-10-29"
  sha256 :no_check

  url "https://github.com/hanthor/artwork/releases/latest/download/bluefin-wallpapers.tar.zstd"
  name "bluefin-wallpapers"
  desc "Wallpapers for Bluefin"
  homepage "https://github.com/hanthor/artwork"

  livecheck do
    regex(/v?(\d{4}-\d{2}-\d{2})/)
    strategy :github_latest
  end

  on_macos do
    # macOS - install HEIC dynamic wallpapers
    destination_dir = "#{Dir.home}/Library/Desktop Pictures/Bluefin"

    # Install macOS HEIC wallpapers
    Dir.glob("#{staged_path}/macos/*.heic").each do |file|
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
      Dir.glob("#{staged_path}/gnome/images/*.jxl").each do |file|
        artifact file, target: "#{destination_dir}/#{File.basename(file)}"
      end

      Dir.glob("#{staged_path}/gnome/images/*.xml").each do |file|
        artifact file, target: "#{destination_dir}/#{File.basename(file)}"
      end

      Dir.glob("#{staged_path}/gnome/gnome-background-properties/*").each do |file|
        artifact file, target: "#{Dir.home}/.local/share/gnome-background-properties/#{File.basename(file)}"
      end
    elsif is_kde
      # KDE - install AVIF wallpapers
      Dir.glob("#{staged_path}/kde/*.avif").each do |file|
        artifact file, target: "#{kde_destination_dir}/#{File.basename(file)}"
      end
    else
      # Other desktops (Hyprland, Niri, Sway, etc.) - install PNG wallpapers
      Dir.glob("#{staged_path}/png/*.png").each do |file|
        artifact file, target: "#{kde_destination_dir}/#{File.basename(file)}"
      end
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
      puts "You can now set them in System Settings > Wallpaper"
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
