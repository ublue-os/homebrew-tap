cask "aurora-wallpapers" do
  version "2025-12-10"
  sha256 "dcf9a202c66b759cdc50780c3087d689365d4b5536603d9a4eb1f8d8924ef00e"

  url "https://github.com/ublue-os/artwork/releases/download/aurora-v#{version}/aurora-wallpapers.tar.zstd"
  name "aurora-wallpapers"
  desc "Wallpapers for Aurora"
  homepage "https://github.com/projectbluefin/artwork"

  livecheck do
    url "https://github.com/ublue-os/artwork.git"
    regex(/aurora-v?(\d{4}-\d{2}-\d{2})/)
    strategy :github_releases
  end

  on_macos do
    # macOS - install PNG wallpapers
    destination_dir = "#{Dir.home}/Library/Desktop Pictures/Aurora"

    Dir.glob("#{staged_path}/kde/*").each do |dir|
      Dir.glob("#{dir}/contents/images/*.png").each do |file|
        wallpaper_name = File.basename(dir)
        artifact file, target: "#{destination_dir}/#{wallpaper_name}.png"
      end
    end
  end

  on_linux do
    # Detect if GNOME is actually running
    is_gnome = ENV["XDG_CURRENT_DESKTOP"]&.include?("GNOME") ||
               ENV["DESKTOP_SESSION"]&.include?("gnome") ||
               (File.exist?("/usr/bin/gnome-shell") && `pgrep -x gnome-shell 2>/dev/null`.strip != "")

    # Detect if KDE is running
    is_kde = ENV["XDG_CURRENT_DESKTOP"]&.include?("KDE") ||
             ENV["DESKTOP_SESSION"]&.include?("kde") ||
             File.exist?("/usr/bin/plasmashell")

    if is_kde
      Dir.glob("#{staged_path}/kde/*").each do |dir|
        next if dir.include?("gnome-background-properties")

        artifact dir, target: "#{Dir.home}/.local/share/backgrounds/aurora/#{File.basename(dir)}"
      end
    else
      Dir.glob("#{staged_path}/kde/*").each do |dir|
        Dir.glob("#{dir}/contents/images/*").each do |file|
          extension = File.extname(file)
          File.basename(file, extension)
          artifact file, target: "#{Dir.home}/.local/share/backgrounds/aurora/#{File.basename(dir)}#{extension}"
        end

        Dir.glob("#{dir}/gnome-background-properties/*").each do |file|
          artifact file, target: "#{Dir.home}/.local/share/gnome-background-properties/#{File.basename(file)}"
        end
      end
    end
  end

  preflight do
    if OS.mac?
      # Create macOS destination directory
      destination_dir = "#{Dir.home}/Library/Desktop Pictures/Aurora"
      FileUtils.mkdir_p destination_dir
    end

    if OS.linux?
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
      destination_dir = "#{Dir.home}/Library/Desktop Pictures/Aurora"
      puts "Wallpapers installed to: #{destination_dir}"
      puts "To use: System Settings > Wallpaper > Add Folder > #{destination_dir}"
    end

    if OS.linux?
      puts "Wallpapers installed to: #{Dir.home}/.local/share/backgrounds/aurora"
    end
  end
end
