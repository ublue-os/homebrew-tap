cask "framework-wallpapers" do
  version "2025-11-29"

  name "framework-wallpapers"
  desc "Extra Wallpapers for Bluefin"
  homepage "https://github.com/projectbluefin/artwork"

  livecheck do
    url "https://github.com/ublue-os/artwork.git"
    regex(/framework-v?(\d{4}-\d{2}-\d{2})/)
    strategy :github_releases
  end

  destination_dir = "#{Dir.home}/.local/share/backgrounds/framework"
  kde_destination_dir = "#{Dir.home}/.local/share/wallpapers/framework"

  if File.exist?("/usr/bin/plasmashell")
    url "https://github.com/ublue-os/artwork/releases/download/framework-v#{version}/framework-wallpapers-kde.tar.zstd"
    sha256 "904d5116a7f397733d4e8602e7184bb063f3ab12df241a819187a1c5e8e4eb99"

    Dir.glob("#{staged_path}/*").each do |file|
      artifact file, target: "#{kde_destination_dir}/#{File.basename(file)}"
    end
  elsif File.exist?("/usr/bin/gnome-shell") || File.exist?("/usr/bin/mutter")
    url "https://github.com/ublue-os/artwork/releases/download/framework-v#{version}/framework-wallpapers-gnome.tar.zstd"
    sha256 "b6666aeae2f5e2ac3248243d2ed04d823379abd70df39fc3e5550479b586724b"

    Dir.glob("#{staged_path}/images/*").each do |file|
      artifact file, target: "#{destination_dir}/#{File.basename(file)}"
    end

    Dir.glob("#{staged_path}/gnome-background-properties/*").each do |file|
      artifact file, target: "#{Dir.home}/.local/share/gnome-background-properties/#{File.basename(file)}"
    end
  else
    url "https://github.com/ublue-os/artwork/releases/download/framework-v#{version}/framework-wallpapers-png.tar.zstd"
    sha256 "f5dc915a4acbd796aa426f5f37fa5fc143d735cc16db08a34bbd4f36a75447a2"

    Dir.glob("#{staged_path}/*").each do |file|
      artifact file, target: "#{destination_dir}/#{File.basename(file)}"
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
