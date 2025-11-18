cask "aurora-wallpapers" do
  version "2025-11-17"
  sha256 "c5c9d7ea3db87e7d1abf1b5e02d0760164dd9c606014b1078a9402d11f249d87"

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
