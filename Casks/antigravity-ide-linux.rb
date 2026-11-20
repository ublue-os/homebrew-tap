cask "antigravity-ide-linux" do
  arch arm: "arm", intel: "x64"
  os linux: "linux"

  version "2.8.0,6733682917113856"
  sha256 arm:          "d8f85ce40306587a80a7478af4de85cb10b83cf26dd9179b902afa9933fcf9f2",
         intel:        "7baa36baab285cb46101af958b8f7be6305458db9a44d8b3d0938d61f38597d7",
         arm64_linux:  "d8f85ce40306587a80a7478af4de85cb10b83cf26dd9179b902afa9933fcf9f2",
         x86_64_linux: "7baa36baab285cb46101af958b8f7be6305458db9a44d8b3d0938d61f38597d7"

  url "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/#{version.csv.first}-#{version.csv.second}/linux-#{arch}/Antigravity%20IDE.tar.gz"
  name "Google Antigravity IDE"
  desc "AI Coding Agent IDE"
  homepage "https://antigravity.google/product/antigravity-ide"

  livecheck do
    url "https://antigravity-ide-auto-updater-974169037036.us-central1.run.app/api/update/linux-#{(arch == "arm") ? "arm64" : "x64"}/stable/latest"
    regex(%r{/stable/([^/]+)/}i)
    strategy :json do |json, regex|
      match = json["url"]&.match(regex)
      next if match.blank?

      match[1]&.tr("-", ",").to_s
    end
  end

  binary "#{staged_path}/Antigravity IDE/bin/antigravity-ide"
  binary "#{staged_path}/Antigravity IDE/bin/antigravity-ide", target: "agy-ide"
  bash_completion "#{staged_path}/Antigravity IDE/resources/completions/bash/antigravity-ide"
  zsh_completion  "#{staged_path}/Antigravity IDE/resources/completions/zsh/_antigravity-ide"
  artifact "antigravity-ide.desktop",
           target: "#{Dir.home}/.local/share/applications/antigravity-ide.desktop"
  artifact "antigravity-ide-url-handler.desktop",
           target: "#{Dir.home}/.local/share/applications/antigravity-ide-url-handler.desktop"
  artifact "Antigravity IDE/resources/app/resources/linux/code.png",
           target: "#{Dir.home}/.local/share/icons/hicolor/512x512/apps/antigravity-ide.png"

  preflight_steps do
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons/hicolor/512x512/apps", base: :home

    write_file "antigravity-ide.desktop", <<~EOS
      [Desktop Entry]
      Name=Antigravity IDE
      Comment=AI Coding Agent IDE
      GenericName=Text Editor
      Exec="{{HOMEBREW_PREFIX}}/bin/antigravity-ide" %F
      Icon=antigravity-ide
      Type=Application
      StartupNotify=false
      StartupWMClass=Antigravity IDE
      Categories=TextEditor;Development;IDE;
      MimeType=text/plain;inode/directory;application/x-code-workspace;x-scheme-handler/antigravity-ide;
      Actions=new-empty-window;
      Keywords=antigravity;code;editor;ai;

      [Desktop Action new-empty-window]
      Name=New Empty Window
      Exec="{{HOMEBREW_PREFIX}}/bin/antigravity-ide" --new-window %F
      Icon=antigravity-ide
    EOS

    write_file "antigravity-ide-url-handler.desktop", <<~EOS
      [Desktop Entry]
      Name=Antigravity IDE - URL Handler
      Comment=AI Coding Agent IDE
      GenericName=Text Editor
      Exec="{{HOMEBREW_PREFIX}}/bin/antigravity-ide" --open-url "%U"
      Icon=antigravity-ide
      Type=Application
      NoDisplay=true
      Terminal=false
      StartupNotify=true
      StartupWMClass=Antigravity IDE
      Categories=Utility;TextEditor;Development;IDE;
      MimeType=x-scheme-handler/antigravity-ide;
      Keywords=antigravity;code;editor;ai;
    EOS
  end

  zap trash: [
    "~/.antigravity-ide",
    "~/.antigravity-ide-server",
    "~/.config/Antigravity IDE",
    "~/.config/antigravity-ide",
    "~/.gemini/antigravity-ide",
  ]

  caveats <<~EOS
    If authentication fails or the browser doesn't open Antigravity IDE, try running:
      xdg-mime default antigravity-ide-url-handler.desktop x-scheme-handler/antigravity-ide
      update-desktop-database ~/.local/share/applications
  EOS
end
