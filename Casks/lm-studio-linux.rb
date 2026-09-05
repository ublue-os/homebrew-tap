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

  preflight_steps do
    # Extract AppImage contents
    set_permissions "LM-Studio-{{version}}-x64.AppImage", "+x"
    run "./LM-Studio-{{version}}-x64.AppImage", args: ["--appimage-extract"], chdir: :staged_path

    # Remove the original AppImage to save space
    remove "LM-Studio-{{version}}-x64.AppImage"

    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons", base: :home

    inreplace "squashfs-root/ai.elementlabs.lmstudio.desktop", /^Exec=.*/, "Exec={{HOMEBREW_PREFIX}}/bin/lm-studio"
  end

  zap trash: "~/.config/LMStudio"
end
