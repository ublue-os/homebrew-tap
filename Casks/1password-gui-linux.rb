cask "1password-gui-linux" do
  arch intel: "x86_64", arm: "aarch64"
  os linux: "linux"

  version "8.12.10"
  sha256 arm64_linux:  "6cd9af5e0feb44cd28b421c577968cfb8ac4b785c557637c420a9942a592aff9",
         x86_64_linux: "83d6adb7ed43439d1f5ab6ae6c991dc626b0d5ec207db66f435f2662d008aa23"

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
  artifact "1password-#{version}.#{arch_suffix}/resources/custom_allowed_browsers",
           target: "#{HOMEBREW_PREFIX}/etc/1password/custom_allowed_browsers"

  preflight do
    desktop_file = "#{staged_path}/1password-#{version}.#{arch_suffix}/resources/1password.desktop"
    text = File.read(desktop_file)
    new_contents = text.gsub("Exec=/opt/1Password/1password", "Exec=#{HOMEBREW_PREFIX}/bin/1password")
    File.write(desktop_file, new_contents)

    # set up flatpak browser support
    browser_config = "#{staged_path}/1password-#{version}.#{arch_suffix}/resources/custom_allowed_browsers"
    File.open(browser_config, "a") do |f|
      f.write "\nflatpak-session-helper"
    end
  end

  postflight do
    system "echo", "Installing polkit policy file to /etc/polkit-1/actions/, you may be prompted for your password."
    if !File.exist?("/etc/polkit-1/actions/com.1password.1Password.policy") ||
       !FileUtils.identical?("#{staged_path}/1password-#{version}.#{arch_suffix}/com.1password.1Password.policy.tpl",
                             "/etc/polkit-1/actions/com.1password.1Password.policy")

      # Get users from /etc/passwd and output first 10 human users (1000 >= UID <= 9999) to the policy file
      # format: `unix-user:username` space separated
      # This is used to allow these users to unlock 1Password via polkit.
      human_users = `awk -F: '$3 >= 1000 && $3 <= 9999 && $1 != "nobody" { print $1 }' /etc/passwd`
                    .split("\n").first(10)
      policy_owners = human_users.map { |user| "unix-user:#{user}" }.join(" ")
      policy_file = File.read("#{staged_path}/1password-#{version}.#{arch_suffix}/com.1password.1Password.policy.tpl")
      replaced_contents = policy_file.gsub("${POLICY_OWNERS}", policy_owners)
      File.write("#{staged_path}/1password-#{version}.#{arch_suffix}/com.1password.1Password.policy", replaced_contents)
      system "sudo", "install", "-Dm0644",
             "#{staged_path}/1password-#{version}.#{arch_suffix}/com.1password.1Password.policy",
             "/etc/polkit-1/actions/com.1password.1Password.policy"
      puts "Installed /etc/polkit-1/actions/com.1password.1Password.policy"
    else
      puts "Skipping installation of /etc/polkit-1/actions/com.1password.1Password.policy,
      as it already exists and is the same as the version to be installed."
    end

    if !File.exist?("/etc/1password/custom_allowed_browsers") ||
       File.readlines("/etc/1password/custom_allowed_browsers").grep(/^flatpak-session-helper/).none?
      if File.exist?("/etc/1password/custom_allowed_browsers")
        # append the flatpak-session-helper to the existing custom_allowed_browsers file
        File.open("/etc/1password/custom_allowed_browsers", "a") do |f|
          f.write "\nflatpak-session-helper"
        end
        puts "Added flatpak-session-helper to /etc/1password/custom_allowed_browsers"
      else
        puts "Installing custom allowed browsers file to /etc/1password/, you may be prompted for your password."
        system "sudo", "install", "-Dm0644",
               "#{staged_path}/1password-#{version}.#{arch_suffix}/resources/custom_allowed_browsers",
               "/etc/1password/custom_allowed_browsers"
      end
    else
      puts "Skipping installation of /etc/1password/custom_allowed_browsers " \
           "as it already exists and contains flatpak-session-helper"
    end

    File.write("#{staged_path}/zpass.sh", <<~EOS)
      #!/bin/bash
      zenity --password --title="Homebrew Sudo Password Prompt"
    EOS
    set_permissions("#{staged_path}/zpass.sh", "755")

    # 1Password browser support binary needs to be owned by group onepassword and
    # have the GID bit set in order to function
    system <<~EOS
      #!/bin/bash
      if [ ! "$(getent group onepassword)" ]; then
        echo "Creating group 'onepassword' for 1Password browser support, you may be prompted for your password."
        sudo groupadd onepassword
      fi
    EOS
    set_ownership("#{staged_path}/1password-#{version}.#{arch_suffix}/1Password-BrowserSupport", user: "root", group: "onepassword")
    # can't use set_permissions here because we no longer own the file and brew tries to run chmod without sudo
    system "sudo", "chmod", "2755", "#{File.expand_path(staged_path)}/1password-#{version}.#{arch_suffix}/1Password-BrowserSupport"

    # the 1Password binary also needs to be owned by root so it can be executed by
    # browser support which runs with elevated permissions
    set_ownership("#{staged_path}/1password-#{version}.#{arch_suffix}/1password", user: "root", group: "root")

    # chrome-sandbox requires the setuid bit to be specifically set.
    # See https://github.com/electron/electron/issues/17972
    set_ownership("#{staged_path}/1password-#{version}.#{arch_suffix}/chrome-sandbox", user: "root", group: "root")
    system "sudo", "chmod", "4755", "#{File.expand_path(staged_path)}/1password-#{version}.#{arch_suffix}/chrome-sandbox"

    File.open("#{staged_path}/1PasswordWrapper.sh", "w", 0755) do |f|
      f.write <<~EOS
        #!/bin/bash
        if [ "${container-}" = flatpak ]; then
          flatpak-spawn --host "#{File.expand_path(HOMEBREW_PREFIX)}/bin/1Password-BrowserSupport" "$@"
        else
          exec "#{File.expand_path(HOMEBREW_PREFIX)}/bin/1Password-BrowserSupport" "$@"
        fi
      EOS
    end

    # this list of supported native messaging hosts paths was retrieved by examining the 1Password log file at
    #  #{Dir.home}/.config/1Password/logs/1Password_rCURRENT.log
    native_messaging_hosts_paths = ["#{Dir.home}/.mozilla/native-messaging-hosts",
                                    "#{Dir.home}/.config/google-chrome/NativeMessagingHosts",
                                    "#{Dir.home}/.config/google-chrome-beta/NativeMessagingHosts",
                                    "#{Dir.home}/.config/google-chrome-unstable/NativeMessagingHosts",
                                    "#{Dir.home}/.config/chromium/NativeMessagingHosts",
                                    "#{Dir.home}/.config/microsoft-edge-dev/NativeMessagingHosts",
                                    "#{Dir.home}/.config/BraveSoftware/Brave-Browser/NativeMessagingHosts",
                                    "#{Dir.home}/.config/vivaldi/NativeMessagingHosts",
                                    "#{Dir.home}/.config/vivaldi-snapshot/NativeMessagingHosts"]

    native_messaging_hosts_paths.each do |nmh_path|
      script_path = "#{File.expand_path(nmh_path)}/1PasswordWrapper.sh"
      # copy wrapper script to each browser support folder so the flatpak filesystem restrictions
      # won't prevent the browser from launching it
      system "cp", "-f", "#{staged_path}/1PasswordWrapper.sh", script_path.to_s

      manifest_content=<<~EOS
        {
          "name": "com.1password.1password",
          "description": "1Password BrowserSupport",
          "path": "#{script_path}",
          "type": "stdio",
          "allowed_origins": [
            "chrome-extension://hjlinigoblmkhjejkmbegnoaljkphmgo/",
            "chrome-extension://bkpbhnjcbehoklfkljkkbbmipaphipgl/",
            "chrome-extension://gejiddohjgogedgjnonbofjigllpkmbf/",
            "chrome-extension://khgocmkkpikpnmmkgmdnfckapcdkgfaf/",
            "chrome-extension://aeblfdkhhhdcdjpifhhbdiojplfjncoa/",
            "chrome-extension://dppgmdbiimibapkepcbdbmkaabgiofem/"
          ]
        }
      EOS

      # Firefox is the only supported browser which has a different manifest
      manifest_content_firefox=<<~EOS
        {
            "name": "com.1password.1password",
            "description": "1Password BrowserSupport",
            "path": "#{script_path}",
            "type": "stdio",
            "allowed_extensions": [
              "{0a75d802-9aed-41e7-8daa-24c067386e82}",
              "{25fc87fa-4d31-4fee-b5c1-c32a7844c063}",
              "{d634138d-c276-4fc8-924b-40a0ea21d284}"
            ]
        }
      EOS

      manifest_path = "#{nmh_path}/com.1password.1password.json"
      if File.exist?(manifest_path)
        manifest = JSON.parse(File.read(manifest_path))
        if manifest["path"] == script_path
          puts "Found native messaging host manifest in #{manifest_path} " \
               "which already has flatpak browser support, skipping update."
        else
          puts "Updating native messaging host manifest in #{manifest_path} " \
               "to support flatpak browsers you may be prompted for your password."
          manifest["path"] = script_path
          system "echo '#{JSON.pretty_generate(manifest)}' | sudo tee #{manifest_path} >/dev/null"
        end
      else
        puts "Installing native messaging host manifest with flatpak browser support to #{nmh_path}, " \
             "you may be prompted for your password."
        system "sudo", "touch", manifest_path.to_s
        system "echo '#{nmh_path.include?("mozilla")? manifest_content_firefox : manifest_content}' " \
               "| sudo tee #{manifest_path} >/dev/null"
      end
      # set NMH manifests to read-only or else 1Password will overwrite them on launch
      system "sudo", "chown", "#{ENV['USER']}:#{ENV['USER']}", manifest_path.to_s
      system "sudo", "chmod", "444", manifest_path.to_s
    end

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

      # re-take ownership of the directory and binaries so we can remove them
      sudo chown "$(whoami)":"$(whoami)" \
       "#{staged_path}/1password-#{version}.#{arch_suffix}" \
       "#{staged_path}/1password-#{version}.#{arch_suffix}/1password" \
       "#{staged_path}/1password-#{version}.#{arch_suffix}/1Password-BrowserSupport" \
       "#{staged_path}/1password-#{version}.#{arch_suffix}/chrome-sandbox"

      native_messaging_hosts_paths=(
        "$HOME/.mozilla/native-messaging-hosts"
        "$HOME/.config/google-chrome/NativeMessagingHosts"
        "$HOME/.config/google-chrome-beta/NativeMessagingHosts"
        "$HOME/.config/google-chrome-unstable/NativeMessagingHosts"
        "$HOME/.config/chromium/NativeMessagingHosts"
        "$HOME/.config/microsoft-edge-dev/NativeMessagingHosts"
        "$HOME/.config/BraveSoftware/Brave-Browser/NativeMessagingHosts"
        "$HOME/.config/vivaldi/NativeMessagingHosts"
        "$HOME/.config/vivaldi-snapshot/NativeMessagingHosts"
      )
      #set NMH manifests back to read-write so 1Password can clean them up on uninstall
      for nmh_path in "${native_messaging_hosts_paths[@]}"; do
        manifest_file="$nmh_path/com.1password.1password.json"
        if [ -f "$manifest_file" ]; then
          echo "allowing write access to $manifest_file for 1Password uninstallation"
          sudo chmod 644 "$manifest_file"
        fi
        echo "removing wrapper script from $nmh_path/1PasswordWrapper.sh"
        sudo rm -f "$nmh_path/1PasswordWrapper.sh"
      done
    EOS
    set_permissions("#{staged_path}/1password-uninstall.sh", "740")

    # set the folder to be owned by root so browser support has access
    system "sudo", "chown", "root:root", "#{staged_path}/1password-#{version}.#{arch_suffix}"
  end

  uninstall_preflight do
    system "#{staged_path}/1password-uninstall.sh"
  end

  zap trash: [
    "~/.cache/1password",
    "~/.config/1Password",
    "~/.local/share/keyrings/1password.keyring",
  ]
end
