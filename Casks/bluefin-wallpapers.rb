cask "bluefin-wallpapers" do
  version "2025-10-29"
  sha256 "76915478e38f702c4c01d906116a216c2040c7f3e33bd64a6a6ffa54727795a4"

  url "https://github.com/projectbluefin/artwork/releases/latest/download/bluefin-wallpapers.tar.zstd"
  name "bluefin-wallpapers"
  desc "Wallpapers for Bluefin"
  homepage "https://github.com/projectbluefin/artwork"

  livecheck do
    regex(/v?(\d{4}-\d{2}-\d{2})/)
    strategy :github_latest
  end

  # Detect if GNOME is actually running
  is_gnome = ENV["XDG_CURRENT_DESKTOP"]&.include?("GNOME") || 
             ENV["DESKTOP_SESSION"]&.include?("gnome") ||
             (File.exist?("/usr/bin/gnome-shell") && `pgrep -x gnome-shell`.strip != "")

  # Detect if KDE is running
  is_kde = ENV["XDG_CURRENT_DESKTOP"]&.include?("KDE") ||
           ENV["DESKTOP_SESSION"]&.include?("kde") ||
           File.exist?("/usr/bin/plasmashell")

  # Only depend on ImageMagick if not on GNOME or KDE
  depends_on formula: "imagemagick" unless is_gnome || is_kde

  destination_dir = "#{Dir.home}/.local/share/backgrounds/bluefin"
  kde_destination_dir = "#{Dir.home}/.local/share/wallpapers/bluefin"

  if is_gnome
    Dir.glob("#{staged_path}/gnome/images/*").each do |file|
      artifact file, target: "#{destination_dir}/#{File.basename(file)}"
    end

    Dir.glob("#{staged_path}/gnome/gnome-background-properties/*").each do |file|
      artifact file, target: "#{Dir.home}/.local/share/gnome-background-properties/#{File.basename(file)}"
    end
  elsif is_kde
    # Use KDE wallpapers for KDE
    Dir.glob("#{staged_path}/kde/*").each do |file|
      artifact file, target: "#{kde_destination_dir}/#{File.basename(file)}"
    end
  else
    # For other desktops (Hyprland, Niri, Sway, etc.), convert to PNG
    Dir.glob("#{staged_path}/kde/*").each do |file|
      artifact file, target: "#{kde_destination_dir}/#{File.basename(file)}"
    end
  end

  preflight do
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

    # Convert KDE wallpapers to PNG if not on KDE or GNOME
    unless is_gnome || is_kde
      Dir.glob("#{staged_path}/kde/*").each do |file|
        next unless File.file?(file)
        
        filename = File.basename(file)
        output_file = "#{kde_destination_dir}/#{filename.gsub(/\.(avif|jxl)$/, '.png')}"
        
        # Convert image to PNG using ImageMagick
        system("convert", file, output_file)
      end
    end

    Dir.glob("#{staged_path}/**/*.xml").each do |file|
      contents = File.read(file)
      contents.gsub!("~", Dir.home)
      # Replace image extensions for converted files if not GNOME/KDE
      unless is_gnome || is_kde
        contents.gsub!(/\.(avif|jxl)(['"]\s*$)/, '.png\2')
      end
      File.write(file, contents)
    end
  end
end
