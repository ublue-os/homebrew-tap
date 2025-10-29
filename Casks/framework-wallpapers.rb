cask "framework-wallpapers" do
  version "2025-10-29"
  sha256 "4c5d8742d7b1e6e44a04911a92fc363ca9a39bd7de1bec927a23741793cbe3e4"

  url "https://github.com/projectbluefin/artwork/releases/latest/download/framework-wallpapers.tar.zstd"
  name "framework-wallpapers"
  desc "Extra Wallpapers for Bluefin"
  homepage "https://github.com/projectbluefin/artwork"

  livecheck do
    regex(/v?(\d{4}-\d{2}-\d{2})/)
    strategy :github_latest
  end

  destination_dir = "#{Dir.home}/.local/share/backgrounds/framework"
  kde_destination_dir = "#{Dir.home}/.local/share/wallpapers/framework"

  if File.exist?("/usr/bin/plasmashell")
    Dir.glob("#{staged_path}/kde/*").each do |file|
      artifact file, target: "#{kde_destination_dir}/#{File.basename(file)}"
    end
  else
    Dir.glob("#{staged_path}/gnome/images/*").each do |file|
      artifact file, target: "#{destination_dir}/#{File.basename(file)}"
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
