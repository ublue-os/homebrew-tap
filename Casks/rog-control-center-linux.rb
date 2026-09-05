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

  binary "#{release_root}/usr/bin/rog-control-center"
  binary "#{release_root}/usr/bin/asusd-user"

  postflight_steps do
    run "ruby", args: [
      "-e",
      <<~RUBY,
        require "fileutils"

        staged_path = ARGV[0]
        prefix = ARGV[1]
        home = ARGV[2]

        release_dir = Dir.glob("\#{staged_path}/rog-control-center-*").first || staged_path
        xdg_share = "\#{home}/.local/share"
        xdg_config = "\#{home}/.config"
        applications_dir = "\#{xdg_share}/applications"
        icons_dir = "\#{xdg_share}/icons/hicolor/512x512/apps"
        status_icons_dir = "\#{xdg_share}/icons/hicolor/scalable/status"
        asusd_share_dir = "\#{xdg_share}/asusd"
        rog_gui_share_dir = "\#{xdg_share}/rog-gui"
        systemd_user_dir = "\#{xdg_config}/systemd/user"
        asusd_config_dir = "\#{xdg_config}/asusd"
        asusd_user_service_src = "\#{release_dir}/usr/lib/systemd/user/asusd-user.service"

        icon_cache_cmd = system("which gtk-update-icon-cache > /dev/null 2>&1")
        desktop_db_cmd = system("which update-desktop-database > /dev/null 2>&1")

        FileUtils.mkdir_p(
          [
            applications_dir,
            icons_dir,
            status_icons_dir,
            asusd_share_dir,
            rog_gui_share_dir,
            systemd_user_dir,
            asusd_config_dir,
          ],
        )

        FileUtils.cp_r("\#{release_dir}/usr/share/asusd/.", asusd_share_dir)
        FileUtils.cp_r("\#{release_dir}/usr/share/rog-gui/.", rog_gui_share_dir)
        Dir.glob("\#{release_dir}/usr/share/icons/hicolor/512x512/apps/*.png").each do |icon|
          FileUtils.cp(icon, icons_dir)
        end
        Dir.glob("\#{release_dir}/usr/share/icons/hicolor/scalable/status/*.svg").each do |icon|
          FileUtils.cp(icon, status_icons_dir)
        end

        desktop_file = "\#{release_dir}/usr/share/applications/rog-control-center.desktop"
        if File.exist?(desktop_file)
          desktop_contents = File.read(desktop_file)
          desktop_contents.gsub!(
            /^Exec=.*/,
            "Exec=\#{prefix}/bin/rog-control-center",
          )
          File.write("\#{applications_dir}/rog-control-center.desktop", desktop_contents)
        end

        if File.exist?(asusd_user_service_src)
          asusd_user_service = File.read(asusd_user_service_src)
          asusd_user_service.gsub!("Environment=ASUSD_USER_EXEC=/usr/bin/asusd-user\\n", "")
          asusd_user_service.gsub!(
            "ExecStart=${ASUSD_USER_EXEC}",
            "ExecStart=\#{prefix}/bin/asusd-user",
          )
          File.write("\#{systemd_user_dir}/asusd-user.service", asusd_user_service)
        end

        File.write("\#{asusd_config_dir}/asusd-user.env", <<~EOS)
          ASUSD_DATA_DIR=\#{asusd_share_dir}
          ROG_GUI_DATA_DIR=\#{rog_gui_share_dir}
          ROG_GUI_LAYOUTS_DIR=\#{rog_gui_share_dir}/layouts
          ASUSCTL_AURA_SUPPORT_PATH=\#{asusd_share_dir}/aura_support.ron
          ASUSCTL_DATA_DIRS=\#{xdg_share}
        EOS

        system "gtk-update-icon-cache", "\#{xdg_share}/icons/hicolor", "-f", "-t" if icon_cache_cmd
        system "update-desktop-database", applications_dir if desktop_db_cmd
      RUBY
      "{{staged_path}}",
      "{{HOMEBREW_PREFIX}}",
      "{{home}}",
    ]
  end

  uninstall_postflight_steps do
    run "ruby", args: [
      "-e",
      <<~RUBY,
        require "fileutils"

        home = ARGV[0]
        applications_dir = "\#{home}/.local/share/applications"
        icons_dir = "\#{home}/.local/share/icons/hicolor/512x512/apps"
        status_icons_dir = "\#{home}/.local/share/icons/hicolor/scalable/status"
        systemd_user_dir = "\#{home}/.config/systemd/user"
        asusd_config_dir = "\#{home}/.config/asusd"

        icon_cache_cmd = system("which gtk-update-icon-cache > /dev/null 2>&1")
        desktop_db_cmd = system("which update-desktop-database > /dev/null 2>&1")
        systemctl = %w[/usr/bin/systemctl /bin/systemctl].find do |path|
          File.executable?(path)
        end

        system systemctl, "--user", "disable", "--now", "asusd-user.service" if systemctl

        FileUtils.rm("\#{systemd_user_dir}/asusd-user.service", force: true)
        FileUtils.rm("\#{applications_dir}/rog-control-center.desktop", force: true)
        FileUtils.rm("\#{asusd_config_dir}/asusd-user.env", force: true)

        %w[
          asus_notif_blue.png
          asus_notif_green.png
          asus_notif_orange.png
          asus_notif_red.png
          asus_notif_white.png
          asus_notif_yellow.png
          rog-control-center.png
        ].each do |icon|
          FileUtils.rm("\#{icons_dir}/\#{icon}", force: true)
        end

        %w[
          gpu-compute.svg
          gpu-hybrid.svg
          gpu-integrated.svg
          gpu-nvidia.svg
          gpu-vfio.svg
          notification-reboot.svg
        ].each do |icon|
          FileUtils.rm("\#{status_icons_dir}/\#{icon}", force: true)
        end

        FileUtils.rmdir(asusd_config_dir) if Dir.exist?(asusd_config_dir) && Dir.empty?(asusd_config_dir)

        system "gtk-update-icon-cache", "\#{home}/.local/share/icons/hicolor", "-f", "-t" if icon_cache_cmd
        system "update-desktop-database", applications_dir if desktop_db_cmd
      RUBY
      "{{home}}",
    ]
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
