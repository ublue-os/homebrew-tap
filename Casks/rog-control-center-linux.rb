cask "rog-control-center-linux" do
  arch arm: "arm64", intel: "amd64"
  os linux: "linux"

  version "6.3.8,3"
  sha256 arm:          "66b7e0c8c358ad2281c806240a410be1c0e61c3c182b05408490f92de779bb9d",
         intel:        "f05fbc48e5971649685d9269a4e7d6c835e3163e8946c4a3cebc49a5cc647cc5",
         arm64_linux:  "66b7e0c8c358ad2281c806240a410be1c0e61c3c182b05408490f92de779bb9d",
         x86_64_linux: "f05fbc48e5971649685d9269a4e7d6c835e3163e8946c4a3cebc49a5cc647cc5"

  release_tag = "asusctl-#{version.csv.first}-#{version.csv.second}"
  release_root = "asusctl-#{version.csv.first}-ubuntu-22.04-#{arch}"

  url "https://github.com/daegalus/linux-app-builds/releases/download/#{release_tag}/#{release_root}.tar.gz"
  name "ROG Control Center"
  desc "ASUS ROG Control Center GUI and user daemon with XDG-first installation"
  homepage "https://gitlab.com/asus-linux/asusctl"

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
  end

  postflight_steps do
    symlink ".", ".user-home", source_base: :home, overwrite: true
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons/hicolor/512x512/apps", base: :home
    mkdir_p ".local/share/icons/hicolor/scalable/status", base: :home
    mkdir_p ".local/share/asusd", base: :home
    mkdir_p ".local/share/rog-gui", base: :home
    mkdir_p ".config/systemd/user", base: :home
    mkdir_p ".config/asusd", base: :home
    copy "asusctl/usr/share/asusd/.", ".local/share/asusd", target_base: :home, recursive: true
    copy "asusctl/usr/share/rog-gui/.", ".local/share/rog-gui", target_base: :home, recursive: true
    copy "asusctl/usr/share/icons/hicolor/512x512/apps/*.png", ".local/share/icons/hicolor/512x512/apps",
         target_base: :home, source_glob: true
    copy "asusctl/usr/share/icons/hicolor/scalable/status/*.svg", ".local/share/icons/hicolor/scalable/status",
         target_base: :home, source_glob: true
    copy "asusctl/usr/share/applications/rog-control-center.desktop",
         ".local/share/applications/rog-control-center.desktop", target_base: :home
    inreplace ".local/share/applications/rog-control-center.desktop", /^Exec=.*/,
              "Exec={{HOMEBREW_PREFIX}}/bin/rog-control-center", base: :home
    copy "asusctl/usr/lib/systemd/user/asusd-user.service", ".config/systemd/user/asusd-user.service",
         target_base: :home
    inreplace ".config/systemd/user/asusd-user.service", "Environment=ASUSD_USER_EXEC=/usr/bin/asusd-user\n", "",
              base: :home, audit_result: false
    inreplace ".config/systemd/user/asusd-user.service", "ExecStart=${ASUSD_USER_EXEC}",
              "ExecStart={{HOMEBREW_PREFIX}}/bin/asusd-user", base: :home
    run "/bin/sh", chdir: "{{staged_path}}", writable_paths: [".config/asusd"], writable_base: :home,
                   args: ["-eu", "-c", <<~SH]
                     user_home=$(readlink .user-home)
                     printf '%s\\n' "ASUSD_DATA_DIR=$user_home/.local/share/asusd" \
                       "ROG_GUI_DATA_DIR=$user_home/.local/share/rog-gui" \
                       "ROG_GUI_LAYOUTS_DIR=$user_home/.local/share/rog-gui/layouts" \
                       "ASUSCTL_AURA_SUPPORT_PATH=$user_home/.local/share/asusd/aura_support.ron" \
                       "ASUSCTL_DATA_DIRS=$user_home/.local/share" > .user-home/.config/asusd/asusd-user.env
                   SH
    run "gtk-update-icon-cache", args: ["{{staged_path}}/.user-home/.local/share/icons/hicolor", "-f", "-t"],
                                 must_succeed: false,
                                 writable_paths: [".local/share/icons/hicolor"], writable_base: :home
    run "update-desktop-database", args: ["{{staged_path}}/.user-home/.local/share/applications"],
                                   must_succeed: false,
                                   writable_paths: [".local/share/applications"], writable_base: :home
  end

  uninstall_postflight_steps do
    symlink ".", ".user-home", source_base: :home, overwrite: true
    run "systemctl", args: ["--user", "disable", "--now", "asusd-user.service"], must_succeed: false,
                     writable_paths: [".config/systemd/user"], writable_base: :home
    remove [".config/systemd/user/asusd-user.service", ".local/share/applications/rog-control-center.desktop",
            ".config/asusd/asusd-user.env"], base: :home
    remove [".local/share/icons/hicolor/512x512/apps/asus_notif_{blue,green,orange,red,white,yellow}.png",
            ".local/share/icons/hicolor/512x512/apps/rog-control-center.png",
            ".local/share/icons/hicolor/scalable/status/gpu-{compute,hybrid,integrated,nvidia,vfio}.svg",
            ".local/share/icons/hicolor/scalable/status/notification-reboot.svg"], base: :home
    run "/bin/rmdir", args: ["{{staged_path}}/.user-home/.config/asusd"], must_succeed: false, print_stderr: false,
                      writable_paths: [".config/asusd"], writable_base: :home
    run "gtk-update-icon-cache", args: ["{{staged_path}}/.user-home/.local/share/icons/hicolor", "-f", "-t"],
                                 must_succeed: false,
                                 writable_paths: [".local/share/icons/hicolor"], writable_base: :home
    run "update-desktop-database", args: ["{{staged_path}}/.user-home/.local/share/applications"],
                                   must_succeed: false,
                                   writable_paths: [".local/share/applications"], writable_base: :home
  end

  zap trash: [
    "~/.config/asusd",
    "~/.config/rog",
    "~/.local/share/asusd",
    "~/.local/share/rog-gui",
  ]

  caveats <<~EOS
    User-facing files were installed to:
      ~/.local/share/applications/rog-control-center.desktop
      ~/.local/share/icons/hicolor
      ~/.local/share/asusd
      ~/.local/share/rog-gui
      ~/.config/systemd/user/asusd-user.service
      ~/.config/asusd/asusd-user.env

    This cask expects the root daemon from:
      brew install --cask asusctl-linux

    After the system daemon is installed and running, enable the user daemon:
      systemctl --user daemon-reload
      systemctl --user enable --now asusd-user.service
  EOS
end
