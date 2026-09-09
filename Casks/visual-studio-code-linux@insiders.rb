cask "visual-studio-code-linux@insiders" do
  arch arm: "arm64", intel: "x64"
  os linux: "linux"

  version "1.137.0-insider,645f29cc3176500b4b5762ba887cf2a7f0ffdf2c"
  sha256 arm:          "a9df2b64ff5c392453cf34eb2d2e01eeb073fac5e70c0a8aae979985035dc37b",
         intel:        "0ad25f84d8c1d1c11e27c69cf40c57a2d33f78b572ddcd4e296866d66258dd32",
         arm64_linux:  "a9df2b64ff5c392453cf34eb2d2e01eeb073fac5e70c0a8aae979985035dc37b",
         x86_64_linux: "0ad25f84d8c1d1c11e27c69cf40c57a2d33f78b572ddcd4e296866d66258dd32"

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
