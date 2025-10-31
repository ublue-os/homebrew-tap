cask "cursor-linux" do
  arch arm: "arm64", intel: "x64"
  arch_suffix arm: "aarch64", intel: "x86_64"

  version "2.0.43"
  commit_sha "8e4da76ad196925accaa169efcae28c45454cce3"
  sha256 arm64_linux:  "PLACEHOLDER_ARM64",
         x86_64_linux: "PLACEHOLDER_X64"

  url "https://downloads.cursor.com/production/#{commit_sha}/linux/#{arch}/Cursor-#{version}-#{arch_suffix}.AppImage",
      verified: "downloads.cursor.com/"
  name "Cursor"
  desc "AI-first coding environment"
  homepage "https://www.cursor.com/"

  livecheck do
    url "https://api2.cursor.sh/updates/api/update/linux-x64/cursor/1.0.0/hash/stable"
    strategy :json do |json|
      json["version"]
    end
  end

  binary "Cursor-#{version}-#{arch_suffix}.AppImage", target: "cursor"
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
    FileUtils.chmod "+x", "#{staged_path}/Cursor-#{version}-#{arch_suffix}.AppImage"

    # Extract AppImage contents to get resources (icon, completions, etc.)
    system "#{staged_path}/Cursor-#{version}-#{arch_suffix}.AppImage", "--appimage-extract", chdir: staged_path

    # Copy extracted resources
    if Dir.exist?("#{staged_path}/squashfs-root/resources")
      FileUtils.cp_r "#{staged_path}/squashfs-root/resources", "#{staged_path}/"

      # Copy icon if it exists
      icon_path = Dir.glob("#{staged_path}/squashfs-root/*.png").first
      FileUtils.cp icon_path, "#{staged_path}/cursor.png" if icon_path
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
    FileUtils.touch "#{staged_path}/cursor.png" unless File.exist?("#{staged_path}/cursor.png")
  end

  zap trash: [
    "~/.config/Cursor",
    "~/.cursor",
  ]
end
