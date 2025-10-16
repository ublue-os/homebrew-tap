module Utils
  INFO = "\e[0;36m".freeze    # Cyan for general information
  SUCCESS = "\e[0;32m".freeze # Green for success messages
  WARN = "\e[0;33m".freeze    # Yellow for warnings
  ERROR = "\e[0;31m".freeze   # Red for errors
  NC = "\e[0m".freeze         # No Color

  ALLOWED_EXTENSIONS_FIREFOX = '"allowed_extensions": [
      "{0a75d802-9aed-41e7-8daa-24c067386e82}",
      "{25fc87fa-4d31-4fee-b5c1-c32a7844c063}",
      "{d634138d-c276-4fc8-924b-40a0ea21d284}"
  ]'.freeze

  ALLOWED_EXTENSIONS_CHROMIUM = '"allowed_origins": [
      "chrome-extension://hjlinigoblmkhjejkmbegnoaljkphmgo/",
      "chrome-extension://gejiddohjgogedgjnonbofjigllpkmbf/",
      "chrome-extension://khgocmkkpikpnmmkgmdnfckapcdkgfaf/",
      "chrome-extension://aeblfdkhhhdcdjpifhhbdiojplfjncoa/",
      "chrome-extension://dppgmdbiimibapkepcbdbmkaabgiofem/"
  ]'.freeze

  def self.flatpak_package_list
    @flatpak_package_list ||= `flatpak list --app --columns=application`.split("\n").freeze
  end

  BROWSERS_NOT_USING_MOZILLA = [
    "org.mozilla.firefox",
    "io.gitlab.librewolf-community",
    "net.waterfox.waterfox",
  ].freeze

  CHROMIUM_BROWSERS = [
    "com.google.Chrome",
    "com.brave.Browser",
    "com.vivaldi.Vivaldi",
    "com.opera.Opera",
    "com.microsoft.Edge",
    "ru.yandex.Browser",
    "org.chromium.Chromium",
    "io.github.ungoogled_software.ungoogled_chromium",
  ].freeze

  FIREFOX_BROWSERS = [
    "org.mozilla.firefox",
    "one.ablaze.floorp",
    "io.gitlab.librewolf-community",
    "org.torproject.torbrowser-launcher",
    "app.zen_browser.zen",
    "org.garudalinux.firedragon",
    "net.mullvad.MullvadBrowser",
    "net.waterfox.waterfox",
  ].freeze

  GLOBAL_WRAPPER_PATH = "#{Dir.home}/.mozilla/native-messaging-hosts/1password-wrapper.sh".freeze
  GLOBAL_NATIVE_MESSAGING_PATH = "#{Dir.home}/.mozilla/native-messaging-hosts".freeze
  CONFIG_PATH = "#{Dir.home}/.config/1password-flatpak-browser-integration-config.json".freeze

  def self.replace_path_in_file(file_path, old_text, new_text)
    content = File.read(file_path)
    new_content = content.gsub(old_text, new_text)
    File.write(file_path, new_content)
  end

  def self.get_native_messaging_hosts_json(wrapper_path, allowed_extensions)
    <<~JSON
      {
        "name": "com.1password.1password",
        "description": "1Password BrowserSupport",
        "path": "#{wrapper_path}",
        "type": "stdio",
        #{allowed_extensions}
      }
    JSON
  end

  def self.list_flatpak_browsers(browsers)
    browsers.select { |browser| flatpak_package_list.include?(browser) }
  end

  def self.load_config
    return unless File.exist?(CONFIG_PATH)

    puts "#{INFO}Existing configuration file found at #{CONFIG_PATH}, loading...#{NC}"
    config = JSON.parse(File.read(CONFIG_PATH))

    unless flatpak_package_list.include?(config["flatpak_browser_id"])
      puts "#{WARN}Browser ID #{config["flatpak_browser_id"]} from config not found in installed Flatpak applications, please re-run the installation to select a valid browser.#{NC}"
      exit 1
    end

    %w[flatpak_browser_id browser_type wrapper_path manifest_path].each do |key|
      puts "#{INFO}Using #{key.tr("_", " ")}: #{config[key]} from config.#{NC}"
    end

    config
  end

  def self.get_browser_lists
    {
      chromium: list_flatpak_browsers(CHROMIUM_BROWSERS),
      firefox:  list_flatpak_browsers(FIREFOX_BROWSERS),
    }
  end

  def self.display_browsers(browser_lists)
    puts "#{INFO}Detected Chromium-based browsers (incomplete list):#{NC}"
    puts browser_lists[:chromium].empty? ? "None" : browser_lists[:chromium].join("\n")

    puts "#{INFO}Detected Firefox-based browsers (incomplete list):#{NC}"
    puts browser_lists[:firefox].empty? ? "None" : browser_lists[:firefox].join("\n")
  end

  def self.get_user_browser_id
    puts "#{INFO}Enter the name of your browser's Flatpak application ID (e.g. com.google.Chrome): #{NC}"
    browser_id = `read -r flatpak_browser_id && echo $flatpak_browser_id`.chomp

    if browser_id.empty?
      puts "#{ERROR}No browser ID entered, aborting.#{NC}"
      exit 1
    end

    unless flatpak_package_list.include?(browser_id)
      puts "#{ERROR}Browser ID #{browser_id} not found in installed Flatpak applications, aborting.#{NC}"
      exit 1
    end

    puts "#{INFO}Using browser ID: #{browser_id}#{NC}"
    browser_id
  end

  def self.determine_browser_type(browser_id, browser_lists)
    if browser_lists[:chromium].include?(browser_id)
      "chromium"
    elsif browser_lists[:firefox].include?(browser_id)
      "firefox"
    else
      puts "#{WARN}Browser ID #{browser_id} not recognized as Chromium-based or Firefox-based, please enter manually: chromium or firefox#{NC}"
      manual_type = `read -r manual_type && echo $manual_type`.chomp

      unless %w[chromium firefox].include?(manual_type)
        puts "#{ERROR}Invalid browser type entered, aborting.#{NC}"
        exit 1
      end

      manual_type
    end
  end

  def self.get_wrapper_script_content
    <<~BASH
      #!/bin/bash
      if [ "${container-}" = flatpak ]; then
        flatpak-spawn --host #{HOMEBREW_PREFIX}/bin/1Password-BrowserSupport "$@"
      else
        exec #{HOMEBREW_PREFIX}/bin/1Password-BrowserSupport "$@"
      fi
    BASH
  end

  def self.create_wrapper_script(browser_id)
    wrapper_path = "#{Dir.home}/.var/app/#{browser_id}/data/bin/1password-wrapper.sh"
    puts "#{INFO}Creating wrapper script for 1Password...#{NC}"

    File.write(wrapper_path, get_wrapper_script_content)
    system "chmod", "+x", wrapper_path

    wrapper_path
  end

  def self.get_native_messaging_dir(browser_type, browser_id)
    if browser_type == "chromium"
      # Find Chromium native messaging directory
      chromium_dir = Dir.glob("#{Dir.home}/.var/app/#{browser_id}/config/**/NativeMessagingHosts").first
      chromium_dir || "#{Dir.home}/.var/app/#{browser_id}/.config/google-chrome/NativeMessagingHosts"
    else
      find_firefox_native_messaging_dir(browser_id)
    end
  end

  def self.create_manifest_path(browser_type, browser_id)
    puts "#{INFO}Creating a Native Messaging Hosts file for the 1Password extension to tell the browser to use the wrapper script...#{NC}"
    native_messaging_dir = get_native_messaging_dir(browser_type, browser_id)

    puts "#{INFO}Creating native messaging host manifest...#{NC}"
    FileUtils.mkdir_p(native_messaging_dir)

    "#{native_messaging_dir}/com.1password.1password.json"
  end

  def self.get_allowed_extensions(browser_id, browser_lists)
    if browser_lists[:chromium].include?(browser_id)
      ALLOWED_EXTENSIONS_CHROMIUM
    elsif browser_lists[:firefox].include?(browser_id)
      ALLOWED_EXTENSIONS_FIREFOX
    else
      puts "#{ERROR}Browser ID #{browser_id} not recognized as Chromium-based or Firefox-based, aborting.#{NC}"
      exit 1
    end
  end

  def self.handle_firefox_global_manifest(browser_id, _manifest_content, wrapper_path)
    return if BROWSERS_NOT_USING_MOZILLA.include?(browser_id)

    global_manifest_path = "#{GLOBAL_NATIVE_MESSAGING_PATH}/com.1password.1password.json"

    # Check if the global manifest is already correctly set up
    if is_native_messaging_host_correct(GLOBAL_WRAPPER_PATH, ALLOWED_EXTENSIONS_FIREFOX,
                                        GLOBAL_NATIVE_MESSAGING_PATH, true)
      puts "#{INFO}Already added to #{global_manifest_path}#{NC}"
      return
    end

    puts "#{INFO}Setting up global Mozilla manifest...#{NC}"

    # Copy wrapper script to global location
    FileUtils.mkdir_p(File.dirname(GLOBAL_WRAPPER_PATH))
    FileUtils.cp(wrapper_path, GLOBAL_WRAPPER_PATH)

    # Set up filesystem access
    system "flatpak", "override", "--user", "--filesystem=#{GLOBAL_NATIVE_MESSAGING_PATH}", browser_id

    # Remove immutable flag if it exists, create manifest, then make it immutable
    FileUtils.mkdir_p(GLOBAL_NATIVE_MESSAGING_PATH)
    system "sudo", "chattr", "-i", global_manifest_path, "2>/dev/null"

    global_manifest_content = get_native_messaging_hosts_json(GLOBAL_WRAPPER_PATH, ALLOWED_EXTENSIONS_FIREFOX)
    File.write(global_manifest_path, global_manifest_content)

    puts "#{INFO}Marking #{global_manifest_path} as read-only using chattr +i. To undo, run this command:#{NC}"
    puts "#{INFO}sudo chattr -i #{global_manifest_path}#{NC}"
    system "sudo", "chattr", "+i", global_manifest_path

    puts "#{INFO}Created and locked #{global_manifest_path}#{NC}"
  end

  def self.setup_1password_allowed_browsers
    puts "#{INFO}Adding Flatpaks to the list of supported browsers in 1Password#{NC}"
    puts "Note: This requires sudo permissions. If this doesn't work, append flatpak-session-helper to the file /etc/1password/custom_allowed_browsers"

    unless File.exist?("/etc/1password")
      puts "#{INFO}Creating directory /etc/1password...#{NC}"
      system "sudo", "mkdir", "-p", "/etc/1password"
    end

    allowed_browsers_file = "/etc/1password/custom_allowed_browsers"

    if File.exist?(allowed_browsers_file) && File.read(allowed_browsers_file).include?("flatpak-session-helper")
      puts "#{INFO}Already added to allowed browsers#{NC}"
    else
      puts "#{INFO}Adding to allowed browsers...#{NC}"
      success = system "echo 'flatpak-session-helper' | sudo tee -a '#{allowed_browsers_file}' >/dev/null"

      unless success
        puts "#{ERROR}Failed to add to allowed browsers. You may need to manually add 'flatpak-session-helper' to #{allowed_browsers_file}#{NC}"
      end
    end
  end

  def self.save_config(config_data)
    File.write(CONFIG_PATH, JSON.pretty_generate(config_data))
  end

  def self.is_firefox_dir(dir)
    return false unless Dir.exist?(dir)
    return false if %w[.. cache .cache].include?(File.basename(dir))

    File.exist?(File.join(dir, "profiles.ini"))
  end

  def self.find_firefox_native_messaging_dir(browser_id)
    app_dir = "#{Dir.home}/.var/app/#{browser_id}"

    # Search through directories in the app folder
    Dir.glob("#{app_dir}/*").each do |dir|
      next unless Dir.exist?(dir)

      return "#{dir}/native-messaging-hosts" if is_firefox_dir(dir)

      # Check subdirectories (like .mozilla/firefox)
      Dir.glob("#{dir}/*").each do |subdir|
        next unless Dir.exist?(subdir)

        if is_firefox_dir(subdir)
          # Firefox puts native-messaging-hosts in .mozilla, not .mozilla/firefox
          return "#{dir}/native-messaging-hosts"
        end
      end
    end

    # Fallback to default location
    "#{app_dir}/.mozilla/native-messaging-hosts"
  end

  def self.is_native_messaging_host_correct(wrapper_path, allowed_extensions, native_messaging_dir,
                                            should_be_immutable = false)
    manifest_file = "#{native_messaging_dir}/com.1password.1password.json"

    # Check if files exist
    return false unless File.exist?(manifest_file) && File.exist?(wrapper_path)

    # Check if file should be immutable
    if should_be_immutable
      attrs = `lsattr "#{manifest_file}" 2>/dev/null`.chomp
      return false if attrs[4] != "i" # 5th character indicates immutable
    end

    # Check contents
    current_content = File.read(manifest_file)
    expected_content = get_native_messaging_hosts_json(wrapper_path, allowed_extensions)

    current_content == expected_content
  end

  def self.display_security_warning
    puts "This script will help you set up 1Password in a Flatpak browser."
    puts "#{WARN}Note: It will make it possible for any Flatpak application to integrate, not just some. Consider if you find this worth the risk.#{NC}"
    puts
  end

  def self.verify_final_setup
    allowed_browsers_file = "/etc/1password/custom_allowed_browsers"

    if File.exist?(allowed_browsers_file) && File.read(allowed_browsers_file).include?("flatpak-session-helper")
      puts "#{SUCCESS}Success! 1Password should now work in your Flatpak browser.#{NC}"
      puts "Now, restart both your browser and 1Password."
      true
    else
      puts "#{ERROR}ERROR: Could not add to allowed browsers#{NC}"
      false
    end
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
    # Display security warning
    Utils.display_security_warning

    # Load existing config or gather user input
    config = Utils.load_config
    browser_lists = Utils.get_browser_lists

    if config
      flatpak_browser_id = config["flatpak_browser_id"]
      browser_type = config["browser_type"]
      wrapper_path = config["wrapper_path"]
      manifest_path = config["manifest_path"]
    else
      Utils.display_browsers(browser_lists)
      flatpak_browser_id = Utils.get_user_browser_id
      browser_type = Utils.determine_browser_type(flatpak_browser_id, browser_lists)
    end

    puts

    # Set up flatpak permissions
    puts "#{Utils::INFO}Giving your browser permission to run programs outside the sandbox#{Utils::NC}"
    system "flatpak", "override", "--user", "--talk-name=org.freedesktop.Flatpak", flatpak_browser_id

    # Create wrapper script and manifest path for new installations
    if config
      puts "#{Utils::INFO}Using existing wrapper script and manifest from config...#{Utils::NC}"
    else
      wrapper_path = Utils.create_wrapper_script(flatpak_browser_id)
      manifest_path = Utils.create_manifest_path(browser_type, flatpak_browser_id)
    end

    # Validate that the native messaging directory was found
    if manifest_path.blank?
      puts "#{Utils::ERROR}ERROR: Could not find Native Messaging Hosts directory#{Utils::NC}"
      exit 1
    end

    # Create and write manifest content
    allowed_extensions = Utils.get_allowed_extensions(flatpak_browser_id, browser_lists)
    manifest_content = Utils.get_native_messaging_hosts_json(wrapper_path, allowed_extensions)
    File.write(manifest_path, manifest_content)

    # Handle Firefox-specific global manifest requirements
    if browser_type == "firefox"
      Utils.handle_firefox_global_manifest(flatpak_browser_id, manifest_content, wrapper_path)
    end

    puts

    # Set up 1Password allowed browsers
    Utils.setup_1password_allowed_browsers

    puts

    # Verify final setup and display results
    if Utils.verify_final_setup
      # Save configuration for future use (only if it doesn't exist)
      unless config
        Utils.save_config({
          "flatpak_browser_id" => flatpak_browser_id,
          "browser_type"       => browser_type,
          "wrapper_path"       => wrapper_path,
          "manifest_path"      => manifest_path,
        })
      end
    else
      exit 1
    end
  end

  uninstall_preflight do
    FileUtils.rm(Utils::CONFIG_PATH)
  end
end
