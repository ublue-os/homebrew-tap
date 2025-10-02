cask "bazzite-wallpapers" do
  version :latest
  sha256 :no_check

  url "https://github.com/projectbluefin/artwork/releases/latest/download/bazzite-wallpapers.tar.zstd"
  name "bazzite-wallpapers"
  desc "Wallpapers for Bazzite"
  homepage "https://bazzite.gg/"

  destination_dir = "#{Dir.home}/.local/share/backgrounds/bazzite"

  if File.exist?("/usr/bin/plasmashell")
    Dir.glob("#{staged_path}/images/*").each do |file|
      artifact file, target: "#{destination_dir}/#{File.basename(file)}"
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
