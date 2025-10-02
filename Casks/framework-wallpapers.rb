cask "framework-wallpapers" do
  version :latest
  sha256 :no_check

  url "https://github.com/projectbluefin/artwork/releases/latest/download/framework-wallpapers.tar.zstd"
  name "framework-wallpapers"
  desc "Extra Wallpapers for Bluefin"
  homepage "https://github.com/projectbluefin/artwork"

  destination_dir = "#{Dir.home}/.local/share/backgrounds/bluefin/framework"

  if Env["XDG_CURRENT_DESKTOP"] == "KDE"
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
