cask "chairlift" do
  arch arm: "arm64", intel: "amd64"

  version "26.09.0-alpha.2"
  sha256 arm:          "cb64663a0e2ae87b049bacd431de9d9c1925833006559c8310f8bd53ec938a86",
         intel:        "18f630bb7de0e921ba12ae8c0650adf5e550b0cde203938d73d534382f196d08",
         arm64_linux:  "cb64663a0e2ae87b049bacd431de9d9c1925833006559c8310f8bd53ec938a86",
         x86_64_linux: "18f630bb7de0e921ba12ae8c0650adf5e550b0cde203938d73d534382f196d08"

  url "https://github.com/projectbluefin/chairlift/releases/download/v#{version}/chairlift_#{version}_linux_#{arch}.tar.gz"
  name "ChairLift"
  desc "System management tool for bootc-based installations"
  homepage "https://github.com/projectbluefin/chairlift"

  livecheck do
    url :url
    strategy :github_releases do |releases|
      releases.filter_map do |release|
        next if release["draft"]

        release["tag_name"]&.delete_prefix("v")
      end
    end
  end

  depends_on :linux

  binary "chairlift"
  binary "data/chairlift-wrapper.sh", target: "chairlift-wrapper"

  preflight_steps do
    # Menu launches need the brew environment even when the session PATH lacks it.
    inreplace "data/chairlift-wrapper.sh", "/home/linuxbrew/.linuxbrew/bin/brew", "{{HOMEBREW_PREFIX}}/bin/brew"
    inreplace "data/chairlift-wrapper.sh", "$BREW_PATH shellenv", "\"$BREW_PATH\" shellenv bash"
    inreplace "data/chairlift-wrapper.sh", "exec chairlift", "exec \"{{HOMEBREW_PREFIX}}/bin/chairlift\""
    inreplace "data/io.projectbluefin.chairlift.desktop", "Exec=chairlift-wrapper",
              "Exec=\"{{HOMEBREW_PREFIX}}/bin/chairlift-wrapper\""
  end

  postflight_steps do
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons/hicolor/scalable/apps", base: :home
    mkdir_p ".local/share/icons/hicolor/symbolic/apps", base: :home
    copy "data/io.projectbluefin.chairlift.desktop", ".local/share/applications/io.projectbluefin.chairlift.desktop",
         target_base: :home
    copy "data/icons/hicolor/scalable/apps/io.projectbluefin.chairlift.svg",
         ".local/share/icons/hicolor/scalable/apps/io.projectbluefin.chairlift.svg", target_base: :home
    copy "data/icons/hicolor/symbolic/apps/io.projectbluefin.chairlift-symbolic.svg",
         ".local/share/icons/hicolor/symbolic/apps/io.projectbluefin.chairlift-symbolic.svg", target_base: :home
    # GSettings schemas for the Livery, Updates and First-Run settings. Without
    # a compiled cache in a directory GSettings searches, the Livery page reports
    # its settings unavailable, update preferences never persist, and setup
    # choices are never recorded. The user data dir is searched by GLib and needs
    # no root; HOMEBREW_PREFIX/share is not on XDG_DATA_DIRS for desktop launches.
    mkdir_p ".local/share/glib-2.0/schemas", base: :home
    copy "data/io.projectbluefin.chairlift.livery.gschema.xml",
         ".local/share/glib-2.0/schemas/io.projectbluefin.chairlift.livery.gschema.xml", target_base: :home
    copy "data/io.projectbluefin.chairlift.updates.gschema.xml",
         ".local/share/glib-2.0/schemas/io.projectbluefin.chairlift.updates.gschema.xml", target_base: :home
    copy "data/io.projectbluefin.chairlift.firstrun.gschema.xml",
         ".local/share/glib-2.0/schemas/io.projectbluefin.chairlift.firstrun.gschema.xml", target_base: :home
    symlink ".", ".user-home", source_base: :home, overwrite: true
    run "/usr/bin/glib-compile-schemas", chdir:          "{{staged_path}}",
                                         writable_paths: [".local/share/glib-2.0/schemas"],
                                         writable_base:  :home,
                                         args:           [".user-home/.local/share/glib-2.0/schemas"]
  end

  uninstall_postflight_steps do
    remove [".local/share/applications/io.projectbluefin.chairlift.desktop",
            ".local/share/icons/hicolor/scalable/apps/io.projectbluefin.chairlift.svg",
            ".local/share/icons/hicolor/symbolic/apps/io.projectbluefin.chairlift-symbolic.svg",
            ".local/share/glib-2.0/schemas/io.projectbluefin.chairlift.livery.gschema.xml",
            ".local/share/glib-2.0/schemas/io.projectbluefin.chairlift.updates.gschema.xml",
            ".local/share/glib-2.0/schemas/io.projectbluefin.chairlift.firstrun.gschema.xml"], base: :home
    # Recompile what other applications left in the directory, or drop the
    # cache if ChairLift's schemas were the only ones.
    # Homebrew runs steps with its own HOME, so the user's home is reached
    # through the .user-home link the install step left in the staged path.
    symlink ".", ".user-home", source_base: :home, overwrite: true
    run "/bin/sh", chdir: "{{staged_path}}", writable_paths: [".local/share/glib-2.0/schemas"],
                   writable_base: :home, args: ["-eu", "-c", <<~SH]
                     dir=".user-home/.local/share/glib-2.0/schemas"
                     [ -d "$dir" ] || exit 0
                     if ls "$dir"/*.gschema.xml >/dev/null 2>&1; then
                       /usr/bin/glib-compile-schemas "$dir"
                     else
                       rm -f "$dir/gschemas.compiled"
                     fi
                   SH
  end

  # Never link privileged helpers or install PolicyKit policies from a user-writable cask.
  caveats <<~EOS
    ChairLift requires GTK 4 and libadwaita 1 shared libraries from your OS.

    Privileged features require the matching projectbluefin-chairlift-system-integration
    package from https://github.com/projectbluefin/chairlift/releases installed by your
    OS administrator or included in your OS image. This cask installs only the GUI
    and desktop assets, not the root-owned helpers or PolicyKit policies.
    Bootc staging additionally requires /usr/libexec/bootc-update-stage from your OS.

    Distribution configuration belongs in /etc/chairlift/config.yml; this cask
    does not overwrite it. Upstream's bundled defaults target Snow Linux.

    If the launcher or icons need refreshing after installation or removal, run:
      gtk-update-icon-cache ~/.local/share/icons/hicolor -f -t
      update-desktop-database ~/.local/share/applications
  EOS
end
