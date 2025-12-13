cask "framework-wallpapers" do
  version "2025-12-10"

  name "framework-wallpapers"
  desc "Wallpapers for Framework laptops"
  homepage "https://github.com/hanthor/artwork"

  livecheck do
    url "https://github.com/ublue-os/artwork.git"
    regex(/framework-v?(\d{4}-\d{2}-\d{2})/)
    strategy :github_releases
  end

  on_macos do
    # macOS - install HEIC dynamic wallpapers
    destination_dir = "#{Dir.home}/Library/Desktop Pictures/Framework"

  if File.exist?("/usr/bin/plasmashell")
    url "https://github.com/ublue-os/artwork/releases/download/framework-v#{version}/framework-wallpapers-kde.tar.zstd"
    sha256 "904d5116a7f397733d4e8602e7184bb063f3ab12df241a819187a1c5e8e4eb99"

    Dir.glob("#{staged_path}/*").each do |file|
      artifact file, target: "#{kde_destination_dir}/#{File.basename(file)}"
    end
  elsif File.exist?("/usr/bin/gnome-shell") || File.exist?("/usr/bin/mutter")
    url "https://github.com/ublue-os/artwork/releases/download/framework-v#{version}/framework-wallpapers-gnome.tar.zstd"
    sha256 "cec25556745ec15cbc73eeb356e94479d7daf9cfbcb1a56da408e1e3c917441b"

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

    destination_dir = "#{Dir.home}/.local/share/backgrounds/framework"
    kde_destination_dir = "#{Dir.home}/.local/share/wallpapers/framework"

    if is_gnome
      # GNOME - install SVG wallpapers
      Dir.glob("#{staged_path}/images/*.svg").each do |file|
        artifact file, target: "#{destination_dir}/#{File.basename(file)}"
      end

      Dir.glob("#{staged_path}/images/*.xml").each do |file|
        artifact file, target: "#{destination_dir}/#{File.basename(file)}"
      end

    Dir.glob("#{staged_path}/gnome-background-properties/*").each do |file|
      artifact file, target: "#{Dir.home}/.local/share/gnome-background-properties/#{File.basename(file)}"
    end
  else
    url "https://github.com/ublue-os/artwork/releases/download/framework-v#{version}/framework-wallpapers-png.tar.zstd"
    sha256 "ab55af2ddf076955c6982065e827f4c1fb9864555cb151c7bb10e8187492caf3"

    Dir.glob("#{staged_path}/*").each do |file|
      artifact file, target: "#{destination_dir}/#{File.basename(file)}"
    end
  end

  preflight do
    if OS.mac?
      # Create macOS destination directory
      destination_dir = "#{Dir.home}/Library/Desktop Pictures/Framework"
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

      destination_dir = "#{Dir.home}/.local/share/backgrounds/framework"
      kde_destination_dir = "#{Dir.home}/.local/share/wallpapers/framework"

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
      destination_dir = "#{Dir.home}/Library/Desktop Pictures/Framework"
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
        puts "GNOME wallpapers installed to: #{Dir.home}/.local/share/backgrounds/framework"
      elsif is_kde
        puts "KDE wallpapers installed to: #{Dir.home}/.local/share/wallpapers/framework"
      else
        puts "Wallpapers installed to: #{Dir.home}/.local/share/wallpapers/framework"
      end
    end
  end
end
