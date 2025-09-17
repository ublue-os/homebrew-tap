cask "lm-studio-linux" do
  version "0.3.26,6"
  sha256 "50a768a70fec32e5d8e3ad0a03d3a3f1c90035d143b76540a44b126751a1d56a"

  url "https://installers.lmstudio.ai/linux/x64/#{version.tr(",", "-")}/LM-Studio-#{version.tr(",", "-")}-x64.AppImage"
  name "LM Studio"
  desc "Discover, download, and run local LLMs"
  homepage "https://lmstudio.ai/"

  auto_updates true
  depends_on formula: "squashfs"

  binary "squashfs-root/AppRun", target: "lm-studio"

  preflight do
    # Extract AppImage contents
    appimage_path = "#{staged_path}/LM-Studio-#{version.tr(",", "-")}-x64.AppImage"
    system "chmod", "+x", appimage_path
    system appimage_path, "--appimage-extract", chdir: staged_path

    # Remove the original AppImage to save space
    FileUtils.rm appimage_path
  end

  postflight do
    # Set up desktop integration
    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    FileUtils.mkdir_p "#{Dir.home}/.local/share/icons"

    # Copy icon to user icon directory
    icon_source = "#{staged_path}/squashfs-root/usr/share/icons/hicolor/0x0/apps/lm-studio.png"
    icon_target = "#{Dir.home}/.local/share/icons/lm-studio.png"

    FileUtils.cp icon_source, icon_target if File.exist?(icon_source)

    source_desktop = "#{staged_path}/squashfs-root/lm-studio.desktop"
    target_desktop = "#{Dir.home}/.local/share/applications/lm-studio.desktop"

    if File.exist?(source_desktop)
      # Use bundled desktop file if available
      desktop_content = File.read(source_desktop)
      desktop_content.gsub!(/^Exec=.*/, "Exec=#{HOMEBREW_PREFIX}/bin/lm-studio")
      File.write(target_desktop, desktop_content)
    else
      # Fallback to custom desktop file
      File.write(target_desktop, <<~EOS)
        [Desktop Entry]
        Name=LM Studio
        Comment=Discover, download, and run local LLMs
        GenericName=LLM Manager
        Exec=#{HOMEBREW_PREFIX}/bin/lm-studio
        Icon=lm-studio
        Type=Application
        StartupNotify=false
        StartupWMClass=LM Studio
        Categories=Development;AI;
        Keywords=llm;ai;local;model;
      EOS
    end
  end

  zap trash: [
    "~/.config/LMStudio",
    "~/.local/share/applications/lm-studio.desktop",
    "~/.local/share/icons/lm-studio.png",
  ]
end
