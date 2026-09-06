cask "1password-gui-linux" do
  arch arm: "aarch64", intel: "x86_64"
  arch_suffix =
    case arch
    when "aarch64" then "arm64"
    when "x86_64" then "x64"
    end
  os linux: "linux"

  version "8.12.34"
  sha256 arm:          "ea5102363d6cf3442b96a7abd6743da8c1d261f56a628e1a3c183d84fa65fdcb",
         intel:        "297784aa66770b645607a7f04c9ba2c4aebed4f46d21202487f521ba572b7b13",
         arm64_linux:  "ea5102363d6cf3442b96a7abd6743da8c1d261f56a628e1a3c183d84fa65fdcb",
         x86_64_linux: "297784aa66770b645607a7f04c9ba2c4aebed4f46d21202487f521ba572b7b13"

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

  depends_on formula: "jq"

  binary "1password/1password", target: "1password"
  binary "1password/op-ssh-sign", target: "op-ssh-sign"
  binary "1password/1Password-BrowserSupport", target: "1Password-BrowserSupport"
  binary "1password/1Password-Crash-Handler", target: "1Password-Crash-Handler"
  binary "1password/1Password-LastPass-Exporter", target: "1Password-LastPass-Exporter"
  artifact "1password/resources/1password.desktop",
           target: "#{Dir.home}/.local/share/applications/1password.desktop"
  artifact "1password/resources/icons/hicolor/256x256/apps/1password.png",
           target: "#{Dir.home}/.local/share/icons/1password.png"
  artifact "1password/com.1password.1Password.policy.tpl",
           target: "#{HOMEBREW_PREFIX}/etc/polkit-1/actions/com.1password.1Password.policy"
  artifact "1password/resources/custom_allowed_browsers",
           target: "#{HOMEBREW_PREFIX}/etc/1password/custom_allowed_browsers"

  preflight_steps do
    move "1password-*", "1password", source_glob: true
    symlink ".", ".user-home", source_base: :home, overwrite: true
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons", base: :home
    inreplace "1password/resources/1password.desktop", "Exec=/opt/1Password/1password",
              "Exec={{HOMEBREW_PREFIX}}/bin/1password"
    run "/bin/sh", args: ["-eu", "-c", <<~'SH'], chdir: "{{staged_path}}"
      printf '\nflatpak-session-helper\n' >> 1password/resources/custom_allowed_browsers
      owners=$(awk -F: '$3 >= 1000 && $3 <= 9999 && $1 != "nobody" && count++ < 10 {printf "unix-user:%s ", $1}' /etc/passwd)
      sed "s/\${POLICY_OWNERS}/$owners/g" 1password/com.1password.1Password.policy.tpl > 1password/com.1password.1Password.policy
    SH
  end

  postflight_steps do
    # System policy and browser allowlist require privilege; user browser files do not.
    run "/bin/sh", args: ["-eu", "-c", <<~'SH', "--", "{{staged_path}}/1password"], sudo: true
      install -Dm0644 "$1/com.1password.1Password.policy" /etc/polkit-1/actions/com.1password.1Password.policy
      if [ -f /etc/1password/custom_allowed_browsers ]; then
        if ! grep -q '^flatpak-session-helper' /etc/1password/custom_allowed_browsers; then
          printf '\nflatpak-session-helper\n' >> /etc/1password/custom_allowed_browsers
        fi
      else
        install -Dm0644 "$1/resources/custom_allowed_browsers" /etc/1password/custom_allowed_browsers
      fi
      getent group onepassword >/dev/null || groupadd onepassword
    SH
    set_ownership "1password/1Password-BrowserSupport", user: "root", group: "onepassword", recursive: false
    run "/bin/chmod", args: ["2755", "{{staged_path}}/1password/1Password-BrowserSupport"], sudo: true
    set_ownership ["1password/1password", "1password/chrome-sandbox"], user: "root", group: "root", recursive: false
    run "/bin/chmod", args: ["4755", "{{staged_path}}/1password/chrome-sandbox"], sudo: true

    write_file "1PasswordWrapper.sh", <<~SH
      #!/bin/bash
      if [ "${container-}" = flatpak ]; then
        exec flatpak-spawn --host "{{HOMEBREW_PREFIX}}/bin/1Password-BrowserSupport" "$@"
      else
        exec "{{HOMEBREW_PREFIX}}/bin/1Password-BrowserSupport" "$@"
      fi
    SH
    set_permissions "1PasswordWrapper.sh", "755", recursive: false
    write_file "native-messaging-chrome.json", <<~JSON
      {
        "name": "com.1password.1password",
        "description": "1Password BrowserSupport",
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
    JSON
    write_file "native-messaging-firefox.json", <<~JSON
      {
        "name": "com.1password.1password",
        "description": "1Password BrowserSupport",
        "type": "stdio",
        "allowed_extensions": [
          "{0a75d802-9aed-41e7-8daa-24c067386e82}",
          "{25fc87fa-4d31-4fee-b5c1-c32a7844c063}",
          "{d634138d-c276-4fc8-924b-40a0ea21d284}"
        ]
      }
    JSON
    run "/bin/bash", chdir: "{{staged_path}}",
                     env: { "BROWSER_HOME" => "{{staged_path}}/.user-home", "JQ" => "{{HOMEBREW_PREFIX}}/bin/jq" },
                     writable_paths: [".mozilla/native-messaging-hosts", ".config/google-chrome/NativeMessagingHosts",
                                      ".config/google-chrome-beta/NativeMessagingHosts",
                                      ".config/google-chrome-unstable/NativeMessagingHosts",
                                      ".config/chromium/NativeMessagingHosts",
                                      ".config/microsoft-edge-dev/NativeMessagingHosts",
                                      ".config/BraveSoftware/Brave-Browser/NativeMessagingHosts",
                                      ".config/vivaldi/NativeMessagingHosts",
                                      ".config/vivaldi-snapshot/NativeMessagingHosts"],
                     writable_base: :home, args: ["-eu", "-c", <<~'SH']
                       BROWSER_HOME=$(readlink "$BROWSER_HOME")
                       for relative in .mozilla/native-messaging-hosts \
                         .config/{google-chrome,google-chrome-beta,google-chrome-unstable,chromium,microsoft-edge-dev,BraveSoftware/Brave-Browser,vivaldi,vivaldi-snapshot}/NativeMessagingHosts; do
                         directory="$BROWSER_HOME/$relative"
                         mkdir -p "$directory"
                         cp -f 1PasswordWrapper.sh "$directory/1PasswordWrapper.sh"
                         chmod 755 "$directory/1PasswordWrapper.sh"
                         manifest="$directory/com.1password.1password.json"
                         source=native-messaging-chrome.json
                         [[ "$relative" != .mozilla/* ]] || source=native-messaging-firefox.json
                         [[ ! -f "$manifest" ]] || source="$manifest"
                         temporary=$(mktemp "$directory/.1password-manifest.XXXXXX")
                         trap 'rm -f "$temporary"' EXIT
                         "$JQ" --arg path "$directory/1PasswordWrapper.sh" '.path = $path' "$source" > "$temporary"
                         chmod 444 "$temporary"
                         mv -f "$temporary" "$manifest"
                       done
                     SH
    # BrowserSupport requires the payload directory itself to be root-owned too.
    set_ownership "1password", user: "root", group: "root", recursive: false
  end

  uninstall_preflight_steps do
    symlink ".", ".user-home", source_base: :home, overwrite: true
    remove "/etc/polkit-1/actions/com.1password.1Password.policy", sudo: true
    run "/bin/chown", args: ["{{user}}:", "{{staged_path}}/1password", "{{staged_path}}/1password/1password",
                             "{{staged_path}}/1password/1Password-BrowserSupport",
                             "{{staged_path}}/1password/chrome-sandbox"],
                      sudo: true
    run "/bin/bash", env: { "BROWSER_HOME" => "{{staged_path}}/.user-home" },
                     writable_paths: [".mozilla/native-messaging-hosts", ".config/google-chrome/NativeMessagingHosts",
                                      ".config/google-chrome-beta/NativeMessagingHosts",
                                      ".config/google-chrome-unstable/NativeMessagingHosts",
                                      ".config/chromium/NativeMessagingHosts",
                                      ".config/microsoft-edge-dev/NativeMessagingHosts",
                                      ".config/BraveSoftware/Brave-Browser/NativeMessagingHosts",
                                      ".config/vivaldi/NativeMessagingHosts",
                                      ".config/vivaldi-snapshot/NativeMessagingHosts"],
                     writable_base: :home, args: ["-eu", "-c", <<~'SH']
                       BROWSER_HOME=$(readlink "$BROWSER_HOME")
                       for relative in .mozilla/native-messaging-hosts \
                         .config/{google-chrome,google-chrome-beta,google-chrome-unstable,chromium,microsoft-edge-dev,BraveSoftware/Brave-Browser,vivaldi,vivaldi-snapshot}/NativeMessagingHosts; do
                         directory="$BROWSER_HOME/$relative"
                         manifest="$directory/com.1password.1password.json"
                         if [ -f "$manifest" ]; then chmod 644 "$manifest"; fi
                         rm -f "$directory/1PasswordWrapper.sh"
                       done
                     SH
  end

  zap trash: [
    "~/.cache/1password",
    "~/.config/1Password",
    "~/.local/share/keyrings/1password.keyring",
  ]
end
