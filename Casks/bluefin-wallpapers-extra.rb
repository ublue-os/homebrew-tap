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
      mkdir_p "Library/Desktop Pictures/Bluefin-Extra", base: :home
      symlink "*", "Library/Desktop Pictures/Bluefin-Extra", target_base: :home, source_glob: true, overwrite: true
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
                           for file in "$PWD"/images/*; do
                             filename=$(basename "$file")
                             folder=${filename%.*}
                             folder=${folder//-night/}
                             folder=${folder//-day/}
                             mkdir -p "$destination/$folder"
                             ln -sfn "$file" "$destination/$folder/$filename"
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
      remove "Library/Desktop Pictures/Bluefin-Extra/*", base:                    :home,
                                                         symlink_target_contains: "/bluefin-wallpapers-extra/"
    end
    on_linux do
      # The main and extra casks share destinations; never remove the other cask's links.
      remove [".local/share/backgrounds/bluefin/**/*", ".local/share/wallpapers/bluefin/**/*",
              ".local/share/gnome-background-properties/*.xml"],
             base: :home, symlink_target_contains: "/bluefin-wallpapers-extra/"
    end
  end

  zap trash: [
    "#{Dir.home}/.local/share/backgrounds/bluefin",
    "#{Dir.home}/.local/share/gnome-background-properties/bluefin-*.xml",
    "#{Dir.home}/.local/share/wallpapers/bluefin",
    "#{Dir.home}/Library/Desktop Pictures/Bluefin-Extra",
  ]
end
