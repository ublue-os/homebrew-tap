cask "visual-studio-code-linux" do
  arch arm: "arm64", intel: "x64"
  os linux: "linux"

  version "1.124.0"
  sha256 arm64_linux:  "289fcb31f00723a01e87144b95af650718c5143d344e61cc0c0e63ca5d3c18be",
         x86_64_linux: "79488ea5224271d0de4a4dcd46fe1fc4ddd14ab1b86b1181e94e738790c46577"

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

  binary "VSCode-linux-#{arch}/bin/code"
  binary "VSCode-linux-#{arch}/bin/code-tunnel"
  bash_completion "#{staged_path}/VSCode-linux-#{arch}/resources/completions/bash/code"
  zsh_completion  "#{staged_path}/VSCode-linux-#{arch}/resources/completions/zsh/_code"
  artifact "VSCode-linux-#{arch}/code.desktop",
           target: "#{Dir.home}/.local/share/applications/code.desktop"
  artifact "VSCode-linux-#{arch}/code-url-handler.desktop",
           target: "#{Dir.home}/.local/share/applications/code-url-handler.desktop"

  preflight do
    # Disable VS Code's built-in update checks; Homebrew manages this install.
    product_json = "#{staged_path}/VSCode-linux-#{arch}/resources/app/product.json"
    product = JSON.parse(File.read(product_json))
    product.delete("updateUrl")
    product["configurationDefaults"] ||= {}
    product["configurationDefaults"]["update.mode"] = "none"
    File.write(product_json, JSON.pretty_generate(product))

    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    File.write("#{staged_path}/VSCode-linux-#{arch}/code.desktop", <<~EOS)
      [Desktop Entry]
      Name=Visual Studio Code
      Comment=Code Editing. Redefined.
      GenericName=Text Editor
      Exec=#{HOMEBREW_PREFIX}/bin/code %F
      Icon=#{staged_path}/VSCode-linux-#{arch}/resources/app/resources/linux/code.png
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
      Exec=#{HOMEBREW_PREFIX}/bin/code --new-window %F
      Icon=#{staged_path}/VSCode-linux-#{arch}/resources/app/resources/linux/code.png
    EOS
    File.write("#{staged_path}/VSCode-linux-#{arch}/code-url-handler.desktop", <<~EOS)
      [Desktop Entry]
      Name=Visual Studio Code - URL Handler
      Comment=Code Editing. Redefined.
      GenericName=Text Editor
      Exec=#{HOMEBREW_PREFIX}/bin/code --open-url %U
      Icon=#{staged_path}/VSCode-linux-#{arch}/resources/app/resources/linux/code.png
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
