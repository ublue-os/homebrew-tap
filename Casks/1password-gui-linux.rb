module Utils
  def self.alternate_arch(arch)
    case arch
    when "aarch64"
      "arm64"
    when "x86_64"
      "x64"
    end
  end

  def self.replace_path_in_file(file_path, old_text, new_text)
    text = File.read(file_path)
    new_contents = text.gsub(old_text, new_text)
    File.open(file_path, "w") { |file| file.puts new_contents }
  end
end

cask "1password-gui-linux" do
  arch intel: "x86_64", arm: "aarch64"
  os linux: "linux"

  version "8.11.12"
  sha256 :no_check

  url "https://downloads.1password.com/#{os}/tar/stable/#{arch}/1password-latest.tar.gz"
  name "1Password"
  desc "Password manager that keeps all passwords secure behind one password"
  homepage "https://1password.com/"

  livecheck do
    url "https://releases.1password.com/linux/stable/index.xml"
    regex(/v?(\d+(?:\.\d+)+)/i)
    strategy :xml do |xml, regex|
      xml.get_elements("rss//channel//item//link").map { |item| item.text[regex, 1] }
    end
  end

  auto_updates true

  binary "1password-#{version}.#{Utils.alternate_arch(arch)}/1password",
         target: "1password"
  binary "1password-#{version}.#{Utils.alternate_arch(arch)}/op-ssh-sign",
         target: "op-ssh-sign"
  binary "1password-#{version}.#{Utils.alternate_arch(arch)}/1Password-BrowserSupport",
         target: "1Password-BrowserSupport"
  binary "1password-#{version}.#{Utils.alternate_arch(arch)}/1Password-Crash-Handler",
         target: "1Password-Crash-Handler"
  binary "1password-#{version}.#{Utils.alternate_arch(arch)}/1Password-LastPass-Exporter",
         target: "1Password-LastPass-Exporter"
  artifact "1password-#{version}.#{Utils.alternate_arch(arch)}/resources/1password.desktop",
           target: "#{Dir.home}/.local/share/applications/1password.desktop"
  artifact "1password-#{version}.#{Utils.alternate_arch(arch)}/resources/icons/hicolor/256x256/apps/1password.png",
           target: "#{Dir.home}/.local/share/icons/1password.png"

  preflight do
    Utils.replace_path_in_file("#{staged_path}/1password-#{version}.#{Utils.alternate_arch(arch)}/resources/1password.desktop",
                               "Exec=/opt/1Password/1password",
                               "Exec=#{HOMEBREW_PREFIX}/bin/1password")
  end

  postflight do
    system "echo", "Installing polkit policy file to /etc/polkit-1/actions/, you may be prompted for your password."
    if !File.exist?("/etc/polkit-1/actions/com.1password.1Password.policy") ||
       !FileUtils.identical?("#{staged_path}/1password-#{version}.#{Utils.alternate_arch(arch)}/com.1password.1Password.policy.tpl", "/etc/polkit-1/actions/com.1password.1Password.policy")
      system "sudo", "install", "-Dm0644",
             "#{staged_path}/1password-#{version}.#{Utils.alternate_arch(arch)}/com.1password.1Password.policy.tpl",
             "/etc/polkit-1/actions/com.1password.1Password.policy"
      puts "Installed /etc/polkit-1/actions/com.1password.1Password.policy"
    else
      puts "Skipping installation of /etc/polkit-1/actions/com.1password.1Password.policy, as it already exists and the same as the version to be installed."
    end

    system "echo", "Installing flatpak browser integratrion using https://github.com/FlyinPancake/1password-flatpak-browser-integration"
    system "curl", "-L",
           "https://github.com/FlyinPancake/1password-flatpak-browser-integration/raw/refs/heads/main/1password-flatpak-browser-integration.sh",
           "-o", "#{staged_path}/1password-flatpak-browser-integration.sh"
    system "chmod", "+x", "#{staged_path}/1password-flatpak-browser-integration.sh"

    integration_script = File.read("#{staged_path}/1password-flatpak-browser-integration.sh")
    integration_script.gsub!("/opt/1Password/1Password-BrowserSupport",
                             "#{HOMEBREW_PREFIX}/bin/1Password-BrowserSupport")
    File.write("#{staged_path}/1password-flatpak-browser-integration.sh", integration_script)

    system "#{staged_path}/1password-flatpak-browser-integration.sh"

    ohai "If you need to integrate with flatpak browsers, you need to install the `1password-flatpak-integrations` cask."

    File.write("#{staged_path}/1password-uninstall.sh", <<~EOS
      #!/bin/bash
      set -e
      echo "Uninstalling polkit policy file from /etc/polkit-1/actions/com.1password.1Password.policy"
      if [ -f /etc/polkit-1/actions/com.1password.1Password.policy ]; then
        rm -f /etc/polkit-1/actions/com.1password.1Password.policy
        echo "Removed /etc/polkit-1/actions/com.1password.1Password.policy"
      else
        echo "/etc/polkit-1/actions/com.1password.1Password.policy does not exist, skipping."
      fi
    EOS
    )
  end

  uninstall_preflight do
    system "chmod", "+x", "#{staged_path}/1password-uninstall.sh"
    system "sudo", "#{staged_path}/1password-uninstall.sh"
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
