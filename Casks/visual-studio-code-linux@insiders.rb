cask "visual-studio-code-linux@insiders" do
  arch arm: "arm64", intel: "x64"
  os linux: "linux"

  version "1.133.0-insider,f4850e0faa6aaab8894a7c08f56891c6cd2ec1f6"
  sha256 arm:          "c78261c0471c954e2c71d0c6c187f17c2e15c30ca358296a7985270e30f21626",
         intel:        "f8c6c812843e02cfd4367203417f3f9e34bad6349644e93d986794e066cd5493",
         arm64_linux:  "c78261c0471c954e2c71d0c6c187f17c2e15c30ca358296a7985270e30f21626",
         x86_64_linux: "f8c6c812843e02cfd4367203417f3f9e34bad6349644e93d986794e066cd5493"

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

  binary "VSCode-linux-#{arch}/bin/code-insiders"
  binary "VSCode-linux-#{arch}/bin/code-tunnel-insiders"
  bash_completion "#{staged_path}/VSCode-linux-#{arch}/resources/completions/bash/code-insiders"
  zsh_completion  "#{staged_path}/VSCode-linux-#{arch}/resources/completions/zsh/_code-insiders"
  artifact "VSCode-linux-#{arch}/code-insiders.desktop",
           target: "#{Dir.home}/.local/share/applications/code-insiders.desktop"
  artifact "VSCode-linux-#{arch}/code-insiders-url-handler.desktop",
           target: "#{Dir.home}/.local/share/applications/code-insiders-url-handler.desktop"

  preflight do
    # Disable VS Code's built-in update checks; Homebrew manages this install.
    product_json = "#{staged_path}/VSCode-linux-#{arch}/resources/app/product.json"
    product = JSON.parse(File.read(product_json))
    product.delete("updateUrl")
    product["configurationDefaults"] ||= {}
    product["configurationDefaults"]["update.mode"] = "none"
    File.write(product_json, JSON.pretty_generate(product))

    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    File.write("#{staged_path}/VSCode-linux-#{arch}/code-insiders.desktop", <<~EOS)
      [Desktop Entry]
      Name=Visual Studio Code - Insiders
      Comment=Code Editing. Redefined.
      GenericName=Text Editor
      Exec=#{HOMEBREW_PREFIX}/bin/code-insiders %F
      Icon=#{staged_path}/VSCode-linux-#{arch}/resources/app/resources/linux/code.png
      Type=Application
      StartupNotify=false
      StartupWMClass=Code - Insiders
      Categories=TextEditor;Development;IDE;
      MimeType=application/x-code-workspace;
      Actions=new-empty-window;
      Keywords=vscode;

      [Desktop Action new-empty-window]
      Name=New Empty Window
      Exec=#{HOMEBREW_PREFIX}/bin/code-insiders --new-window %F
      Icon=#{staged_path}/VSCode-linux-#{arch}/resources/app/resources/linux/code.png
    EOS
    File.write("#{staged_path}/VSCode-linux-#{arch}/code-insiders-url-handler.desktop", <<~EOS)
      [Desktop Entry]
      Name=Visual Studio Code Insiders - URL Handler
      Comment=Code Editing. Redefined.
      GenericName=Text Editor
      Exec=#{HOMEBREW_PREFIX}/bin/code-insiders --open-url %U
      Icon=#{staged_path}/VSCode-linux-#{arch}/resources/app/resources/linux/code.png
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
