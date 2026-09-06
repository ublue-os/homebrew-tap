cask "framework-wallpapers" do
  os macos: "darwin", linux: "linux"

  version "2025-12-14"

  on_macos do
    sha256 "e3afcfdbb919d84e02b0f99c2e450514db347bd4e7dd37e9fa23fdb72d321841"

    url "https://github.com/ublue-os/artwork/releases/download/framework-v#{version}/framework-wallpapers-macos.tar.zstd"
  end
  on_linux do
    if File.exist?("/usr/bin/plasmashell")
      url "https://github.com/ublue-os/artwork/releases/download/framework-v#{version}/framework-wallpapers-kde.tar.zstd"
      sha256 "2616c84b94bb3e83bf0576bbb260f2a5f98c06674b69e14db335e79d7e3b03a1"
    elsif File.exist?("/usr/bin/gnome-shell") || File.exist?("/usr/bin/mutter")
      url "https://github.com/ublue-os/artwork/releases/download/framework-v#{version}/framework-wallpapers-gnome.tar.zstd"
      sha256 "8affb9c512d39fc0c665608939815e1eab7062bf1a01c3deab23de367216efc9"
    else
      url "https://github.com/ublue-os/artwork/releases/download/framework-v#{version}/framework-wallpapers-png.tar.zstd"
      sha256 "2da39f34cb2131861da2adca1d03a6b25b0714b2e7d2686b4d14f7ed8c60e8eb"
    end
  end

  name "framework-wallpapers"
  desc "Wallpapers for Framework laptops"
  homepage "https://github.com/projectbluefin/artwork"

  livecheck do
    url "https://github.com/ublue-os/artwork.git"
    regex(/framework-v?(\d{4}-\d{2}-\d{2})/)
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
      mkdir_p "Library/Desktop Pictures/Framework", base: :home
      symlink "*", "Library/Desktop Pictures/Framework", target_base: :home, source_glob: true, overwrite: true
    end
    on_linux do
      mkdir_p ".local/share/backgrounds/framework", base: :home
      mkdir_p ".local/share/wallpapers/framework", base: :home
      mkdir_p ".local/share/gnome-background-properties", base: :home
      run "/bin/bash", chdir: "{{staged_path}}",
                       env: { "WALLPAPER_HOME" => "{{staged_path}}/.user-home" },
                       writable_paths: [".local/share/backgrounds/framework", ".local/share/wallpapers/framework",
                                        ".local/share/gnome-background-properties"], writable_base: :home,
                       args: ["-eu", "-c", <<~SH]
                         shopt -s nullglob
                         destination="$WALLPAPER_HOME/.local/share/backgrounds/framework"
                         if [ -e /usr/bin/plasmashell ]; then
                           destination="$WALLPAPER_HOME/.local/share/wallpapers/framework"
                           for file in "$PWD"/*; do ln -sfn "$file" "$destination/$(basename "$file")"; done
                         elif [ -e /usr/bin/gnome-shell ] || [ -e /usr/bin/mutter ]; then
                           for file in "$PWD"/images/*; do ln -sfn "$file" "$destination/$(basename "$file")"; done
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
      remove "Library/Desktop Pictures/Framework/*", base: :home, symlink_target_contains: "/framework-wallpapers/"
    end
    on_linux do
      remove [".local/share/backgrounds/framework/**/*", ".local/share/wallpapers/framework/**/*",
              ".local/share/gnome-background-properties/*.xml"],
             base: :home, symlink_target_contains: "/framework-wallpapers/"
    end
  end

  zap trash: [
    "#{Dir.home}/.local/share/backgrounds/framework",
    "#{Dir.home}/.local/share/gnome-background-properties/framework-*.xml",
    "#{Dir.home}/.local/share/wallpapers/framework",
    "#{Dir.home}/Library/Desktop Pictures/Framework",
  ]
end
