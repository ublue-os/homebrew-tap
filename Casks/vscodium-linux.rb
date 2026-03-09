cask "vscodium-linux" do
  arch arm: "arm64", intel: "x64"
  os linux: "linux"

  version "1.110.11631"
  sha256 arm64_linux:  "e69ad9f513bcb0fbf83ee9c0ab0a395a373bf80a5f185e457d611a8b40626aac",
         x86_64_linux: "c76527d3ce480654d3bbdf1fbf567e20dbbc50346db5b6cd24c649dd17873cd1"

  url "https://github.com/VSCodium/vscodium/releases/download/#{version}/VSCodium-linux-#{arch}-#{version}.tar.gz"
  name "VSCodium"
  desc "Open-source code editor"
  homepage "https://vscodium.com/"

  livecheck do
    url :url
    strategy :github_latest
  end

  binary "bin/codium"
  binary "bin/codium-tunnel"
  bash_completion "resources/completions/bash/codium"
  zsh_completion  "resources/completions/zsh/_codium"
  artifact "codium.desktop",
           target: "#{Dir.home}/.local/share/applications/codium.desktop"
  artifact "codium-url-handler.desktop",
           target: "#{Dir.home}/.local/share/applications/codium-url-handler.desktop"
  artifact "resources/app/resources/linux/code.png",
           target: "#{Dir.home}/.local/share/icons/vscodium.png"

  preflight do
    FileUtils.mkdir_p("#{Dir.home}/.local/share/applications")
    FileUtils.mkdir_p("#{Dir.home}/.local/share/icons")

    File.write("#{staged_path}/codium.desktop", <<~EOS)
      [Desktop Entry]
      Name=VSCodium
      Comment=Code Editing. Redefined.
      GenericName=Text Editor
      Exec=#{HOMEBREW_PREFIX}/bin/codium %F
      Icon=vscodium
      Type=Application
      StartupNotify=false
      StartupWMClass=VSCodium
      Categories=TextEditor;Development;IDE;
      MimeType=text/plain;inode/directory;application/x-codium-workspace;
      Actions=new-empty-window;
      Keywords=vscodium;codium;vscode;

      [Desktop Action new-empty-window]
      Name=New Empty Window
      Name[de]=Neues leeres Fenster
      Name[es]=Nueva ventana vacía
      Name[fr]=Nouvelle fenêtre vide
      Name[it]=Nuova finestra vuota
      Name[ja]=新しい空のウィンドウ
      Name[ko]=새 빈 창
      Name[ru]=Новое пустое окно
      Name[zh_CN]=新建空窗口
      Name[zh_TW]=開新空視窗
      Exec=#{HOMEBREW_PREFIX}/bin/codium --new-window %F
      Icon=vscodium
    EOS
    File.write("#{staged_path}/codium-url-handler.desktop", <<~EOS)
      [Desktop Entry]
      Name=VSCodium - URL Handler
      Comment=Code Editing. Redefined.
      GenericName=Text Editor
      Exec=#{HOMEBREW_PREFIX}/bin/codium --open-url %U
      Icon=vscodium
      Type=Application
      NoDisplay=true
      StartupNotify=true
      Categories=Utility;TextEditor;Development;IDE;
      MimeType=x-scheme-handler/vscodium;
      Keywords=vscodium;codium;vscode;
    EOS
  end

  zap trash: [
    "#{Dir.home}/.config/Codium",
    "#{Dir.home}/.vscodium",
  ]
end
