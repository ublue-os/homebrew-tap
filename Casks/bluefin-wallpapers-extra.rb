cask "bluefin-wallpapers-extra" do
  version "2025-11-30"

  name "bluefin-wallpapers-extra"
  desc "Extra Wallpapers for Bluefin"
  homepage "https://github.com/ublue-os/artwork"

  livecheck do
    url "https://github.com/ublue-os/artwork.git"
    regex(/bluefin-extra-v?(\d{4}-\d{2}-\d{2})/)
    strategy :github_releases
  end

  destination_dir = "#{Dir.home}/.local/share/backgrounds/bluefin"
  kde_destination_dir = "#{Dir.home}/.local/share/wallpapers/bluefin"

  if File.exist?("/usr/bin/plasmashell")
    url "https://github.com/ublue-os/artwork/releases/download/bluefin-extra-v#{version}/bluefin-wallpapers-extra-kde.tar.zstd"
    sha256 "84f714825d61a0518421314b1afb3b7fcb19c7f5c213a06f5f8928a15be54a1c"
  elsif File.exist?("/usr/bin/gnome-shell") || File.exist?("/usr/bin/mutter")
    url "https://github.com/ublue-os/artwork/releases/download/bluefin-extra-v#{version}/bluefin-wallpapers-extra-gnome.tar.zstd"
    sha256 "98b8a10a31f571a791f806a96d5f40287169d6fae223d5ae53dae065d377a4d6"
  else
    url "https://github.com/ublue-os/artwork/releases/download/bluefin-extra-v#{version}/bluefin-wallpapers-extra-png.tar.zstd"
    sha256 "e8c5b8fdfa2d4cc7614a6892ba0809215aa8e6273c501d2e18d2fcbe126b85e8"
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
      FileUtils.mkdir_p("#{Dir.home}/.local/share/gnome-background-properties")

      Dir.glob("#{staged_path}/images/*").each do |file|
        folder = File.basename(file, File.extname(file)).gsub(/-night|-day/, "")
        target_dir = "#{destination_dir}/#{folder}"
        FileUtils.mkdir_p(target_dir)
        FileUtils.cp(file, "#{target_dir}/#{File.basename(file)}")
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
    Dir.glob("#{gnome_props_dir}/bluefin-extra-*.xml").each do |file|
      FileUtils.rm(file) if File.exist?(file)
    end
  end
end
