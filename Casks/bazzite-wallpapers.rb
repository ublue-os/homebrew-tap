cask "bazzite-wallpapers" do
  version "2025-11-17"
  sha256 "b14feecf13568a2d42754f59fe90f5a2ce590ebe5e2b2596ad4735ca087d6c4a"

  url "https://github.com/ublue-os/artwork/releases/download/bazzite-v#{version}/bazzite-wallpapers.tar.zstd"
  name "bazzite-wallpapers"
  desc "Wallpapers for Bazzite"
  homepage "https://bazzite.gg/"

  livecheck do
    url "https://github.com/ublue-os/artwork.git"
    regex(/bazzite-v?(\d{4}-\d{2}-\d{2})/)
    strategy :github_releases
  end

  destination_dir = "#{Dir.home}/.local/share/backgrounds/bazzite"
  kde_destination_dir = "#{Dir.home}/.local/share/backgrounds/bazzite"

  if File.exist?("/usr/bin/plasmashell")
    Dir.glob("#{staged_path}/*").each do |file|
      artifact file, target: "#{kde_destination_dir}/#{File.basename(file)}"
    end
  else
    Dir.glob("#{staged_path}/images/*").each do |file|
      artifact file, target: "#{destination_dir}/#{File.basename(file)}"
    end

    Dir.glob("#{staged_path}/gnome-background-properties/*").each do |file|
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
