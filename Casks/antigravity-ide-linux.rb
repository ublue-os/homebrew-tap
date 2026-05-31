cask "antigravity-ide-linux" do
  arch arm: "arm", intel: "x64"
  livecheck_arch = on_arch_conditional arm: "arm64", intel: "x64"
  os linux: "linux"

  version "2.0.3,6242596486512640"

  on_linux do
    sha256 arm64_linux:  "8ba7073c71f43c625fbfb95bd0b0c5c7d854974d5b4cc90f6e0fff4a109259ba",
           x86_64_linux: "00b5fd709fef02c9f81ab4edd77e8d5baf8b85842cc654fa016d7d0492cde803"
  end

  url "https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/#{version.csv.first}-#{version.csv.second}/linux-#{arch}/Antigravity%20IDE.tar.gz",
      verified: "edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/"
  name "Google Antigravity IDE"
  desc "AI Coding Agent IDE"
  homepage "https://antigravity.google/product/antigravity-ide"

  livecheck do
    url "https://antigravity-ide-auto-updater-974169037036.us-central1.run.app/api/update/linux-#{livecheck_arch}/stable/latest"
    regex(%r{/stable/([^/]+)/}i)
    strategy :json do |json, regex|
      match = json["url"]&.match(regex)
      next if match.blank?

      match[1]&.tr("-", ",").to_s
    end
  end

  binary "#{staged_path}/Antigravity IDE/bin/antigravity-ide"
  binary "#{staged_path}/Antigravity IDE/bin/antigravity-ide", target: "agy-ide"
  bash_completion "#{staged_path}/Antigravity IDE/resources/completions/bash/antigravity-ide"
  zsh_completion  "#{staged_path}/Antigravity IDE/resources/completions/zsh/_antigravity-ide"
  artifact "antigravity-ide.desktop",
           target: "#{Dir.home}/.local/share/applications/antigravity-ide.desktop"
  artifact "antigravity-ide-url-handler.desktop",
           target: "#{Dir.home}/.local/share/applications/antigravity-ide-url-handler.desktop"
  artifact "Antigravity IDE/resources/app/resources/linux/code.png",
           target: "#{Dir.home}/.local/share/icons/hicolor/512x512/apps/antigravity-ide.png"

  preflight do
    product_json = "#{staged_path}/Antigravity IDE/resources/app/product.json"
    if File.exist?(product_json)
      product = JSON.parse(File.read(product_json))
      product.delete("updateUrl")
      product["configurationDefaults"] ||= {}
      product["configurationDefaults"]["update.mode"] = "none"
      File.write(product_json, JSON.pretty_generate(product))
    end

    FileUtils.mkdir_p "#{Dir.home}/.local/share/applications"
    FileUtils.mkdir_p "#{Dir.home}/.local/share/icons/hicolor/512x512/apps"

    File.write("#{staged_path}/antigravity-ide.desktop", <<~EOS)
      [Desktop Entry]
      Name=Antigravity IDE
      Comment=AI Coding Agent IDE
      GenericName=Text Editor
      Exec="#{HOMEBREW_PREFIX}/bin/antigravity-ide" %F
      Icon=#{Dir.home}/.local/share/icons/hicolor/512x512/apps/antigravity-ide.png
      Type=Application
      StartupNotify=false
      StartupWMClass=Antigravity IDE
      Categories=TextEditor;Development;IDE;
      MimeType=text/plain;inode/directory;application/x-code-workspace;x-scheme-handler/antigravity-ide;
      Actions=new-empty-window;
      Keywords=antigravity;code;editor;ai;

      [Desktop Action new-empty-window]
      Name=New Empty Window
      Exec="#{HOMEBREW_PREFIX}/bin/antigravity-ide" --new-window %F
      Icon=#{Dir.home}/.local/share/icons/hicolor/512x512/apps/antigravity-ide.png
    EOS

    File.write("#{staged_path}/antigravity-ide-url-handler.desktop", <<~EOS)
      [Desktop Entry]
      Name=Antigravity IDE - URL Handler
      Comment=AI Coding Agent IDE
      GenericName=Text Editor
      Exec="#{HOMEBREW_PREFIX}/bin/antigravity-ide" --open-url "%U"
      Icon=#{Dir.home}/.local/share/icons/hicolor/512x512/apps/antigravity-ide.png
      Type=Application
      NoDisplay=true
      Terminal=false
      StartupNotify=true
      StartupWMClass=Antigravity IDE
      Categories=Utility;TextEditor;Development;IDE;
      MimeType=x-scheme-handler/antigravity-ide;
      Keywords=antigravity;code;editor;ai;
    EOS
  end

  zap trash: [
    "~/.antigravity-ide",
    "~/.antigravity-ide-server",
    "~/.config/Antigravity IDE",
    "~/.config/antigravity-ide",
    "~/.gemini/antigravity-ide",
  ]

  caveats <<~EOS
    If authentication fails or the browser doesn't open Antigravity IDE, try running:
      xdg-mime default antigravity-ide-url-handler.desktop x-scheme-handler/antigravity-ide
      update-desktop-database ~/.local/share/applications
  EOS
end
