cask "antigravity-linux" do
  arch arm: "arm", intel: "x64"
  arch_dir = on_arch_conditional arm: "arm64", intel: "x64"
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

  binary "#{staged_path}/Antigravity-#{arch_dir}/antigravity"
  artifact "antigravity.desktop",
           target: "#{Dir.home}/.local/share/applications/antigravity.desktop"
  artifact "antigravity-url-handler.desktop",
           target: "#{Dir.home}/.local/share/applications/antigravity-url-handler.desktop"
  artifact "antigravity.png",
           target: "#{Dir.home}/.local/share/icons/hicolor/512x512/apps/antigravity.png"

  preflight_steps do
    run "ruby", args: [
      "-e",
      <<~RUBY,
        require "json"
        require "fileutils"
        staged = ARGV[0]
        app_root = Dir.glob("\#{staged}/Antigravity-*").first
        if app_root
          app_update_yml = "\#{app_root}/resources/app-update.yml"
          FileUtils.rm_f(app_update_yml)

          asar_path = "\#{app_root}/resources/app.asar"
          if File.exist?(asar_path)
            File.open(asar_path, "rb") do |asar|
              asar.seek(8)
              padded_size = asar.read(4).unpack1("V") - 4
              asar.seek(12)
              true_size = asar.read(4).unpack1("V")
              asar.seek(16)
              header = JSON.parse(asar.read(true_size))
              icon_entry = header.dig("files", "icon.png")

              if icon_entry
                asar.seek(16 + padded_size + icon_entry["offset"].to_i)
                File.binwrite("\#{staged}/antigravity.png", asar.read(icon_entry["size"]))
              end
            end
          end
        end

        FileUtils.touch("\#{staged}/antigravity.png") unless File.exist?("\#{staged}/antigravity.png")
      RUBY
      "{{staged_path}}",
    ]

    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons/hicolor/512x512/apps", base: :home

    write_file "antigravity.desktop", <<~EOS
      [Desktop Entry]
      Name=Antigravity
      Comment=Agent orchestration platform
      GenericName=AI Agent Platform
      Exec="{{HOMEBREW_PREFIX}}/bin/antigravity" %F
      Icon={{home}}/.local/share/icons/hicolor/512x512/apps/antigravity.png
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
      Icon={{home}}/.local/share/icons/hicolor/512x512/apps/antigravity.png
      Type=Application
      NoDisplay=true
      Terminal=false
      StartupNotify=true
      StartupWMClass=Antigravity
      Categories=Utility;Development;
      MimeType=x-scheme-handler/antigravity;
      Keywords=antigravity;
    EOS
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
