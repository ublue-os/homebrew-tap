cask "visual-studio-code-linux" do
  arch arm: "arm64", intel: "x64"
  os linux: "linux"

  version "1.145.3,dcd3ad6e368fbe19d03f37054a40dbaf40d676f4"
  sha256 arm:          "1fe639e74fb6eb64a081fafe352dbf978c9fe4f2b324822c5ee0d335b72ad961",
         intel:        "567e067c3ce043605af1b466e916173193100cf8c7da911b85e4c5c0869fe621",
         arm64_linux:  "1fe639e74fb6eb64a081fafe352dbf978c9fe4f2b324822c5ee0d335b72ad961",
         x86_64_linux: "567e067c3ce043605af1b466e916173193100cf8c7da911b85e4c5c0869fe621"

  url "https://update.code.visualstudio.com/commit:#{version.csv.second}/linux-#{arch}/stable"
  name "Microsoft Visual Studio Code"
  name "VS Code"
  desc "Open-source code editor"
  homepage "https://code.visualstudio.com/"

  livecheck do
    url "https://update.code.visualstudio.com/api/update/linux-#{arch}/stable/latest"
    strategy :json do |json|
      version = json["productVersion"]
      build = json["version"]
      next if version.blank? || build.blank?

      "#{version},#{build}"
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
    # Keep sandbox write declarations out of the not-yet-renamed directory.
    run "/bin/mv", args: ["{{staged_path}}/product.json", "{{staged_path}}/vscode/resources/app/product.json"]

    mkdir_p ".local/share/applications", base: :home
    write_file "code.desktop", <<~EOS
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
    write_file "code-url-handler.desktop", <<~EOS
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
    run "/bin/mv", args: ["{{staged_path}}/code.desktop", "{{staged_path}}/code-url-handler.desktop",
                          "{{staged_path}}/vscode/"]
  end

  zap trash: [
    "~/.config/Code",
    "~/.vscode",
  ]
end
