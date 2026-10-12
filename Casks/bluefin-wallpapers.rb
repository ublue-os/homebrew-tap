cask "bluefin-wallpapers" do
  os macos: "darwin", linux: "linux"

  version "2026-10-12"

  on_macos do
    sha256 "afafb174f8d16b374ed1bf467b0c688f2e27fd49c44c5e4aba743c36b2b5fa1a"

    url "https://github.com/ublue-os/artwork/releases/download/bluefin-v#{version}/bluefin-wallpapers-macos.tar.zstd"
  end
  on_linux do
    if File.exist?("/usr/bin/plasmashell")
      url "https://github.com/ublue-os/artwork/releases/download/bluefin-v#{version}/bluefin-wallpapers-kde.tar.zstd"
      sha256 "07fd86ac83115ab413cc7334d31112ce16ab4c3d51e3199c39dac7246012cc47"

    elsif File.exist?("/usr/bin/gnome-shell") || File.exist?("/usr/bin/mutter")
      url "https://github.com/ublue-os/artwork/releases/download/bluefin-v#{version}/bluefin-wallpapers-gnome.tar.zstd"
      sha256 "c6cd3fb5c6f14472b0ced070d2d9f5ac374197305feb81ab4026cae22d2d1eb5"

    else
      url "https://github.com/ublue-os/artwork/releases/download/bluefin-v#{version}/bluefin-wallpapers-png.tar.zstd"
      sha256 "28617c0843753c26a98adf08c1b2f9779a7ce397d1d9beee1ed115b82d409cfa"

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
    on_linux do
      symlink ".", ".user-home", source_base: :home, overwrite: true
      run "/bin/sh", args: ["-eu", "-c", <<~'SH'], chdir: "{{staged_path}}"
        WALLPAPER_HOME=$(readlink .user-home)
        replacement=$(printf '%s' "$WALLPAPER_HOME" | sed 's/[\\&|]/\\&/g')
        find . -type f -name '*.xml' -exec sed -i.brew-home-backup "s|~|$replacement|g" {} +
        find . -type f -name '*.xml.brew-home-backup' -delete
      SH
    end
  end

  postflight_steps do
    on_macos do
      mkdir_p "Library/Desktop Pictures/Bluefin", base: :home
      symlink "*", "Library/Desktop Pictures/Bluefin", target_base: :home, source_glob: true, overwrite: true
    end
    on_linux do
      mkdir_p ".local/share/backgrounds/bluefin", base: :home
      mkdir_p ".local/share/wallpapers/bluefin", base: :home
      mkdir_p ".local/share/gnome-background-properties", base: :home
      run "/bin/bash", chdir: "{{staged_path}}",
                       env: { "WALLPAPER_HOME" => "{{staged_path}}/.user-home" },
                       writable_paths: [".local/share/backgrounds/bluefin", ".local/share/wallpapers/bluefin",
                                        ".local/share/gnome-background-properties"], writable_base: :home,
                       args: ["-eu", "-c", <<~SH]
                         shopt -s nullglob
                         destination="$WALLPAPER_HOME/.local/share/backgrounds/bluefin"
                         if [ -e /usr/bin/plasmashell ]; then
                           destination="$WALLPAPER_HOME/.local/share/wallpapers/bluefin"
                           for file in "$PWD"/*; do ln -sfn "$file" "$destination/$(basename "$file")"; done
                         elif [ -e /usr/bin/gnome-shell ] || [ -e /usr/bin/mutter ]; then
                           for file in "$PWD"/*; do
                             if [ -f "$file" ]; then ln -sfn "$file" "$destination/$(basename "$file")"; fi
                           done
                           for file in "$PWD"/gnome-background-properties/*; do
                             ln -sfn "$file" "$WALLPAPER_HOME/.local/share/gnome-background-properties/$(basename "$file")"
                           done
                         else
                           for file in "$PWD"/*; do ln -sfn "$file" "$destination/$(basename "$file")"; done
                         fi
                       SH
    end
  end

  uninstall_postflight_steps do
    on_macos do
      remove "Library/Desktop Pictures/Bluefin/*", base: :home, symlink_target_contains: "/bluefin-wallpapers/"
    end
    on_linux do
      remove [".local/share/backgrounds/bluefin/**/*", ".local/share/wallpapers/bluefin/**/*",
              ".local/share/gnome-background-properties/*.xml"],
             base: :home, symlink_target_contains: "/bluefin-wallpapers/"
    end
  end

  caveats <<~EOS
    On macOS, add ~/Library/Desktop Pictures/Bluefin in System Settings > Wallpaper > Add Folder.
  EOS
end
