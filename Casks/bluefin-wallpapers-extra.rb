cask "bluefin-wallpapers-extra" do
  version :latest
  sha256 :no_check

  url "https://github.com/projectbluefin/artwork/releases/latest/download/bazzite-wallpapers-extra.tar.zstd"
  name "bluefin-wallpapers-extra"
  desc "Extra Wallpapers for Bluefin"
  homepage "https://github.com/projectbluefin/artwork"

  destination_dir = "#{Dir.home}/.local/share/backgrounds/bluefin"

  if ENV["XDG_CURRENT_DESKTOP"] == "KDE"
    Dir.glob("#{staged_path}/kde/*").each do |file|
      artifact file, target: "#{destination_dir}/#{File.basename(file)}"
    end
  else
    Dir.glob("#{staged_path}/gnome/images/*").each do |file|
      artifact file, target: "#{destination_dir}/#{File.basename(file)}"
    end

    Dir.glob("#{staged_path}/gnome/gnome-background-properties/*").each do |file|
      artifact file, target: "#{Dir.home}/.local/share/gnome-background-properties/#{File.basename(file)}"
    end
  end
end
