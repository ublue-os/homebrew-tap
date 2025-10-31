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

  destination_dir = "#{Dir.home}/.local/share/backgrounds/bluefin"
  kde_destination_dir = "#{Dir.home}/.local/share/wallpapers/bluefin"

  # Detect if GNOME is actually running
  is_gnome = ENV["XDG_CURRENT_DESKTOP"]&.include?("GNOME") || 
             ENV["DESKTOP_SESSION"]&.include?("gnome") ||
             (File.exist?("/usr/bin/gnome-shell") && `pgrep -x gnome-shell`.strip != "")

  if is_gnome
    Dir.glob("#{staged_path}/gnome/images/*").each do |file|
      artifact file, target: "#{destination_dir}/#{File.basename(file)}"
    end

    Dir.glob("#{staged_path}/gnome/gnome-background-properties/*").each do |file|
      artifact file, target: "#{Dir.home}/.local/share/gnome-background-properties/#{File.basename(file)}"
    end
  else
    # Use KDE wallpapers for KDE, Hyprland, Niri, and other non-GNOME desktops
    Dir.glob("#{staged_path}/kde/*").each do |file|
      artifact file, target: "#{kde_destination_dir}/#{File.basename(file)}"
    end
  end

  preflight do
    Dir.glob("#{staged_path}/**/*.xml").each do |file|
      contents = File.read(file)
      contents.gsub!("~", Dir.home)
      File.write(file, contents)
    end
  end
end
