cask "1password-gui-linux" do
  arch intel: "x86_64", arm: "aarch64"
  os linux: "linux"

  version "8.11.16"
  sha256 arm64_linux:  "8adca470eb570ad383789ec2b5ab0df0ce00abc0c2576a6e9a9cbae3a3c00e21",
         x86_64_linux: "2d9d15dbde862cb75ea248f79a00f42e74021ea94c1e73303cb1e5c08e5bd4ad"

  arch_suffix =
    case arch
    when "aarch64" then "arm64"
    when "x86_64" then "x64"
    end

  url "https://downloads.1password.com/#{os}/tar/stable/#{arch}/1password-#{version}.#{arch_suffix}.tar.gz"
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

  binary "1password-#{version}.#{arch_suffix}/1password", target: "1password"
  binary "1password-#{version}.#{arch_suffix}/op-ssh-sign", target: "op-ssh-sign"
  binary "1password-#{version}.#{arch_suffix}/1Password-BrowserSupport", target: "1Password-BrowserSupport"
  binary "1password-#{version}.#{arch_suffix}/1Password-Crash-Handler", target: "1Password-Crash-Handler"
  binary "1password-#{version}.#{arch_suffix}/1Password-LastPass-Exporter", target: "1Password-LastPass-Exporter"
  artifact "1password-#{version}.#{arch_suffix}/resources/1password.desktop",
           target: "#{Dir.home}/.local/share/applications/1password.desktop"
  artifact "1password-#{version}.#{arch_suffix}/resources/icons/hicolor/256x256/apps/1password.png",
           target: "#{Dir.home}/.local/share/icons/1password.png"
  artifact "1password-#{version}.#{arch_suffix}/com.1password.1Password.policy.tpl",
           target: "#{HOMEBREW_PREFIX}/etc/polkit-1/actions/com.1password.1Password.policy"

  preflight do
    desktop_file = "#{staged_path}/1password-#{version}.#{arch_suffix}/resources/1password.desktop"
    text = File.read(desktop_file)
    new_contents = text.gsub("Exec=/opt/1Password/1password", "Exec=#{HOMEBREW_PREFIX}/bin/1password")
    File.write(desktop_file, new_contents)
  end

  postflight do
    system "echo", "Installing polkit policy file to /etc/polkit-1/actions/, you may be prompted for your password."
    if !File.exist?("/etc/polkit-1/actions/com.1password.1Password.policy") ||
       !FileUtils.identical?(
         "#{staged_path}/1password-#{version}.#{arch_suffix}/com.1password.1Password.policy.tpl",
         "/etc/polkit-1/actions/com.1password.1Password.policy",
       )

      human_users = `awk -F: '$3 >= 1000 && $3 <= 9999 && $1 != "nobody" { print $1 }' /etc/passwd`
                    .split("\n").first(10)
      policy_owners = human_users.map { |user| "unix-user:#{user}" }.join(" ")
      policy_file = File.read("#{staged_path}/1password-#{version}.#{arch_suffix}/com.1password.1Password.policy.tpl")
      replaced_contents = policy_file.gsub("${POLICY_OWNERS}", policy_owners)
      File.write("#{staged_path}/1password-#{version}.#{arch_suffix}/com.1password.1Password.policy",
                 replaced_contents)
      system "sudo", "install", "-Dm0644",
             "#{staged_path}/1password-#{version}.#{arch_suffix}/com.1password.1Password.policy",
             "/etc/polkit-1/actions/com.1password.1Password.policy"
      puts "Installed /etc/polkit-1/actions/com.1password.1Password.policy"
    else
      puts "Skipping installation of /etc/polkit-1/actions/com.1password.1Password.policy,
      as it already exists and is the same as the version to be installed."
    end

    File.write("#{staged_path}/zpass.sh", <<~EOS)
      #!/bin/bash
      zenity --password --title="Homebrew Sudo Password Prompt"
    EOS

    File.write("#{staged_path}/1password-uninstall.sh", <<~EOS)
      #!/bin/bash
      set -e

      SUDO_ASKPASS=#{staged_path}/zpass.sh
      echo "Uninstalling polkit policy file from /etc/polkit-1/actions/com.1password.1Password.policy"
      if [ -f /etc/polkit-1/actions/com.1password.1Password.policy ]; then
        sudo rm -f /etc/polkit-1/actions/com.1password.1Password.policy
        echo "Removed /etc/polkit-1/actions/com.1password.1Password.policy"
      else
        echo "/etc/polkit-1/actions/com.1password.1Password.policy does not exist, skipping."
      fi
    EOS
  end

  uninstall_preflight do
    system "chmod", "+x", "#{staged_path}/1password-uninstall.sh"
    system "#{staged_path}/1password-uninstall.sh"
  end

  zap trash: [
    "~/.cache/1password",
    "~/.config/1Password",
    "~/.local/share/keyrings/1password.keyring",
  ]
end
