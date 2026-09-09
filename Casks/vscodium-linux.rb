cask "vscodium-linux" do
  arch arm: "arm64", intel: "x64"
  os linux: "linux"

  version "1.135.06055"
  sha256 arm:          "9765cea4f707ff7dc83a40be408a7318a59abb6996b359631639d9aab2f48a90",
         intel:        "c09d8ac8dd7f52b09ee159ee24b440541dfd8f937a0f6f88cc428c78e48ee1f2",
         arm64_linux:  "9765cea4f707ff7dc83a40be408a7318a59abb6996b359631639d9aab2f48a90",
         x86_64_linux: "c09d8ac8dd7f52b09ee159ee24b440541dfd8f937a0f6f88cc428c78e48ee1f2"

  url "https://github.com/VSCodium/vscodium/releases/download/#{version}/VSCodium-linux-#{arch}-#{version}.tar.gz"
  name "VSCodium"
  desc "Open-source code editor"
  homepage "https://vscodium.com/"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on formula: "jq"

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

  preflight_steps do
    if_path_exists "resources/app/product.json" do
      run "{{HOMEBREW_PREFIX}}/bin/jq",
          args:        ["del(.updateUrl) | .configurationDefaults[\"update.mode\"] = \"none\"",
                        "{{staged_path}}/resources/app/product.json"],
          stdout_path: "product.json"
      move "product.json", "resources/app/product.json"
    end

    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons", base: :home

    write_file "codium.desktop", <<~EOS
      [Desktop Entry]
      Name=VSCodium
      Comment=Code Editing. Redefined.
      GenericName=Text Editor
      Exec={{HOMEBREW_PREFIX}}/bin/codium %F
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
      Exec={{HOMEBREW_PREFIX}}/bin/codium --new-window %F
      Icon=vscodium
    EOS
    write_file "codium-url-handler.desktop", <<~EOS
      [Desktop Entry]
      Name=VSCodium - URL Handler
      Comment=Code Editing. Redefined.
      GenericName=Text Editor
      Exec={{HOMEBREW_PREFIX}}/bin/codium --open-url %U
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
