cask "bluefin-wallpapers" do
  os macos: "darwin", linux: "linux"

  version "2026-08-21"

  on_macos do
    sha256 "afafb174f8d16b374ed1bf467b0c688f2e27fd49c44c5e4aba743c36b2b5fa1a"

    url "https://github.com/ublue-os/artwork/releases/download/bluefin-v#{version}/bluefin-wallpapers-macos.tar.zstd"
  end
  on_linux do
    if File.exist?("/usr/bin/plasmashell")
      url "https://github.com/ublue-os/artwork/releases/download/bluefin-v#{version}/bluefin-wallpapers-kde.tar.zstd"
      sha256 "d1c3b022e5ff0532e2727de76bc9bc8fb2efb74c6201c4d1cda55dbbc3826be9"

    elsif File.exist?("/usr/bin/gnome-shell") || File.exist?("/usr/bin/mutter")
      url "https://github.com/ublue-os/artwork/releases/download/bluefin-v#{version}/bluefin-wallpapers-gnome.tar.zstd"
      sha256 "b3c5332f28c06265aa39284c0e1fad5ec970860d06737ebae24072a17cb52bf4"

    else
      url "https://github.com/ublue-os/artwork/releases/download/bluefin-v#{version}/bluefin-wallpapers-png.tar.zstd"
      sha256 "52cce2d24ef1df7978b432c5f248322af27b416efa334e854f57fc9f99decb51"

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
