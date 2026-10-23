cask "visual-studio-code-linux@insiders" do
  arch arm: "arm64", intel: "x64"
  os linux: "linux"

  version "1.144.0-insider,58173d0ebc1838579e3c331e0a47e365904a6456"
  sha256 arm:          "5a6e912c698d327642425a3fb7882af5ca01f17131e8679b5fa9ba3e85151e26",
         intel:        "0986a1159a860f9e03d4294eed80df03d2844c1a8459ce9c6c25cb70ba0ccae1",
         arm64_linux:  "5a6e912c698d327642425a3fb7882af5ca01f17131e8679b5fa9ba3e85151e26",
         x86_64_linux: "0986a1159a860f9e03d4294eed80df03d2844c1a8459ce9c6c25cb70ba0ccae1"

  url "https://update.code.visualstudio.com/commit:#{version.csv.second}/linux-#{arch}/insider"
  name "Microsoft Visual Studio Code Insiders"
  name "VS Code Insiders"
  desc "Open-source code editor (Insiders build)"
  homepage "https://code.visualstudio.com/insiders/"

  livecheck do
    url "https://update.code.visualstudio.com/api/update/linux-#{arch}/insider/latest"
    strategy :json do |json|
      version = json["productVersion"]
      build = json["version"]
      next if version.blank? || build.blank?

      "#{version},#{build}"
    end
  end

  depends_on formula: "jq"

  binary "vscode-insiders/bin/code-insiders"
  binary "vscode-insiders/bin/code-tunnel-insiders"
  bash_completion "vscode-insiders/resources/completions/bash/code-insiders"
  zsh_completion  "vscode-insiders/resources/completions/zsh/_code-insiders"
  artifact "vscode-insiders/code-insiders.desktop",
           target: "#{Dir.home}/.local/share/applications/code-insiders.desktop"
  artifact "vscode-insiders/code-insiders-url-handler.desktop",
           target: "#{Dir.home}/.local/share/applications/code-insiders-url-handler.desktop"

  preflight_steps do
    move "VSCode-linux-*", "vscode-insiders", source_glob: true
    run "{{HOMEBREW_PREFIX}}/bin/jq",
        args:        ["del(.updateUrl) | .configurationDefaults[\"update.mode\"] = \"none\"",
                      "{{staged_path}}/vscode-insiders/resources/app/product.json"],
        stdout_path: "product.json"
    # Keep sandbox write declarations out of the not-yet-renamed directory.
    run "/bin/mv",
        args: ["{{staged_path}}/product.json", "{{staged_path}}/vscode-insiders/resources/app/product.json"]

    mkdir_p ".local/share/applications", base: :home
    write_file "code-insiders.desktop", <<~EOS
      [Desktop Entry]
      Name=Visual Studio Code - Insiders
      Comment=Code Editing. Redefined.
      GenericName=Text Editor
      Exec={{HOMEBREW_PREFIX}}/bin/code-insiders %F
      Icon={{staged_path}}/vscode-insiders/resources/app/resources/linux/code.png
      Type=Application
      StartupNotify=false
      StartupWMClass=Code - Insiders
      Categories=TextEditor;Development;IDE;
      MimeType=application/x-code-workspace;
      Actions=new-empty-window;
      Keywords=vscode;

      [Desktop Action new-empty-window]
      Name=New Empty Window
      Exec={{HOMEBREW_PREFIX}}/bin/code-insiders --new-window %F
      Icon={{staged_path}}/vscode-insiders/resources/app/resources/linux/code.png
    EOS
    write_file "code-insiders-url-handler.desktop", <<~EOS
      [Desktop Entry]
      Name=Visual Studio Code Insiders - URL Handler
      Comment=Code Editing. Redefined.
      GenericName=Text Editor
      Exec={{HOMEBREW_PREFIX}}/bin/code-insiders --open-url %U
      Icon={{staged_path}}/vscode-insiders/resources/app/resources/linux/code.png
      Type=Application
      NoDisplay=true
      StartupNotify=true
      Categories=Utility;TextEditor;Development;IDE;
      MimeType=x-scheme-handler/vscode-insiders;
      Keywords=vscode;
    EOS
    run "/bin/mv",
        args: ["{{staged_path}}/code-insiders.desktop", "{{staged_path}}/code-insiders-url-handler.desktop",
               "{{staged_path}}/vscode-insiders/"]
  end

  zap trash: [
    "~/.config/Code - Insiders",
    "~/.vscode-insiders",
  ]
end
