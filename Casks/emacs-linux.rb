cask "emacs-linux" do
  version "17962258335"
  sha256 "af5d317fcc974a354fb736843df52b630b049c694aa1bdb634948ce2b858242e"

  url "https://github.com/blahgeek/emacs-appimage/releases/download/github-action-build-#{version}/Emacs-master-gtk3-x86_64.AppImage"
  name "Emacs (master)"
  desc "GNU Emacs text editor"
  homepage "https://www.gnu.org/software/emacs/"

  auto_updates true
  depends_on formula: "squashfs"

  binary "squashfs-root/AppRun", target: "emacs"
  artifact "squashfs-root/share/icons/hicolor/128x128/apps/emacs.png",
           target: "#{Dir.home}/.local/share/icons/emacs.png"
  artifact "squashfs-root/emacs.desktop",
           target: "#{Dir.home}/.local/share/applications/emacs.desktop"

  preflight do
    # Extract AppImage contents
    appimage_path = "#{staged_path}/Emacs-master-gtk3-x86_64.AppImage"
    system "chmod", "+x", appimage_path
    system appimage_path, "--appimage-extract", chdir: staged_path

    # Remove the original AppImage to save space
    FileUtils.rm appimage_path

    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    FileUtils.mkdir_p "#{Dir.home}/.local/share/icons"

    desktop_content = File.read("#{staged_path}/squashfs-root/emacs.desktop")
    desktop_content.gsub!(/^Exec=.*/, "Exec=#{HOMEBREW_PREFIX}/bin/emacs")
    File.write("#{staged_path}/squashfs-root/emacs.desktop", desktop_content)
  end
end
