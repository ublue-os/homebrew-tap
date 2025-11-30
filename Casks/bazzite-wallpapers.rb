cask "bazzite-wallpapers" do
  version "2025-11-29"
  sha256 "86b2219cc9fec6424dd533abe43d894afcc903c2c98ccf57b4b215c962509770"

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
