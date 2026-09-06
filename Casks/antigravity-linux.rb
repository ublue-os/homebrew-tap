cask "antigravity-linux" do
  arch arm: "arm", intel: "x64"
  os linux: "linux"

  version "2.12.2,6298742303883264"
  sha256 arm:          "72049b207d1c179a8524a4dcf13c4f86d8cbba599d845fdc457de0f7f112e918",
         intel:        "fc2e2af49a45aefee9558bce56aaa4bbde00d560d354357af1b834a9dd43cd33",
         arm64_linux:  "72049b207d1c179a8524a4dcf13c4f86d8cbba599d845fdc457de0f7f112e918",
         x86_64_linux: "fc2e2af49a45aefee9558bce56aaa4bbde00d560d354357af1b834a9dd43cd33"

  url "https://storage.googleapis.com/antigravity-public/antigravity-hub/#{version.csv.first}-#{version.csv.second}/linux-#{arch}/Antigravity.tar.gz"
  name "Google Antigravity"
  desc "Agent orchestration platform"
  homepage "https://antigravity.google/product/antigravity-2"

  livecheck do
    url "https://antigravity-hub-auto-updater-974169037036.us-central1.run.app/manifest/latest-x64-linux.yml"
    regex(%r{/antigravity-hub/(\d+(?:\.\d+)+)-(\d+)/}i)
    strategy :page_match do |page, regex|
      match = page.match(regex)
      next if match.blank?

      "#{match[1]},#{match[2]}"
    end
  end

  depends_on formula: "jq"

  binary "Antigravity/antigravity"
  artifact "antigravity.desktop",
           target: "#{Dir.home}/.local/share/applications/antigravity.desktop"
  artifact "antigravity-url-handler.desktop",
           target: "#{Dir.home}/.local/share/applications/antigravity-url-handler.desktop"
  artifact "antigravity.png",
           target: "#{Dir.home}/.local/share/icons/hicolor/512x512/apps/antigravity.png"

  preflight_steps do
    move "Antigravity-*", "Antigravity", source_glob: true
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons/hicolor/512x512/apps", base: :home
    remove "Antigravity/resources/app-update.yml"

    # ASAR uses little-endian 32-bit pickle lengths on both supported Linux CPUs.
    if_path_exists "Antigravity/resources/app.asar" do
      run "/bin/bash", chdir: "{{staged_path}}", env: { "JQ" => "{{HOMEBREW_PREFIX}}/bin/jq" },
                       args: ["-euo", "pipefail", "-c", <<~'SH']
                         asar=Antigravity/resources/app.asar
                         header_size=$(od -An -tu4 -j4 -N4 "$asar" | tr -d '[:space:]')
                         json_size=$(od -An -tu4 -j12 -N4 "$asar" | tr -d '[:space:]')
                         dd if="$asar" of=asar-header.json bs=64K iflag=skip_bytes,count_bytes skip=16 count="$json_size" status=none
                         if "$JQ" -e '.files["icon.png"] != null' asar-header.json >/dev/null; then
                           offset=$("$JQ" -er '.files["icon.png"].offset | tonumber' asar-header.json)
                           size=$("$JQ" -er '.files["icon.png"].size' asar-header.json)
                           [[ "$offset" =~ ^[0-9]+$ && "$size" =~ ^[0-9]+$ ]]
                           dd if="$asar" of=antigravity.png bs=64K iflag=skip_bytes,count_bytes \
                             skip="$((8 + header_size + offset))" count="$size" status=none
                         fi
                       SH
      remove "asar-header.json"
    end

    write_file "antigravity.desktop", <<~EOS
      [Desktop Entry]
      Name=Antigravity
      Comment=Agent orchestration platform
      GenericName=AI Agent Platform
      Exec="{{HOMEBREW_PREFIX}}/bin/antigravity" %F
      Icon=antigravity
      Type=Application
      StartupNotify=false
      StartupWMClass=Antigravity
      Categories=Development;Utility;
      Keywords=antigravity;agent;ai;
    EOS

    write_file "antigravity-url-handler.desktop", <<~EOS
      [Desktop Entry]
      Name=Antigravity - URL Handler
      Comment=Agent orchestration platform
      GenericName=AI Agent Platform
      Exec="{{HOMEBREW_PREFIX}}/bin/antigravity" "%U"
      Icon=antigravity
      Type=Application
      NoDisplay=true
      Terminal=false
      StartupNotify=true
      StartupWMClass=Antigravity
      Categories=Utility;Development;
      MimeType=x-scheme-handler/antigravity;
      Keywords=antigravity;
    EOS

    # Create a placeholder icon if extraction fails
    unless_path_exists "antigravity.png" do
      touch "antigravity.png"
    end
  end

  zap trash: [
    "~/.antigravity",
    "~/.config/Antigravity",
    "~/.config/antigravity",
    "~/.gemini/antigravity",
  ]

  caveats <<~EOS
    If authentication fails or the browser doesn't open Antigravity, try running:
      xdg-mime default antigravity-url-handler.desktop x-scheme-handler/antigravity
      update-desktop-database ~/.local/share/applications
  EOS
end
