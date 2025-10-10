module Utils
  INFO="\e[0;36m"    # Cyan for general information
  SUCCESS="\e[0;32m" # Green for success messages
  WARN="\e[0;33m"    # Yellow for warnings
  ERROR="\e[0;31m"   # Red for errors
  NC="\e[0m"            # No Color

  ALLOWED_EXTENSIONS_FIREFOX = '"allowed_extensions": [
      "{0a75d802-9aed-41e7-8daa-24c067386e82}",
      "{25fc87fa-4d31-4fee-b5c1-c32a7844c063}",
      "{d634138d-c276-4fc8-924b-40a0ea21d284}"
  ]'
  ALLOWED_EXTENSIONS_CHROMIUM='"allowed_origins": [
      "chrome-extension://hjlinigoblmkhjejkmbegnoaljkphmgo/",
      "chrome-extension://gejiddohjgogedgjnonbofjigllpkmbf/",
      "chrome-extension://khgocmkkpikpnmmkgmdnfckapcdkgfaf/",
      "chrome-extension://aeblfdkhhhdcdjpifhhbdiojplfjncoa/",
      "chrome-extension://dppgmdbiimibapkepcbdbmkaabgiofem/"
  ]'
  FLATPAK_PACKAGE_LIST = `flatpak list --app --columns=application`.split("\n")
  BROWSERS_NOT_USING_MOZILLA = [
    "org.mozilla.firefox",
    "io.gitlab.liberwolf-community",
    "net.waterfox.waterfox",
  ]
  GLOBAL_WRAPPER_PATH = "#{Dir.home}/.mozilla/native-messaging-hosts/1password-wrapper.sh"
  GLOBAL_NATIVE_MESSAGING_PATH = "#{Dir.home}/.mozilla/native-messaging-hosts"

  def self.replace_path_in_file(file_path, old_text, new_text)
    text = File.read(file_path)
    new_contents = text.gsub(old_text, new_text)
    File.open(file_path, "w") { |file| file.puts new_contents }
  end

  def self.get_native_messaging_hosts_json(wrapper_path, allowed_extensions)
    <<~EOS
      {
        "name": "com.1password.1password",
        "description": "1Password BrowserSupport",
        "path": "#{wrapper_path}",
        "type": "stdio",
        #{allowed_extensions}
      }
    EOS
  end

  def self.list_flatpak_browsers(browsers)
    browsers.select { |browser| FLATPAK_PACKAGE_LIST.include?(browser) }
  end
end

cask "1password-flatpak-browser-integration" do
  arch intel: "x86_64", arm: "aarch64"
  os linux: "linux"

  version :latest
  sha256 :no_check

  url "https://github.com/FlyinPancake/1password-flatpak-browser-integration.git",
      branch: "main"
  name "1Password Flatpak Browser Integration"
  desc "Integration for 1Password with Flatpak browsers"
  homepage "https://github.com/FlyinPancake/1password-flatpak-browser-integration"

  depends_on cask: "1password-gui-linux"

  preflight do
    puts "#{Utils::INFO}Detected Chromium-based browsers (incomplete list):#{Utils::NC}"
    chromium_browsers = Utils.list_flatpak_browsers([
      "com.google.Chrome",
      "com.brave.Browser",
      "com.vivaldi.Vivaldi",
      "com.opera.Opera",
      "com.microsoft.Edge",
      "ru.yandex.Browser",
      "org.chromium.Chromium",
      "io.github.ungoogled_software.ungoogled_chromium"
    ])
    puts chromium_browsers.empty? ? "None" : chromium_browsers.join("\n")

    puts "#{Utils::INFO}Detected Firefox-based browsers (incomplete list):#{Utils::NC}"
    firefox_browsers = Utils.list_flatpak_browsers([
      "org.mozilla.firefox",
      "one.ablaze.floorp",
      "io.gitlab.liberwolf-community",
      "org.torproject.torbrowser-launcher",
      "app.zen_browser.zen",
      "org.garudalinux.firedragon",
      "net.mullvad.MullvadBrowser",
      "net.waterfox.waterfox"
    ])
    puts firefox_browsers.empty? ? "None" : firefox_browsers.join("\n")

    puts "#{Utils::INFO}Enter the name of your browser's Flatpak application ID (e.g. com.google.Chrome): #{Utils::NC}"
    flatpak_browser_id = `read -r flatpak_browser_id && echo $flatpak_browser_id`.chomp
    if flatpak_browser_id.empty?
      puts "#{Utils::ERROR}No browser ID entered, aborting.#{Utils::NC}"
    end
    if Utils::FLATPAK_PACKAGE_LIST.exclude?(flatpak_browser_id)
      puts "#{Utils::ERROR}Browser ID #{flatpak_browser_id} not found in installed Flatpak applications, aborting.#{Utils::NC}"
    end
    puts "#{Utils::INFO}Using browser ID: #{flatpak_browser_id}#{Utils::NC}"

    browser_type = if chromium_browsers.include?(flatpak_browser_id)
      "chromium"
    elsif firefox_browsers.include?(flatpak_browser_id)
      "firefox"
    else
      puts "#{Utils::WARN}Browser ID #{flatpak_browser_id} not recognized as Chromium-based or Firefox-based, please enter manually: chromium or firefox#{Utils::NC}"
      manual_type = gets.chomp.downcase
      if %w[chromium firefox].include?(manual_type)
        manual_type
      else
        puts "#{Utils::ERROR}Invalid browser type entered, aborting.#{Utils::NC}"
      end
    end

    puts "#{Utils::INFO}Giving your browser permissions to run programs outside the sandbox...#{Utils::NC}"
    system "flatpak", "override", "--user", "--talk-name=org.freedesktop.Flatpak", flatpak_browser_id

    puts "#{Utils::INFO}Creating wrapper script for 1Password...#{Utils::NC}"
    wrapper_path = "#{Dir.home}/.var/app/#{flatpak_browser_id}/data/bin/1password-wrapper.sh"
    File.write(wrapper_path, <<~EOS
      #!/bin/bash
      if [ "\${container-}" = flatpak ]; then
        flatpak-spawn --host #{HOMEBREW_PREFIX}/bin/1Password-BrowserSupport "$@"
      else
        exec #{HOMEBREW_PREFIX}/bin/1Password-BrowserSupport "$@"
      fi
    EOS
    )
    system "chmod", "+x", wrapper_path

    puts "#{Utils::INFO}Creating a Native Messaging Hosts file for the 1Password extension to tell the browser to use the wrapper script...#{Utils::NC}"
    if browser_type == "chromium"
      native_messaging_dir = "#{Dir.home}/.var/app/#{flatpak_browser_id}/.config/google-chrome/NativeMessagingHosts"
    else
      native_messaging_dir = "#{Dir.home}/.var/app/#{flatpak_browser_id}/.mozilla/native-messaging-hosts"
    end

    puts "#{Utils::INFO}Creating native messaging host manifest...#{Utils::NC}"
    FileUtils.mkdir_p native_messaging_dir
    manifest_path = "#{native_messaging_dir}/com.1password.1password.json"

    allowed_extensions = if chromium_browsers.include?(flatpak_browser_id)
      Utils::ALLOWED_EXTENSIONS_CHROMIUM
    elsif firefox_browsers.include?(flatpak_browser_id)
      Utils::ALLOWED_EXTENSIONS_FIREFOX
    else
      puts "#{Utils::ERROR}Browser ID #{flatpak_browser_id} not recognized as Chromium-based or Firefox-based, aborting.#{Utils::NC}"
    end

    manifest_content = Utils.get_native_messaging_hosts_json(wrapper_path, allowed_extensions)
    if browser_type == "chromium"
      File.write(manifest_path, manifest_content)
    elsif browser_type == "firefox"
      File.write(manifest_path, manifest_content)
      if !Utils::BROWSERS_NOT_USING_MOZILLA.include?(flatpak_browser_id)
        puts "#{Utils::INFO}Some browsers, like Floorp and Zen, need the file in ~/.mozilla instead of in their own sandbox. This requires replacing the existing file $HOME/.mozilla/native-messaging-hosts/com.1password.1password.json with a custom one. Then, to prevent 1Password overwriting it, the file needs to be marked as read-only using chattr +i on it.#{Utils::NC}"
        FileUtils.mkdir_p Utils::GLOBAL_NATIVE_MESSAGING_PATH
        system "sudo", "chattr", "-i", Utils::GLOBAL_NATIVE_MESSAGING_PATH + "/com.1password.1password.json"
        File.write(Utils::GLOBAL_NATIVE_MESSAGING_PATH + "/com.1password.1password.json", manifest_content)
        system "flatpak", "override", "--user", "--filesystem=#{Utils::GLOBAL_NATIVE_MESSAGING_PATH}", flatpak_browser_id
        system "sudo", "chattr", "+i", Utils::GLOBAL_NATIVE_MESSAGING_PATH + "/com.1password.1password.json"
        puts "#{Utils::INFO}Created and locked #{Utils::GLOBAL_NATIVE_MESSAGING_PATH}/com.1password.1password.json#{Utils::NC}"

      end
    end

    puts "#{Utils::INFO}Adding Flatpaks to the list of supported browsers in 1Password...#{Utils::NC}"
    if File.exist?("/etc/1password")
      puts "#{Utils::INFO}Creating directory /etc/1password...#{Utils::NC}"
      system "sudo", "mkdir", "-p", "/etc/1password"
    end
    if !File.read("/etc/1password/custom_allowed_browsers").include?("flatpak-session-helper")
      puts "#{Utils::INFO}Adding to allowed browsers...#{Utils::NC}"
      puts "flatpak-session-helper", "|", "sudo", "tee", "-a", "/etc/1password/custom_allowed_browsers"
    else
      puts "#{Utils::INFO}Already added to allowed browsers...#{Utils::NC}"
    end
    puts "#{Utils::INFO}Installation complete. Please restart your browser to load the 1Password extension with Flatpak support.#{Utils::NC}"
  end
end
