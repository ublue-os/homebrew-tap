cask "aurora-wallpapers" do
  version "2025-11-30"
  sha256 "c953f8ef2e4f0a4decc53d4caa15d025a06aef3f401a0aa16551ff7cce5de25e"

  url "https://github.com/ublue-os/artwork/releases/download/aurora-v#{version}/aurora-wallpapers.tar.zstd"
  name "aurora-wallpapers"
  desc "Wallpapers for Aurora"
  homepage "https://github.com/projectbluefin/artwork"

  livecheck do
    url "https://github.com/ublue-os/artwork.git"
    regex(/aurora-v?(\d{4}-\d{2}-\d{2})/)
    strategy :github_releases
  end

  postflight do
    destination_dir = "#{Dir.home}/.local/share/backgrounds/aurora"

    # Process XML files first
    Dir.glob("#{staged_path}/**/*.xml").each do |file|
      contents = File.read(file)
      contents.gsub!("~", Dir.home)
      File.write(file, contents)
    end

    if File.exist?("/usr/bin/plasmashell")
      FileUtils.mkdir_p(destination_dir)
      Dir.glob("#{staged_path}/kde/*").each do |dir|
        next if dir.include?("gnome-background-properties")

        FileUtils.cp_r(dir, "#{destination_dir}/#{File.basename(dir)}", remove_destination: true)
      end
    else
      FileUtils.mkdir_p(destination_dir)
      FileUtils.mkdir_p("#{Dir.home}/.local/share/gnome-background-properties")

      Dir.glob("#{staged_path}/kde/*").each do |dir|
        Dir.glob("#{dir}/contents/images/*").each do |file|
          extension = File.extname(file)
          FileUtils.cp(file, "#{destination_dir}/#{File.basename(dir)}#{extension}")
        end

        Dir.glob("#{dir}/gnome-background-properties/*").each do |file|
          FileUtils.cp(file, "#{Dir.home}/.local/share/gnome-background-properties/#{File.basename(file)}")
        end
      end
    end
  end

  uninstall_postflight do
    destination_dir = "#{Dir.home}/.local/share/backgrounds/aurora"

    FileUtils.rm_rf(destination_dir) if File.exist?(destination_dir)

    gnome_props_dir = "#{Dir.home}/.local/share/gnome-background-properties"
    Dir.glob("#{gnome_props_dir}/aurora-*.xml").each do |file|
      FileUtils.rm(file) if File.exist?(file)
    end
  end
end
