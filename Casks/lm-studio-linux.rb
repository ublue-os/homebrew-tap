cask "lm-studio-linux" do
  version "0.4.24-1"
  sha256 "17cb8ac6374f9182fc127efae20680265e3c4c17d96eadf147eb5fe6111a9353"

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
    set_permissions "LM-Studio-{{version}}-x64.AppImage", "+x", recursive: false
    run "LM-Studio-{{version}}-x64.AppImage", args: ["--appimage-extract"],
                                           base: :staged_path, chdir: "{{staged_path}}"
    remove "LM-Studio-{{version}}-x64.AppImage"
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons", base: :home
    # The desktop file does not exist until the AppImage has been extracted.
    run "/bin/sed", args: ["-i", "s|^Exec=.*|Exec={{HOMEBREW_PREFIX}}/bin/lm-studio|",
                           "{{staged_path}}/squashfs-root/ai.elementlabs.lmstudio.desktop"]
  end

  zap trash: "~/.config/LMStudio"
end
