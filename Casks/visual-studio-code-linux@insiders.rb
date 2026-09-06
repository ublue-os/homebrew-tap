cask "visual-studio-code-linux@insiders" do
  arch arm: "arm64", intel: "x64"
  os linux: "linux"

  version "1.137.0-insider,1f625adb84abf41cdff31f40f66e58a222f033f6"
  sha256 arm:          "0bd989f051f0faed32baede6014387fe5a8a5cf711beea39c0b4d55ad62bc053",
         intel:        "dace879714aa1be6e722de574bb1ab4b43505fd1c373d39e8cc116c9f83a2f82",
         arm64_linux:  "0bd989f051f0faed32baede6014387fe5a8a5cf711beea39c0b4d55ad62bc053",
         x86_64_linux: "dace879714aa1be6e722de574bb1ab4b43505fd1c373d39e8cc116c9f83a2f82"

  url "https://update.code.visualstudio.com/#{version.csv.first}/linux-#{arch}/insider"
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
    move "product.json", "vscode-insiders/resources/app/product.json"

    mkdir_p ".local/share/applications", base: :home
    write_file "vscode-insiders/code-insiders.desktop", <<~EOS
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
    write_file "vscode-insiders/code-insiders-url-handler.desktop", <<~EOS
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
  end

  zap trash: [
    "~/.config/Code - Insiders",
    "~/.vscode-insiders",
  ]
end
