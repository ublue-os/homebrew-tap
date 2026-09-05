cask "bluefin-wallpapers" do
  os macos: "darwin", linux: "linux"

  version "2026-08-21"

  on_macos do
    sha256 "afafb174f8d16b374ed1bf467b0c688f2e27fd49c44c5e4aba743c36b2b5fa1a"

    url "https://github.com/ublue-os/artwork/releases/download/bluefin-v#{version}/bluefin-wallpapers-macos.tar.zstd"

    Dir.glob("#{staged_path}/*").each do |file|
      artifact file, target: "#{Dir.home}/Library/Desktop Pictures/Bluefin/#{File.basename(file)}"
    end
  end
  on_linux do
    destination_dir = "#{Dir.home}/.local/share/backgrounds/bluefin"
    kde_destination_dir = "#{Dir.home}/.local/share/wallpapers/bluefin"

    if File.exist?("/usr/bin/plasmashell")
      url "https://github.com/ublue-os/artwork/releases/download/bluefin-v#{version}/bluefin-wallpapers-kde.tar.zstd"
      sha256 "d1c3b022e5ff0532e2727de76bc9bc8fb2efb74c6201c4d1cda55dbbc3826be9"

      Dir.glob("#{staged_path}/*").each do |file|
        artifact file, target: "#{kde_destination_dir}/#{File.basename(file)}"
      end
    elsif File.exist?("/usr/bin/gnome-shell") || File.exist?("/usr/bin/mutter")
      url "https://github.com/ublue-os/artwork/releases/download/bluefin-v#{version}/bluefin-wallpapers-gnome.tar.zstd"
      sha256 "b3c5332f28c06265aa39284c0e1fad5ec970860d06737ebae24072a17cb52bf4"

      Dir.glob("#{staged_path}/*").select { |f| File.file?(f) }.each do |file|
        artifact file, target: "#{destination_dir}/#{File.basename(file)}"
      end

      Dir.glob("#{staged_path}/gnome-background-properties/*").each do |file|
        artifact file, target: "#{Dir.home}/.local/share/gnome-background-properties/#{File.basename(file)}"
      end
    else
      url "https://github.com/ublue-os/artwork/releases/download/bluefin-v#{version}/bluefin-wallpapers-png.tar.zstd"
      sha256 "52cce2d24ef1df7978b432c5f248322af27b416efa334e854f57fc9f99decb51"

      Dir.glob("#{staged_path}/*").each do |file|
        artifact file, target: "#{destination_dir}/#{File.basename(file)}"
      end
    end
  end

  name "bluefin-wallpapers"
  desc "Wallpapers for Bluefin"
  homepage "https://github.com/projectbluefin/artwork"

  livecheck do
    url "https://github.com/ublue-os/artwork.git"
    regex(/bluefin-v?(\d{4}-\d{2}-\d{2})/)
    strategy :github_releases
  end

  preflight_steps do
    on_macos do
      mkdir_p "Library/Desktop Pictures/Bluefin", base: :home
    end

    on_linux do
      mkdir_p ".local/share/backgrounds/bluefin", base: :home
      mkdir_p ".local/share/wallpapers/bluefin", base: :home
      mkdir_p ".local/share/gnome-background-properties", base: :home
      inreplace "**/*.xml", "~", "{{home}}", audit_result: false
    end
  end

  caveats do
    if OS.mac?
      <<~EOS
        Wallpapers installed to: #{Dir.home}/Library/Desktop Pictures/Bluefin
        To use: System Settings > Wallpaper > Add Folder
      EOS
    end
  end
end
