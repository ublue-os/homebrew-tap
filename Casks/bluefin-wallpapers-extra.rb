cask "bluefin-wallpapers-extra" do
  os macos: "darwin", linux: "linux"

  version "2026-05-09"

  on_macos do
    sha256 "619dc6807432318f0ce5316d77f77bd6cd4549a1c9509bdba10074f71b742ff2"

    url "https://github.com/ublue-os/artwork/releases/download/bluefin-extra-v#{version}/bluefin-wallpapers-extra-macos.tar.zstd"
  end
  on_linux do
    if File.exist?("/usr/bin/plasmashell")
      url "https://github.com/ublue-os/artwork/releases/download/bluefin-extra-v#{version}/bluefin-wallpapers-extra-kde.tar.zstd"
      sha256 "0f690073b3d681da24eb9a349ea33669863d4220733c1997577f705aaa43ee70"
    elsif File.exist?("/usr/bin/gnome-shell") || File.exist?("/usr/bin/mutter")
      url "https://github.com/ublue-os/artwork/releases/download/bluefin-extra-v#{version}/bluefin-wallpapers-extra-gnome.tar.zstd"
      sha256 "73a5e034577a665e56be0e8fe0d54f9fdbd7f61096bf4fa638cede41c07aa2e4"
    else
      url "https://github.com/ublue-os/artwork/releases/download/bluefin-extra-v#{version}/bluefin-wallpapers-extra-png.tar.zstd"
      sha256 "dafdb5e47d0a967b7bcfaeabe4afda0d75575fd7ef28b8120c924fc19c53f02c"
    end
  end

  name "bluefin-wallpapers-extra"
  desc "Extra Wallpapers for Bluefin"
  homepage "https://github.com/ublue-os/artwork"

  livecheck do
    url "https://github.com/ublue-os/artwork.git"
    regex(/bluefin-extra-v?(\d{4}-\d{2}-\d{2})/)
    strategy :github_releases
  end

  preflight_steps do
    on_macos do
      mkdir_p "Library/Desktop Pictures/Bluefin-Extra", base: :home
    end

    on_linux do
      mkdir_p ".local/share/backgrounds/bluefin", base: :home
      mkdir_p ".local/share/wallpapers/bluefin", base: :home
      mkdir_p ".local/share/gnome-background-properties", base: :home
      inreplace "**/*.xml", "~", "{{home}}", audit_result: false
    end
  end

  postflight_steps do
    on_macos do
      run "ruby", args: [
        "-e",
        <<~RUBY,
          staged_path = ARGV[0]
          home = ARGV[1]
          Dir.glob("\#{staged_path}/*").each do |file|
            target = "\#{home}/Library/Desktop Pictures/Bluefin-Extra/\#{File.basename(file)}"
            FileUtils.ln_sf(file, target)
          end
        RUBY
        "{{staged_path}}",
        "{{home}}",
      ]
    end

    on_linux do
      run "ruby", args: [
        "-e",
        <<~RUBY,
          staged_path = ARGV[0]
          home = ARGV[1]
          destination_dir = "\#{home}/.local/share/backgrounds/bluefin"
          kde_destination_dir = "\#{home}/.local/share/wallpapers/bluefin"

          if File.exist?("/usr/bin/plasmashell")
            Dir.glob("\#{staged_path}/*").each do |file|
              target = "\#{kde_destination_dir}/\#{File.basename(file)}"
              FileUtils.ln_sf(file, target)
            end
          elsif File.exist?("/usr/bin/gnome-shell") || File.exist?("/usr/bin/mutter")
            Dir.glob("\#{staged_path}/images/*").each do |file|
              folder = File.basename(file, File.extname(file)).gsub(/-night|-day/, "")
              FileUtils.mkdir_p "\#{destination_dir}/\#{folder}"
              target = "\#{destination_dir}/\#{folder}/\#{File.basename(file)}"
              FileUtils.ln_sf(file, target)
            end

            Dir.glob("\#{staged_path}/gnome-background-properties/*").each do |file|
              target = "\#{home}/.local/share/gnome-background-properties/\#{File.basename(file)}"
              FileUtils.ln_sf(file, target)
            end
          else
            Dir.glob("\#{staged_path}/*").each do |file|
              target = "\#{destination_dir}/\#{File.basename(file)}"
              FileUtils.ln_sf(file, target)
            end
          end
        RUBY
        "{{staged_path}}",
        "{{home}}",
      ]
    end
  end

  uninstall_postflight_steps do
    on_macos do
      remove "Library/Desktop Pictures/Bluefin-Extra", base: :home, recursive: true
    end

    on_linux do
      run "ruby", args: [
        "-e",
        <<~RUBY,
          home = ARGV[0]
          bg_dir    = "\#{home}/.local/share/backgrounds/bluefin"
          kde_dir   = "\#{home}/.local/share/wallpapers/bluefin"
          props_dir = "\#{home}/.local/share/gnome-background-properties"

          # Remove only the symlinks this cask created via postflight. During upgrade,
          # these point to the old staged path (now being removed) and become broken.
          # Symlinks from bluefin-wallpapers point to a separate Caskroom path that is
          # not being removed, so they remain valid and are intentionally left alone.
          [bg_dir, kde_dir].each do |dir|
            next unless Dir.exist?(dir)

            Dir.glob("\#{dir}/**/*").reverse_each do |f|
              File.unlink(f) if File.symlink?(f) && !File.exist?(f)
              next unless File.directory?(f)
              next unless Dir.empty?(f)

              begin
                Dir.rmdir(f)
              rescue
                nil
              end
            end
          end

          if Dir.exist?(props_dir)
            Dir.glob("\#{props_dir}/*.xml").each do |f|
              File.unlink(f) if File.symlink?(f) && !File.exist?(f)
            end
          end
        RUBY
        "{{home}}",
      ]
    end
  end

  zap trash: [
    "#{Dir.home}/.local/share/backgrounds/bluefin",
    "#{Dir.home}/.local/share/gnome-background-properties/bluefin-*.xml",
    "#{Dir.home}/.local/share/wallpapers/bluefin",
    "#{Dir.home}/Library/Desktop Pictures/Bluefin-Extra",
  ]

  caveats do
    if OS.mac?
      <<~EOS
        Wallpapers installed to: #{Dir.home}/Library/Desktop Pictures/Bluefin-Extra
        To use: System Settings > Wallpaper > Add Folder
      EOS
    end
  end
end
