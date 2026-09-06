cask "aurora-wallpapers" do
  version "2026-04-23"
  sha256 "fd029232de0bc45f327c394ecd00023fe52d30b376fe19046660c82f6f8bdcd7"

  url "https://github.com/ublue-os/artwork/releases/download/aurora-v#{version}/aurora-wallpapers.tar.zstd"
  name "aurora-wallpapers"
  desc "Wallpapers for Aurora"
  homepage "https://github.com/projectbluefin/artwork"

  livecheck do
    url "https://github.com/ublue-os/artwork.git"
    regex(/aurora-v?(\d{4}-\d{2}-\d{2})/)
    strategy :github_releases
  end

  preflight_steps do
    mkdir_p ".local/share/backgrounds/aurora", base: :home
    mkdir_p ".local/share/gnome-background-properties", base: :home
    symlink ".", ".user-home", source_base: :home, overwrite: true
    run "/bin/sh", args: ["-eu", "-c", <<~'SH'], chdir: "{{staged_path}}"
      WALLPAPER_HOME=$(readlink .user-home)
      replacement=$(printf '%s' "$WALLPAPER_HOME" | sed 's/[\\&|]/\\&/g')
      find . -type f -name '*.xml' -exec sed -i.brew-home-backup "s|~|$replacement|g" {} +
      find . -type f -name '*.xml.brew-home-backup' -delete
    SH
  end

  postflight_steps do
    run "/bin/bash", chdir: "{{staged_path}}",
                     env: { "WALLPAPER_HOME" => "{{staged_path}}/.user-home" },
                     writable_paths: [".local/share/backgrounds/aurora", ".local/share/gnome-background-properties"],
                     writable_base: :home, args: ["-eu", "-c", <<~SH]
                       shopt -s nullglob
                       destination="$WALLPAPER_HOME/.local/share/backgrounds/aurora"
                       for directory in "$PWD"/kde/*; do
                         if [ -e /usr/bin/plasmashell ]; then
                           [[ "$directory" != *gnome-background-properties* ]] || continue
                           ln -sfn "$directory" "$destination/$(basename "$directory")"
                         else
                           for file in "$directory"/contents/images/*; do
                             filename=$(basename "$file")
                             ln -sfn "$file" "$destination/$(basename "$directory").${filename##*.}"
                           done
                           for file in "$directory"/gnome-background-properties/*; do
                             ln -sfn "$file" "$WALLPAPER_HOME/.local/share/gnome-background-properties/$(basename "$file")"
                           done
                         fi
                       done
                     SH
  end

  uninstall_postflight_steps do
    remove [".local/share/backgrounds/aurora/**/*", ".local/share/gnome-background-properties/*.xml"],
           base: :home, symlink_target_contains: "/aurora-wallpapers/"
  end

  zap trash: [
    "#{Dir.home}/.local/share/backgrounds/aurora",
    "#{Dir.home}/.local/share/gnome-background-properties/aurora-*.xml",
  ]
end
