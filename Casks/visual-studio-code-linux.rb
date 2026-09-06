cask "visual-studio-code-linux" do
  arch arm: "arm64", intel: "x64"
  os linux: "linux"

  version "1.136.1"
  sha256 arm:          "2aac154ec452817e88c7b452b110f2cdbaad00af7bcf05ef7343891364e10c44",
         intel:        "9b4a54f0d49beaa413eda137d00c6541a639300d479efcac566ad13419409218",
         arm64_linux:  "2aac154ec452817e88c7b452b110f2cdbaad00af7bcf05ef7343891364e10c44",
         x86_64_linux: "9b4a54f0d49beaa413eda137d00c6541a639300d479efcac566ad13419409218"

  url "https://update.code.visualstudio.com/#{version}/linux-#{arch}/stable"
  name "Microsoft Visual Studio Code"
  name "VS Code"
  desc "Open-source code editor"
  homepage "https://code.visualstudio.com/"

  livecheck do
    url "https://update.code.visualstudio.com/api/update/linux-#{arch}/stable/latest"
    strategy :json do |json|
      json["productVersion"]
    end
  end

  depends_on formula: "jq"

  binary "vscode/bin/code"
  binary "vscode/bin/code-tunnel"
  bash_completion "vscode/resources/completions/bash/code"
  zsh_completion  "vscode/resources/completions/zsh/_code"
  artifact "vscode/code.desktop",
           target: "#{Dir.home}/.local/share/applications/code.desktop"
  artifact "vscode/code-url-handler.desktop",
           target: "#{Dir.home}/.local/share/applications/code-url-handler.desktop"

  preflight_steps do
    move "VSCode-linux-*", "vscode", source_glob: true
    # Parse JSON rather than relying on the upstream file's formatting.
    run "{{HOMEBREW_PREFIX}}/bin/jq",
        args:        ["del(.updateUrl) | .configurationDefaults[\"update.mode\"] = \"none\"",
                      "{{staged_path}}/vscode/resources/app/product.json"],
        stdout_path: "product.json"
    move "product.json", "vscode/resources/app/product.json"

    mkdir_p ".local/share/applications", base: :home
    write_file "vscode/code.desktop", <<~EOS
      [Desktop Entry]
      Name=Visual Studio Code
      Comment=Code Editing. Redefined.
      GenericName=Text Editor
      Exec={{HOMEBREW_PREFIX}}/bin/code %F
      Icon={{staged_path}}/vscode/resources/app/resources/linux/code.png
      Type=Application
      StartupNotify=false
      StartupWMClass=Code
      Categories=TextEditor;Development;IDE;
      MimeType=application/x-code-workspace;
      Actions=new-empty-window;
      Keywords=vscode;

      [Desktop Action new-empty-window]
      Name=New Empty Window
      Name[cs]=Nové prázdné okno
      Name[de]=Neues leeres Fenster
      Name[es]=Nueva ventana vacía
      Name[fr]=Nouvelle fenêtre vide
      Name[it]=Nuova finestra vuota
      Name[ja]=新しい空のウィンドウ
      Name[ko]=새 빈 창
      Name[ru]=Новое пустое окно
      Name[zh_CN]=新建空窗口
      Name[zh_TW]=開新空視窗
      Exec={{HOMEBREW_PREFIX}}/bin/code --new-window %F
      Icon={{staged_path}}/vscode/resources/app/resources/linux/code.png
    EOS
    write_file "vscode/code-url-handler.desktop", <<~EOS
      [Desktop Entry]
      Name=Visual Studio Code - URL Handler
      Comment=Code Editing. Redefined.
      GenericName=Text Editor
      Exec={{HOMEBREW_PREFIX}}/bin/code --open-url %U
      Icon={{staged_path}}/vscode/resources/app/resources/linux/code.png
      Type=Application
      NoDisplay=true
      StartupNotify=true
      Categories=Utility;TextEditor;Development;IDE;
      MimeType=x-scheme-handler/vscode;
      Keywords=vscode;
    EOS
  end

  zap trash: [
    "~/.config/Code",
    "~/.vscode",
  ]
end
