cask "rog-control-center-linux" do
  arch arm: "arm64", intel: "amd64"
  os linux: "linux"

  version "6.5.0,4"
  sha256 arm:          "04b2a6e7a1858d9af33423f67cca335b3b46a89b9a6077c16a3f4f244c0a02d7",
         intel:        "91aa192f9b1861dce9ea3077bd7bf839acf97c5349d26435e699e49785fd21e6",
         arm64_linux:  "04b2a6e7a1858d9af33423f67cca335b3b46a89b9a6077c16a3f4f244c0a02d7",
         x86_64_linux: "91aa192f9b1861dce9ea3077bd7bf839acf97c5349d26435e699e49785fd21e6"

  release_tag = "asusctl-#{version.csv.first}-#{version.csv.second}"
  release_root = "asusctl-#{version.csv.first}-ubuntu-22.04-#{arch}"

  url "https://github.com/daegalus/linux-app-builds/releases/download/#{release_tag}/#{release_root}.tar.gz"
  name "ROG Control Center"
  desc "ASUS ROG Control Center GUI and user daemon with XDG-first installation"
  homepage "https://github.com/OpenGamingCollective/asusctl"

  livecheck do
    url "https://api.github.com/repos/daegalus/linux-app-builds/releases/latest"
    strategy :json do |json|
      tag = json["tag_name"].to_s
      match = tag.match(/^asusctl-(\d+(?:\.\d+)+)-(\d+)$/)
      next if match.nil?

      "#{match[1]},#{match[2]}"
    end
  end

  binary "asusctl/usr/bin/rog-control-center"
  binary "asusctl/usr/bin/asusd-user"

  preflight_steps do
    move "asusctl-*-ubuntu-22.04-*", "asusctl", source_glob: true
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons", base: :home
    mkdir_p ".local/share/asusd", base: :home
    mkdir_p ".local/share/rog-gui", base: :home
    mkdir_p ".local/share/locale", base: :home
    mkdir_p ".local/share/metainfo", base: :home
    mkdir_p ".config/systemd/user", base: :home
    mkdir_p ".config/asusd", base: :home
  end

  postflight_steps do
    symlink ".", ".user-home", source_base: :home, overwrite: true
    copy "asusctl/usr/share/asusd/.", ".local/share/asusd", target_base: :home, recursive: true
    copy "asusctl/usr/share/rog-gui/.", ".local/share/rog-gui", target_base: :home, recursive: true
    copy "asusctl/usr/share/locale/.", ".local/share/locale", target_base: :home, recursive: true
    copy "asusctl/usr/share/metainfo/.", ".local/share/metainfo", target_base: :home, recursive: true
    # Declarative source_glob only accepts one match; these icon sets contain several.
    run "/bin/sh", chdir: "{{staged_path}}",
                   writable_paths: [".local/share/icons"], writable_base: :home,
                   args: ["-eu", "-c", <<~SH]
                     mkdir -p .user-home/.local/share/icons/hicolor/512x512/apps
                     mkdir -p .user-home/.local/share/icons/hicolor/scalable/status
                     for icon in asusctl/usr/share/icons/hicolor/512x512/apps/*.png; do
                       [ -f "$icon" ] || continue
                       cp "$icon" .user-home/.local/share/icons/hicolor/512x512/apps/
                     done
                     for icon in asusctl/usr/share/icons/hicolor/scalable/status/*.svg; do
                       [ -f "$icon" ] || continue
                       cp "$icon" .user-home/.local/share/icons/hicolor/scalable/status/
                     done
                   SH
    # Prepare files in the readable stage, then only write to the user's home.
    run "/bin/sed", args:        ["s|^Exec=.*|Exec={{HOMEBREW_PREFIX}}/bin/rog-control-center|",
                                  "{{staged_path}}/asusctl/usr/share/applications/org.opengamingcollective.rog-control-center.desktop"],
                    stdout_path: "org.opengamingcollective.rog-control-center.desktop"
    copy "org.opengamingcollective.rog-control-center.desktop", ".local/share/applications/org.opengamingcollective.rog-control-center.desktop", target_base: :home
    # Upstream renamed the launcher; drop the legacy name so upgrades do not leave a duplicate.
    run "/bin/rm", args: ["-f", "{{staged_path}}/.user-home/.local/share/applications/rog-control-center.desktop"],
                      must_succeed: false, writable_paths: [".local/share/applications"], writable_base: :home
    run "/bin/sed", args:        ["-e", "/^Environment=ASUSD_USER_EXEC=/d",
                                  "-e",
                                  "s|^ExecStart=.*|ExecStart={{HOMEBREW_PREFIX}}/bin/asusd-user|",
                                  "{{staged_path}}/asusctl/usr/lib/systemd/user/asusd-user.service"],
                    stdout_path: "asusd-user.service"
    copy "asusd-user.service", ".config/systemd/user/asusd-user.service", target_base: :home
    run "/bin/sh", chdir: "{{staged_path}}", writable_paths: [".config/asusd"], writable_base: :home,
                   args: ["-eu", "-c", <<~SH]
                     user_home=$(readlink .user-home)
                     printf '%s\\n' "ASUSD_DATA_DIR=$user_home/.local/share/asusd" \
                       "ROG_GUI_DATA_DIR=$user_home/.local/share/rog-gui" \
                       "ROG_GUI_LAYOUTS_DIR=$user_home/.local/share/rog-gui/layouts" \
                       "ASUSCTL_AURA_SUPPORT_PATH=$user_home/.local/share/asusd/aura_support.ron" \
                       "ASUSCTL_DATA_DIRS=$user_home/.local/share" > .user-home/.config/asusd/asusd-user.env
                   SH
  end

  uninstall_postflight_steps do
    symlink ".", ".user-home", source_base: :home, overwrite: true
    run "systemctl", args: ["--user", "disable", "--now", "asusd-user.service"], must_succeed: false,
                     writable_paths: [".config/systemd/user"], writable_base: :home
    remove [".config/systemd/user/asusd-user.service", ".local/share/applications/org.opengamingcollective.rog-control-center.desktop",
            ".local/share/applications/rog-control-center.desktop",
            ".local/share/metainfo/org.opengamingcollective.rog-control-center.metainfo.xml",
            ".local/share/locale/*/LC_MESSAGES/rog-control-center.mo",
            ".config/asusd/asusd-user.env"], base: :home
    remove [".local/share/icons/hicolor/512x512/apps/asus_notif_{blue,green,orange,red,white,yellow}.png",
            ".local/share/icons/hicolor/512x512/apps/rog-control-center.png",
            ".local/share/icons/hicolor/scalable/status/gpu-{compute,hybrid,integrated,nvidia,vfio}.svg",
            ".local/share/icons/hicolor/scalable/status/notification-reboot.svg"], base: :home
    run "/bin/rmdir", args: ["{{staged_path}}/.user-home/.config/asusd"], must_succeed: false, print_stderr: false,
                      writable_paths: [".config/asusd"], writable_base: :home
  end

  zap trash: [
    "~/.config/asusd",
    "~/.config/rog",
    "~/.local/share/asusd",
    "~/.local/share/rog-gui",
  ]

  caveats <<~EOS
    User-facing files were installed to:
      ~/.local/share/applications/org.opengamingcollective.rog-control-center.desktop
      ~/.local/share/icons/hicolor
      ~/.local/share/asusd
      ~/.local/share/rog-gui
      ~/.local/share/locale
      ~/.local/share/metainfo
      ~/.config/systemd/user/asusd-user.service
      ~/.config/asusd/asusd-user.env

    This cask expects the root daemon from:
      brew install --cask asusctl-linux

    After the system daemon is installed and running, enable the user daemon:
      systemctl --user daemon-reload
      systemctl --user enable --now asusd-user.service

    Shared desktop caches cannot be read inside the cask sandbox. If the launcher
    or icons need refreshing after installation or removal, run:
      gtk-update-icon-cache ~/.local/share/icons/hicolor -f -t
      update-desktop-database ~/.local/share/applications
  EOS
end
