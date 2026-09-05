cask "1password-gui-linux" do
  arch arm: "aarch64", intel: "x86_64"
  os linux: "linux"

  version "8.12.34"
  sha256 arm:          "ea5102363d6cf3442b96a7abd6743da8c1d261f56a628e1a3c183d84fa65fdcb",
         intel:        "297784aa66770b645607a7f04c9ba2c4aebed4f46d21202487f521ba572b7b13",
         arm64_linux:  "ea5102363d6cf3442b96a7abd6743da8c1d261f56a628e1a3c183d84fa65fdcb",
         x86_64_linux: "297784aa66770b645607a7f04c9ba2c4aebed4f46d21202487f521ba572b7b13"

  arch_suffix =
    case arch
    when "aarch64" then "arm64"
    when "x86_64" then "x64"
    end

  url "https://downloads.1password.com/linux/tar/stable/#{arch}/1password-#{version}.#{arch_suffix}.tar.gz"
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

  preflight_steps do
    run "ruby", args: [
      "-e",
      <<~RUBY,
        staged = ARGV[0]
        prefix = ARGV[1]
        pkg_dir = Dir.glob("\#{staged}/1password-*").first
        if pkg_dir
          desktop_file = "\#{pkg_dir}/resources/1password.desktop"
          if File.exist?(desktop_file)
            text = File.read(desktop_file)
            File.write(desktop_file, text.gsub("Exec=/opt/1Password/1password", "Exec=\#{prefix}/bin/1password"))
          end
          browser_config = "\#{pkg_dir}/resources/custom_allowed_browsers"
          if File.exist?(browser_config)
            File.open(browser_config, "a") { |f| f.write "\nflatpak-session-helper" }
          end
        end
      RUBY
      "{{staged_path}}",
      "{{HOMEBREW_PREFIX}}",
    ]
  end

  postflight_steps do
    run "ruby", args: [
      "-e",
      <<~RUBY,
        require "fileutils"
        require "json"

        staged_path = ARGV[0]
        prefix = ARGV[1]
        home = ARGV[2]
        user = ARGV[3]

        pkg_dir = Dir.glob("\#{staged_path}/1password-*").find { |d| File.directory?(d) }
        next unless pkg_dir

        system "echo", "Installing polkit policy file to /etc/polkit-1/actions/, you may be prompted for your password."
        policy_tpl = "\#{pkg_dir}/com.1password.1Password.policy.tpl"
        policy_dest = "/etc/polkit-1/actions/com.1password.1Password.policy"
        if !File.exist?(policy_dest) || !FileUtils.identical?(policy_tpl, policy_dest)
          human_users = `awk -F: '$3 >= 1000 && $3 <= 9999 && $1 != "nobody" { print $1 }' /etc/passwd`.split("\n").first(10)
          policy_owners = human_users.map { |u| "unix-user:\#{u}" }.join(" ")
          policy_file = File.read(policy_tpl)
          replaced_contents = policy_file.gsub("${POLICY_OWNERS}", policy_owners)
          policy_tmp = "\#{pkg_dir}/com.1password.1Password.policy"
          File.write(policy_tmp, replaced_contents)
          system "sudo", "install", "-Dm0644", policy_tmp, policy_dest
          puts "Installed \#{policy_dest}"
        else
          puts "Skipping installation of \#{policy_dest}, as it already exists and is the same as the version to be installed."
        end

        custom_browsers_src = "\#{pkg_dir}/resources/custom_allowed_browsers"
        custom_browsers_dest = "/etc/1password/custom_allowed_browsers"
        if !File.exist?(custom_browsers_dest) || File.readlines(custom_browsers_dest).grep(/^flatpak-session-helper/).none?
          if File.exist?(custom_browsers_dest)
            File.open(custom_browsers_dest, "a") { |f| f.write "\nflatpak-session-helper" }
            puts "Added flatpak-session-helper to \#{custom_browsers_dest}"
          else
            puts "Installing custom allowed browsers file to /etc/1password/, you may be prompted for your password."
            system "sudo", "install", "-Dm0644", custom_browsers_src, custom_browsers_dest
          end
        else
          puts "Skipping installation of \#{custom_browsers_dest} as it already exists and contains flatpak-session-helper"
        end

        File.write("\#{staged_path}/zpass.sh", <<~EOS)
          #!/bin/bash
          zenity --password --title="Homebrew Sudo Password Prompt"
        EOS
        FileUtils.chmod 0755, "\#{staged_path}/zpass.sh"

        if system("getent group onepassword >/dev/null 2>&1") != true
          puts "Creating group 'onepassword' for 1Password browser support, you may be prompted for your password."
          system "sudo", "groupadd", "onepassword"
        end

        system "sudo", "chown", "root:onepassword", "\#{pkg_dir}/1Password-BrowserSupport"
        system "sudo", "chmod", "2755", "\#{pkg_dir}/1Password-BrowserSupport"
        system "sudo", "chown", "root:root", "\#{pkg_dir}/1password"
        system "sudo", "chown", "root:root", "\#{pkg_dir}/chrome-sandbox"
        system "sudo", "chmod", "4755", "\#{pkg_dir}/chrome-sandbox"

        File.open("\#{staged_path}/1PasswordWrapper.sh", "w", 0755) do |f|
          f.write <<~EOS
            #!/bin/bash
            if [ "${container-}" = flatpak ]; then
              flatpak-spawn --host "\#{prefix}/bin/1Password-BrowserSupport" "$@"
            else
              exec "\#{prefix}/bin/1Password-BrowserSupport" "$@"
            fi
          EOS
        end

        native_messaging_hosts_paths = [
          "\#{home}/.mozilla/native-messaging-hosts",
          "\#{home}/.config/google-chrome/NativeMessagingHosts",
          "\#{home}/.config/google-chrome-beta/NativeMessagingHosts",
          "\#{home}/.config/google-chrome-unstable/NativeMessagingHosts",
          "\#{home}/.config/chromium/NativeMessagingHosts",
          "\#{home}/.config/microsoft-edge-dev/NativeMessagingHosts",
          "\#{home}/.config/BraveSoftware/Brave-Browser/NativeMessagingHosts",
          "\#{home}/.config/vivaldi/NativeMessagingHosts",
          "\#{home}/.config/vivaldi-snapshot/NativeMessagingHosts",
        ]

        native_messaging_hosts_paths.each do |nmh_path|
          script_path = "\#{nmh_path}/1PasswordWrapper.sh"
          FileUtils.mkdir_p(nmh_path)
          FileUtils.cp("\#{staged_path}/1PasswordWrapper.sh", script_path)

          manifest_content = <<~EOS
            {
              "name": "com.1password.1password",
              "description": "1Password BrowserSupport",
              "path": "\#{script_path}",
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

          manifest_content_firefox = <<~EOS
            {
                "name": "com.1password.1password",
                "description": "1Password BrowserSupport",
                "path": "\#{script_path}",
                "type": "stdio",
                "allowed_extensions": [
                  "{0a75d802-9aed-41e7-8daa-24c067386e82}",
                  "{25fc87fa-4d31-4fee-b5c1-c32a7844c063}",
                  "{d634138d-c276-4fc8-924b-40a0ea21d284}"
                ]
            }
          EOS

          manifest_path = "\#{nmh_path}/com.1password.1password.json"
          if File.exist?(manifest_path)
            manifest = JSON.parse(File.read(manifest_path))
            if manifest["path"] == script_path
              puts "Found native messaging host manifest in \#{manifest_path} which already has flatpak browser support, skipping update."
            else
              puts "Updating native messaging host manifest in \#{manifest_path} to support flatpak browsers you may be prompted for your password."
              manifest["path"] = script_path
              system "echo '\#{JSON.pretty_generate(manifest)}' | sudo tee \#{manifest_path} >/dev/null"
            end
          else
            puts "Installing native messaging host manifest with flatpak browser support to \#{nmh_path}, you may be prompted for your password."
            system "sudo", "touch", manifest_path
            content = nmh_path.include?("mozilla") ? manifest_content_firefox : manifest_content
            system "echo '\#{content}' | sudo tee \#{manifest_path} >/dev/null"
          end
          system "sudo", "chown", "\#{user}:\#{user}", manifest_path
          system "sudo", "chmod", "444", manifest_path
        end

        File.write("\#{staged_path}/1password-uninstall.sh", <<~EOS)
          #!/bin/bash
          set -e

          SUDO_ASKPASS=\#{staged_path}/zpass.sh
          echo "Uninstalling polkit policy file from /etc/polkit-1/actions/com.1password.1Password.policy"
          if [ -f /etc/polkit-1/actions/com.1password.1Password.policy ]; then
            sudo rm -f /etc/polkit-1/actions/com.1password.1Password.policy
            echo "Removed /etc/polkit-1/actions/com.1password.1Password.policy"
          else
            echo "/etc/polkit-1/actions/com.1password.1Password.policy does not exist, skipping."
          fi

          sudo chown "$(whoami)":"$(whoami)" \\
           "\#{pkg_dir}" \\
           "\#{pkg_dir}/1password" \\
           "\#{pkg_dir}/1Password-BrowserSupport" \\
           "\#{pkg_dir}/chrome-sandbox"

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
        FileUtils.chmod 0740, "\#{staged_path}/1password-uninstall.sh"
        system "sudo", "chown", "root:root", pkg_dir
      RUBY
      "{{staged_path}}",
      "{{HOMEBREW_PREFIX}}",
      "{{home}}",
      "{{user}}",
    ]
  end

  uninstall_preflight_steps do
    run "./1password-uninstall.sh", chdir: :staged_path
  end

  zap trash: [
    "~/.cache/1password",
    "~/.config/1Password",
    "~/.local/share/keyrings/1password.keyring",
  ]
end
