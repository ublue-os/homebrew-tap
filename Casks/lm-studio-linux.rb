cask "lm-studio-linux" do
  version "0.4.23-1"
  sha256 "c1bdf195281e25dc921af5c91eb2502035240dce1217140c43036d6cf3038fd8"

  url "https://installers.lmstudio.ai/linux/x64/#{version}/LM-Studio-#{version}-x64.AppImage"
  name "LM Studio"
  desc "Discover, download, and run local LLMs"
  homepage "https://lmstudio.ai/"

  livecheck do
    url "https://versions-prod.lmstudio.ai/update/linux/x86/#{version}"
    strategy :json do |json|
      version = json["version"]
      build = json["build"]
      next if version.blank? || build.blank?

      "#{version}-#{build}"
    end
  end

  depends_on formula: "squashfs"

  binary "squashfs-root/AppRun", target: "lm-studio"
  artifact "squashfs-root/usr/share/icons/hicolor/512x512/apps/lm-studio.png",
           target: "#{Dir.home}/.local/share/icons/lm-studio.png"
  artifact "squashfs-root/ai.elementlabs.lmstudio.desktop",
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

    desktop_content = File.read("#{staged_path}/squashfs-root/ai.elementlabs.lmstudio.desktop")
    desktop_content.gsub!(/^Exec=.*/, "Exec=#{HOMEBREW_PREFIX}/bin/lm-studio")
    File.write("#{staged_path}/squashfs-root/ai.elementlabs.lmstudio.desktop", desktop_content)
  end

  zap trash: "~/.config/LMStudio"
end
