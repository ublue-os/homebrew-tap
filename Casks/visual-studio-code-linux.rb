cask "visual-studio-code-linux" do
  arch arm: "arm64", intel: "x64"
  os linux: "linux"

  version "1.139.0,2242ebbb54efeeb0129e08e919e7e8d43033cd83"
  sha256 arm:          "7a8dfc162a670478d4d699e67c5a0172ffa2f8b23e42e46026a32a4546f57c9a",
         intel:        "ef18461d14d658255917ea978cdccb20576f797af8d9f6062e6ac5afa9f5ec51",
         arm64_linux:  "7a8dfc162a670478d4d699e67c5a0172ffa2f8b23e42e46026a32a4546f57c9a",
         x86_64_linux: "ef18461d14d658255917ea978cdccb20576f797af8d9f6062e6ac5afa9f5ec51"

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
