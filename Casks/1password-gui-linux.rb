cask "1password-gui-linux" do
  version "8.11.8"
  sha256 :no_check

  url "https://downloads.1password.com/linux/rpm/stable/x86_64/1password-latest.rpm"
  name "1Password"
  desc "Password manager that keeps all passwords secure behind one password"
  homepage "https://1password.com/"

  auto_updates true

  binary "#{staged_path}/1password-extracted/opt/1Password/1password", target: "1password"

  preflight do
    rpm_file = "#{staged_path}/1password-latest.rpm"

    extract_dir = "#{staged_path}/1password-extracted"
    FileUtils.mkdir_p extract_dir

    system "cd '#{extract_dir}' && rpm2cpio '#{rpm_file}' | cpio -idmv"

    FileUtils.rm rpm_file
  end

  postflight do
    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    FileUtils.mkdir_p "#{Dir.home}/.local/share/icons"

    icon_source = "#{staged_path}/1password-extracted/usr/share/icons/hicolor/256x256/apps/1password.png"
    icon_target = "#{Dir.home}/.local/share/icons/1password.png"

    FileUtils.cp icon_source, icon_target if File.exist?(icon_source)

    bundled_desktop = "#{staged_path}/1password-extracted/usr/share/applications/1password.desktop"
    if File.exist?(bundled_desktop)
      desktop_content = File.read(bundled_desktop)
      desktop_content.gsub!(/^Exec=.*/, "Exec=#{HOMEBREW_PREFIX}/bin/1password %U")
      File.write("#{Dir.home}/.local/share/applications/1password.desktop", desktop_content)
    else
      File.write("#{Dir.home}/.local/share/applications/1password.desktop", <<~EOS)
        [Desktop Entry]
        Name=1Password
        Comment=Password manager that keeps all passwords secure behind one password
        GenericName=Password Manager
        Exec=#{HOMEBREW_PREFIX}/bin/1password %U
        Icon=1password
        Type=Application
        StartupNotify=true
        StartupWMClass=1Password
        Categories=Utility;Security;
        Keywords=password;security;encryption;
        MimeType=x-scheme-handler/onepassword;x-scheme-handler/onepassword4;x-scheme-handler/onepassword-ssh;
      EOS
    end
  end

  uninstall_postflight do
    # Remove desktop integration files created during installation
    FileUtils.rm("#{Dir.home}/.local/share/applications/1password.desktop")
    FileUtils.rm("#{Dir.home}/.local/share/icons/1password.png")
  end

  zap trash: [
    "~/.cache/1password",
    "~/.config/1Password",
    "~/.local/share/1password",
    "~/.local/share/applications/1password.desktop",
    "~/.local/share/icons/1password.png",
    "~/.local/share/keyrings/1password.keyring",
  ]
end
