cask "aurora-wallpapers" do
  version "2026-04-07"
  sha256 "f9f27fd73afdbd3380197478721aeb3a534bc7a9ffe562008ccb29f111175c1b"

  url "https://github.com/ublue-os/artwork/releases/download/aurora-v#{version}/aurora-wallpapers.tar.zstd"
  name "aurora-wallpapers"
  desc "Wallpapers for Aurora"
  homepage "https://github.com/projectbluefin/artwork"

  livecheck do
    url "https://github.com/ublue-os/artwork.git"
    regex(/aurora-v?(\d{4}-\d{2}-\d{2})/)
    strategy :github_releases
  end

  preflight do
    FileUtils.mkdir_p "#{Dir.home}/.local/share/backgrounds/aurora"
    FileUtils.mkdir_p "#{Dir.home}/.local/share/gnome-background-properties"

    Dir.glob("#{staged_path}/**/*.xml").each do |file|
      contents = File.read(file)
      contents.gsub!("~", Dir.home)
      File.write(file, contents)
    end
  end

  postflight do
    if File.exist?("/usr/bin/plasmashell")
      Dir.glob("#{staged_path}/kde/*").each do |dir|
        next if dir.include?("gnome-background-properties")

        target = "#{Dir.home}/.local/share/backgrounds/aurora/#{File.basename(dir)}"
        FileUtils.ln_sf(dir, target)
      end
    else
      Dir.glob("#{staged_path}/kde/*").each do |dir|
        Dir.glob("#{dir}/contents/images/*").each do |file|
          extension = File.extname(file)
          target = "#{Dir.home}/.local/share/backgrounds/aurora/#{File.basename(dir)}#{extension}"
          FileUtils.ln_sf(file, target)
        end

        Dir.glob("#{dir}/gnome-background-properties/*").each do |file|
          target = "#{Dir.home}/.local/share/gnome-background-properties/#{File.basename(file)}"
          FileUtils.ln_sf(file, target)
        end
      end
    end
  end

  uninstall_postflight do
    FileUtils.rm_r "#{Dir.home}/.local/share/backgrounds/aurora"
  end

  zap trash: [
    "#{Dir.home}/.local/share/backgrounds/aurora",
    "#{Dir.home}/.local/share/gnome-background-properties/aurora-*.xml",
  ]
end
