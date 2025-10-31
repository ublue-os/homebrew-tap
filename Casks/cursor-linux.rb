cask "cursor-linux" do
  arch arm: "arm64", intel: "x64"

  version "0.44.9"
  sha256 arm64_linux:  "PLACEHOLDER_ARM64",
         x86_64_linux: "PLACEHOLDER_X64"

  url "https://downloader.cursor.sh/linux/appImage/#{arch}",
      verified: "cursor.sh"
  name "Cursor"
  desc "AI-first coding environment"
  homepage "https://www.cursor.com/"

  livecheck do
    url "https://www.cursor.com/api/latest-version"
    strategy :json do |json|
      json["version"]
    end
  end

  depends_on formula: "xdg-utils"

  binary "cursor.AppImage", target: "cursor"
  bash_completion "#{staged_path}/resources/completions/bash/cursor"
  zsh_completion  "#{staged_path}/resources/completions/zsh/_cursor"
  artifact "cursor.desktop",
           target: "#{Dir.home}/.local/share/applications/cursor.desktop"
  artifact "cursor.png",
           target: "#{Dir.home}/.local/share/icons/hicolor/512x512/apps/cursor.png"

  preflight do
    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    FileUtils.mkdir_p "#{Dir.home}/.local/share/icons/hicolor/512x512/apps"
    
    # Make AppImage executable
    FileUtils.chmod "+x", "#{staged_path}/cursor.AppImage"
    
    # Extract AppImage contents to get resources (icon, completions, etc.)
    system "#{staged_path}/cursor.AppImage", "--appimage-extract", chdir: staged_path
    
    # Copy extracted resources
    if Dir.exist?("#{staged_path}/squashfs-root/resources")
      FileUtils.cp_r "#{staged_path}/squashfs-root/resources", "#{staged_path}/"
      
      # Copy icon if it exists
      icon_path = Dir.glob("#{staged_path}/squashfs-root/*.png").first
      if icon_path
        FileUtils.cp icon_path, "#{staged_path}/cursor.png"
      end
    end
    
    File.write("#{staged_path}/cursor.desktop", <<~EOS)
      [Desktop Entry]
      Name=Cursor
      Comment=AI-first coding environment
      GenericName=Text Editor
      Exec=#{HOMEBREW_PREFIX}/bin/cursor %F
      Icon=#{Dir.home}/.local/share/icons/hicolor/512x512/apps/cursor.png
      Type=Application
      StartupNotify=false
      StartupWMClass=Cursor
      Categories=TextEditor;Development;IDE;
      MimeType=text/plain;inode/directory;application/x-code-workspace;
      Actions=new-empty-window;
      Keywords=cursor;code;editor;

      [Desktop Action new-empty-window]
      Name=New Empty Window
      Exec=#{HOMEBREW_PREFIX}/bin/cursor --new-window %F
      Icon=#{Dir.home}/.local/share/icons/hicolor/512x512/apps/cursor.png
    EOS
    
    # Create a placeholder icon if extraction fails
    unless File.exist?("#{staged_path}/cursor.png")
      FileUtils.touch "#{staged_path}/cursor.png"
    end
  end

  zap trash: [
    "~/.config/Cursor",
    "~/.cursor",
  ]
end
