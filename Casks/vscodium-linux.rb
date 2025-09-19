cask "vscodium-linux" do
  arch arm: "arm64", intel: "x64"
  os linux: "linux"

  version "1.104.06131"
  sha256 arm64_linux:  "ad7e699baa2c2d8fa46f58139574f2442c65f9595d1da539065ba03c732b9b55",
         x86_64_linux: "0cec2a781025d363ace683551742b2cd436086bb9cb3c7ee2fa68ce8f2f3e74e"

  url "https://github.com/VSCodium/vscodium/releases/download/#{version}/VSCodium-linux-#{arch}-#{version}.tar.gz"
  name "VSCodium"
  desc "Open-source code editor"
  homepage "https://vscodium.com/"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true

  binary "bin/codium"
  binary "bin/codium-tunnel"
  bash_completion "resources/completions/bash/codium"
  zsh_completion  "resources/completions/zsh/_codium"

preflight do
  applications_dir = "#{Dir.home}/.local/share/applications"
  icons_dir = "#{Dir.home}/.local/share/icons"

  FileUtils.mkdir_p(applications_dir)
  FileUtils.mkdir_p(icons_dir)

  FileUtils.cp("#{staged_path}/resources/app/resources/linux/code.png","#{icons_dir}/vscodium.png")
  File.write("#{applications_dir}/codium.desktop", <<~EOS)
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
  File.write("#{applications_dir}/codium-url-handler.desktop", <<~EOS)
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

  # zap trash: [
  #   "#{ENV["HOME"]}/.config/Code",
  #   "#{ENV["HOME"]}/.vscode",
  # ]
end
