cask "lm-studio-linux" do
  version "0.3.26-6"
  sha256 "50a768a70fec32e5d8e3ad0a03d3a3f1c90035d143b76540a44b126751a1d56a"

  url "https://installers.lmstudio.ai/linux/x64/#{version}/LM-Studio-#{version}-x64.AppImage"
  name "LM Studio"
  desc "Discover, download, and run local LLMs"
  homepage "https://lmstudio.ai/"

  auto_updates true
  depends_on formula: "squashfs"

  binary "squashfs-root/AppRun", target: "lm-studio"
  artifact "squashfs-root/usr/share/icons/hicolor/0x0/apps/lm-studio.png",
           target: "#{Dir.home}/.local/share/icons/lm-studio.png"
  artifact "squashfs-root/lm-studio.desktop",
           target: "#{Dir.home}/.local/share/applications/lm-studio.desktop"

  preflight do
    # Extract AppImage contents
    appimage_path = "#{staged_path}/LM-Studio-#{version}-x64.AppImage"
    system "chmod", "+x", appimage_path
    system appimage_path, "--appimage-extract", chdir: staged_path

    # Remove the original AppImage to save space
    FileUtils.rm appimage_path

    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    FileUtils.mkdir_p "#{Dir.home}/.local/share/icons"

    desktop_content = File.read("#{staged_path}/squashfs-root/lm-studio.desktop")
    desktop_content.gsub!(/^Exec=.*/, "Exec=#{HOMEBREW_PREFIX}/bin/lm-studio")
    File.write("#{staged_path}/squashfs-root/lm-studio.desktop", desktop_content)
  end

  zap trash: "~/.config/LMStudio"
end
