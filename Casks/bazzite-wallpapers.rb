cask "bazzite-wallpapers" do
  version "2025-12-14"
  sha256 "21bfa43889d68e4fcbe67b17a2626d5f752138bf751dd67f0c90f4bf820f1374"

  url "https://github.com/ublue-os/artwork/releases/download/bazzite-v#{version}/bazzite-wallpapers.tar.zstd"
  name "bazzite-wallpapers"
  desc "Wallpapers for Bazzite"
  homepage "https://bazzite.gg/"

  livecheck do
    url "https://github.com/ublue-os/artwork.git"
    regex(/bazzite-v?(\d{4}-\d{2}-\d{2})/)
    strategy :github_releases
  end

  preflight_steps do
    symlink ".", ".user-home", source_base: :home, overwrite: true
    run "/bin/sh", args: ["-eu", "-c", <<~'SH'], chdir: "{{staged_path}}"
      WALLPAPER_HOME=$(readlink .user-home)
      replacement=$(printf '%s' "$WALLPAPER_HOME" | sed 's/[\\&|]/\\&/g')
      find . -type f -name '*.xml' -exec sed -i.brew-home-backup "s|~|$replacement|g" {} +
      find . -type f -name '*.xml.brew-home-backup' -delete
    SH
  end

  postflight_steps do
    mkdir_p ".local/share/backgrounds/bazzite", base: :home
    mkdir_p ".local/share/gnome-background-properties", base: :home
    # Discover the payload after extraction, not while loading the cask for CI/API use.
    run "/bin/bash", chdir: "{{staged_path}}",
                     env: { "WALLPAPER_HOME" => "{{staged_path}}/.user-home" },
                     writable_paths: [".local/share/backgrounds/bazzite", ".local/share/gnome-background-properties"],
                     writable_base: :home, args: ["-eu", "-c", <<~SH]
                       shopt -s nullglob
                       destination="$WALLPAPER_HOME/.local/share/backgrounds/bazzite"
                       if [ -e /usr/bin/plasmashell ]; then
                         for file in "$PWD"/*; do ln -sfn "$file" "$destination/$(basename "$file")"; done
                       else
                         for file in "$PWD"/images/*; do ln -sfn "$file" "$destination/$(basename "$file")"; done
                         for file in "$PWD"/gnome-background-properties/*; do
                           ln -sfn "$file" "$WALLPAPER_HOME/.local/share/gnome-background-properties/$(basename "$file")"
                         done
                       fi
                     SH
  end

  uninstall_postflight_steps do
    remove [".local/share/backgrounds/bazzite/**/*", ".local/share/gnome-background-properties/*.xml"],
           base: :home, symlink_target_contains: "/bazzite-wallpapers/"
  end
end
