cask "bazzite-wallpapers" do
  version "2025-12-10"
  sha256 "f661c50d689aed1b04c9f0c25a687bbaf7c2ef85121f46bb757e5e881bb2cf06"

  url "https://github.com/ublue-os/artwork/releases/download/bazzite-v#{version}/bazzite-wallpapers.tar.zstd"
  name "bazzite-wallpapers"
  desc "Wallpapers for Bazzite"
  homepage "https://bazzite.gg/"

  livecheck do
    url "https://github.com/ublue-os/artwork.git"
    regex(/bazzite-v?(\d{4}-\d{2}-\d{2})/)
    strategy :github_releases
  end

  on_macos do
    # macOS - install PNG and JPG wallpapers
    destination_dir = "#{Dir.home}/Library/Desktop Pictures/Bazzite"

  if File.exist?("/usr/bin/plasmashell")
    Dir.glob("#{staged_path}/*").each do |file|
      artifact file, target: "#{kde_destination_dir}/#{File.basename(file)}"
    end
  end

  on_linux do
    # Detect if GNOME is actually running
    ENV["XDG_CURRENT_DESKTOP"]&.include?("GNOME") ||
      ENV["DESKTOP_SESSION"]&.include?("gnome") ||
      (File.exist?("/usr/bin/gnome-shell") && `pgrep -x gnome-shell`.strip != "")

    # Detect if KDE is running
    is_kde = ENV["XDG_CURRENT_DESKTOP"]&.include?("KDE") ||
             ENV["DESKTOP_SESSION"]&.include?("kde") ||
             File.exist?("/usr/bin/plasmashell")

    destination_dir = "#{Dir.home}/.local/share/backgrounds/bazzite"

    Dir.glob("#{staged_path}/images/*").each do |file|
      artifact file, target: "#{destination_dir}/#{File.basename(file)}"
    end

    unless is_kde
      Dir.glob("#{staged_path}/gnome-background-properties/*").each do |file|
        artifact file, target: "#{Dir.home}/.local/share/gnome-background-properties/#{File.basename(file)}"
      end
    end
  end

  preflight do
    # Create directory structure before installation
    if OS.mac?
      destination_dir = "#{Dir.home}/Library/Desktop Pictures/Bazzite"
      FileUtils.mkdir_p(destination_dir)
    else
      # Detect if GNOME is actually running
      is_gnome = ENV["XDG_CURRENT_DESKTOP"]&.include?("GNOME") ||
                 ENV["DESKTOP_SESSION"]&.include?("gnome") ||
                 (File.exist?("/usr/bin/gnome-shell") && `pgrep -x gnome-shell 2>/dev/null`.strip != "")

      # Detect if KDE is running
      is_kde = ENV["XDG_CURRENT_DESKTOP"]&.include?("KDE") ||
               ENV["DESKTOP_SESSION"]&.include?("kde") ||
               File.exist?("/usr/bin/plasmashell")

      Dir.glob("#{staged_path}/**/*.xml").each do |file|
        next unless File.file?(file)

        contents = File.read(file)
        contents.gsub!("~", Dir.home)
        # Replace image extensions for converted files if not GNOME/KDE
        contents.gsub!(/\.(avif|jxl)(?=['"])/, ".png") if !is_gnome && !is_kde
        File.write(file, contents)
      end
    end
  end

  postflight do
    if OS.mac?
      destination_dir = "#{Dir.home}/Library/Desktop Pictures/Bazzite"
      puts "Wallpapers installed to: #{destination_dir}"
      puts "To use: System Settings > Wallpaper > Add Folder > #{destination_dir}"
    end
  end
end
