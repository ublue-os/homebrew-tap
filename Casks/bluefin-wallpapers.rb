cask "bluefin-wallpapers" do
  version "2025-11-30"

  name "bluefin-wallpapers"
  desc "Wallpapers for Bluefin"
  homepage "https://github.com/projectbluefin/artwork"

  livecheck do
    url "https://github.com/ublue-os/artwork.git"
    regex(/bluefin-v?(\d{4}-\d{2}-\d{2})/)
    strategy :github_releases
  end

  destination_dir = "#{Dir.home}/.local/share/backgrounds/bluefin"
  kde_destination_dir = "#{Dir.home}/.local/share/wallpapers/bluefin"

  if File.exist?("/usr/bin/plasmashell")
    url "https://github.com/ublue-os/artwork/releases/download/bluefin-v#{version}/bluefin-wallpapers-kde.tar.zstd"
    sha256 "d0c57affa270d6a8846f067341d69073c8469f8f97c2e60fbb7b51153483403e"
  elsif File.exist?("/usr/bin/gnome-shell") || File.exist?("/usr/bin/mutter")
    url "https://github.com/ublue-os/artwork/releases/download/bluefin-v#{version}/bluefin-wallpapers-gnome.tar.zstd"
    sha256 "b3aa0df9e6ba7380a797779e14ca58abd6c3d95a7e5e75f6e39a052494f792f1"
  else
    url "https://github.com/ublue-os/artwork/releases/download/bluefin-v#{version}/bluefin-wallpapers-png.tar.zstd"
    sha256 "078c2e259055ea220045e1aea84a13d7a7a68c5ab05dbcfe928501b0a98d625c"
  end

  postflight do
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
    elsif File.exist?("/usr/bin/gnome-shell") || File.exist?("/usr/bin/mutter")
      FileUtils.mkdir_p(destination_dir)
      FileUtils.mkdir_p("#{Dir.home}/.local/share/gnome-background-properties")

      Dir.glob("#{staged_path}/images/*").each do |file|
        FileUtils.cp(file, "#{destination_dir}/#{File.basename(file)}")
      end

      Dir.glob("#{staged_path}/gnome-background-properties/*").each do |file|
        FileUtils.cp(file, "#{Dir.home}/.local/share/gnome-background-properties/#{File.basename(file)}")
      end
    else
      FileUtils.mkdir_p(destination_dir)
      Dir.glob("#{staged_path}/*").each do |file|
        FileUtils.cp_r(file, "#{destination_dir}/#{File.basename(file)}", remove_destination: true)
      end
    end
  end

  uninstall_postflight do
    if File.exist?("/usr/bin/plasmashell")
      FileUtils.rm_rf(kde_destination_dir) if File.exist?(kde_destination_dir)
    else
      FileUtils.rm_rf(destination_dir) if File.exist?(destination_dir)
    end

    gnome_props_dir = "#{Dir.home}/.local/share/gnome-background-properties"
    Dir.glob("#{gnome_props_dir}/bluefin-*.xml").each do |file|
      FileUtils.rm(file) if File.exist?(file)
    end
  end
end
