cask "antigravity-linux" do
  arch arm: "arm", intel: "x64"

  version "1.18.4,5780041996042240"
  sha256 arm64_linux:  "eee54e88290cf4b0b8feb56283a04ab31ce4746465ca0bd1afd3e4505b2f95ea",
         x86_64_linux: "f97d790d1fb74e8ccb9ddb6af301a2b60391aed22f633f1a2baf86862aa65826"

  url "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/#{version.csv.first}-#{version.csv.second}/linux-#{arch}/Antigravity.tar.gz",
      verified: "edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/"
  name "Google Antigravity"
  desc "AI Coding Agent IDE"
  homepage "https://antigravity.google/"

  livecheck do
    url "https://antigravity-auto-updater-974169037036.us-central1.run.app/api/update/linux-x64/stable/latest"
    regex(%r{/stable/([^/]+)/}i)
    strategy :json do |json, regex|
      match = json["url"]&.match(regex)
      next if match.blank?

      match[1]&.tr("-", ",").to_s
    end
  end

  binary "#{staged_path}/Antigravity/bin/antigravity"
  binary "#{staged_path}/Antigravity/bin/antigravity", target: "agy"
  bash_completion "#{staged_path}/Antigravity/resources/completions/bash/antigravity"
  zsh_completion  "#{staged_path}/Antigravity/resources/completions/zsh/_antigravity"
  artifact "antigravity.desktop",
           target: "#{Dir.home}/.local/share/applications/antigravity.desktop"
  artifact "antigravity-url-handler.desktop",
           target: "#{Dir.home}/.local/share/applications/antigravity-url-handler.desktop"
  artifact "antigravity.png",
           target: "#{Dir.home}/.local/share/icons/hicolor/512x512/apps/antigravity.png"

  preflight do
    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    FileUtils.mkdir_p "#{Dir.home}/.local/share/icons/hicolor/512x512/apps"

    # Copy icon from extracted archive
    icon_path = "Antigravity/resources/app/out/vs/workbench/contrib/antigravityCustomAppIcon"
    icon_source = "#{staged_path}/#{icon_path}/browser/media/antigravity/antigravity.png"
    FileUtils.cp icon_source, "#{staged_path}/antigravity.png" if File.exist?(icon_source)

    File.write("#{staged_path}/antigravity.desktop", <<~EOS)
      [Desktop Entry]
      Name=Antigravity
      Comment=AI Coding Agent IDE
      GenericName=Text Editor
      Exec=#{HOMEBREW_PREFIX}/bin/antigravity %F
      Icon=#{Dir.home}/.local/share/icons/hicolor/512x512/apps/antigravity.png
      Type=Application
      StartupNotify=false
      StartupWMClass=Antigravity
      Categories=TextEditor;Development;IDE;
      MimeType=text/plain;inode/directory;application/x-code-workspace;
      Actions=new-empty-window;
      Keywords=antigravity;code;editor;ai;

      [Desktop Action new-empty-window]
      Name=New Empty Window
      Exec=#{HOMEBREW_PREFIX}/bin/antigravity --new-window %F
      Icon=#{Dir.home}/.local/share/icons/hicolor/512x512/apps/antigravity.png
    EOS

    File.write("#{staged_path}/antigravity-url-handler.desktop", <<~EOS)
      [Desktop Entry]
      Name=Antigravity - URL Handler
      Comment=AI Coding Agent IDE
      GenericName=Text Editor
      Exec=#{HOMEBREW_PREFIX}/bin/antigravity --open-url %U
      Icon=#{Dir.home}/.local/share/icons/hicolor/512x512/apps/antigravity.png
      Type=Application
      NoDisplay=true
      StartupNotify=true
      Categories=Utility;TextEditor;Development;IDE;
      MimeType=x-scheme-handler/antigravity;
      Keywords=antigravity;
    EOS

    # Create a placeholder icon if extraction fails
    FileUtils.touch "#{staged_path}/antigravity.png" unless File.exist?("#{staged_path}/antigravity.png")
  end

  zap trash: [
    "~/.antigravity",
    "~/.config/Antigravity",
  ]
end
