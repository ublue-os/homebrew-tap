cask "bluefin-wallpapers" do
  version "2025-10-16"
  sha256 "a1f29c5f3025ab64d2359f43218b88e2dc7d2d5b3d9e1e5be8cc8f66709363df"

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
