cask "aurora-wallpapers" do
  version "2025-10-29"
  sha256 "9ca146a905c330e3a411e2f9036eacbeaa9683ca0c73b32d10110e81cc8e82ff"

  url "https://github.com/ublue-os/artwork/releases/download/aurora-v#{version}/aurora-wallpapers.tar.zstd"
  name "aurora-wallpapers"
  desc "Wallpapers for Aurora"
  homepage "https://github.com/projectbluefin/artwork"

  livecheck do
    url "https://github.com/ublue-os/artwork.git"
    regex(/aurora-v?(\d{4}-\d{2}-\d{2})/)
    strategy :github_releases
  end

  if File.exist?("/usr/bin/plasmashell")
    Dir.glob("#{staged_path}/kde/*").each do |dir|
      next if dir.include?("gnome-background-properties")

      artifact dir, target: "#{Dir.home}/.local/share/backgrounds/aurora/#{File.basename(dir)}"
    end
  else
    Dir.glob("#{staged_path}/kde/*").each do |dir|
      Dir.glob("#{dir}/contents/images/*").each do |file|
        extension = File.extname(file)
        File.basename(file, extension)
        artifact file, target: "#{Dir.home}/.local/share/backgrounds/aurora/#{File.basename(dir)}#{extension}"
      end

      Dir.glob("#{dir}/gnome-background-properties/*").each do |file|
        artifact file, target: "#{Dir.home}/.local/share/gnome-background-properties/#{File.basename(file)}"
      end
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
