cask "bazzite-wallpapers" do
  version "2025-11-30"
  sha256 "54f14e251ad48efdc52e002113c8df462d45e09916d836001a056f031dc0eb46"

  url "https://github.com/ublue-os/artwork/releases/download/bazzite-v#{version}/bazzite-wallpapers.tar.zstd"
  name "bazzite-wallpapers"
  desc "Wallpapers for Bazzite"
  homepage "https://bazzite.gg/"

  livecheck do
    url "https://github.com/ublue-os/artwork.git"
    regex(/bazzite-v?(\d{4}-\d{2}-\d{2})/)
    strategy :github_releases
  end

  postflight do
    destination_dir = "#{Dir.home}/.local/share/backgrounds/bazzite"
    kde_destination_dir = "#{Dir.home}/.local/share/backgrounds/bazzite"

    # Process XML files first
    Dir.glob("#{staged_path}/**/*.xml").each do |file|
      contents = File.read(file)
      contents.gsub!("~", Dir.home)
      File.write(file, contents)
    end

    if File.exist?("/usr/bin/plasmashell")
      FileUtils.mkdir_p(kde_destination_dir)
      Dir.glob("#{staged_path}/*").each do |file|
        FileUtils.cp_r(file, "#{kde_destination_dir}/#{File.basename(file)}", remove_destination: true)
      end
    else
      FileUtils.mkdir_p(destination_dir)
      FileUtils.mkdir_p("#{Dir.home}/.local/share/gnome-background-properties")

      Dir.glob("#{staged_path}/images/*").each do |file|
        FileUtils.cp(file, "#{destination_dir}/#{File.basename(file)}")
      end

      Dir.glob("#{staged_path}/gnome-background-properties/*").each do |file|
        FileUtils.cp(file, "#{Dir.home}/.local/share/gnome-background-properties/#{File.basename(file)}")
      end
    end
  end

  uninstall_postflight do
    destination_dir = "#{Dir.home}/.local/share/backgrounds/bazzite"

    FileUtils.rm_rf(destination_dir) if File.exist?(destination_dir)

    gnome_props_dir = "#{Dir.home}/.local/share/gnome-background-properties"
    Dir.glob("#{gnome_props_dir}/bazzite-*.xml").each do |file|
      FileUtils.rm(file) if File.exist?(file)
    end
  end
end
