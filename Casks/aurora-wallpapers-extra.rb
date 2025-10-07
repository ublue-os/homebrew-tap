cask "aurora-wallpapers-extra" do
  version "2025-10-07"
  sha256 :no_check

  url "https://github.com/projectbluefin/artwork/releases/latest/download/aurora-wallpapers-extra.tar.zstd"
  name "aurora-wallpapers-extra"
  desc "Extra Wallpapers for Aurora"
  homepage "https://github.com/ublue-os/artwork"

  livecheck do
    regex(/v?(\d{4}-\d{2}-\d{2})/)
    strategy :github_latest
  end

  auto_updates true

  destination_dir = "#{Dir.home}/.local/share/backgrounds/aurora"
  kde_destination_dir = "#{Dir.home}/.local/share/wallpapers/aurora"

  if File.exist?("/usr/bin/plasmashell")
    Dir.glob("#{staged_path}/kde/*").each do |file|
      artifact file, target: "#{kde_destination_dir}/#{File.basename(file)}"
    end
  else
    Dir.glob("#{staged_path}/gnome/images/*").each do |file|
      folder = File.basename(file, File.extname(file)).gsub(/-night|-day/, "")
      artifact file, target: "#{destination_dir}/#{folder}/#{File.basename(file)}"
    end

    Dir.glob("#{staged_path}/gnome/gnome-background-properties/*").each do |file|
      artifact file, target: "#{Dir.home}/.local/share/gnome-background-properties/#{File.basename(file)}"
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

