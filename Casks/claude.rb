cask "claude" do
  arch arm: "arm64", intel: "amd64"

  on_macos do
    version "6.6395.1,8fc566f7b97e371bae421fc79c260de86c6a4106"
    sha256 "eaf23d2e65a6302c76aa180682d1c61ed4bf7adaead95b4cfa46eada96145467"

    url "https://downloads.claude.ai/releases/darwin/universal/#{version.csv.first}/Claude-#{version.csv.second}.zip"

    livecheck do
      url "https://downloads.claude.ai/releases/darwin/universal/RELEASES.json"
      regex(%r{/(\d+(?:\.\d+)+)/Claude[._-](\h+)\.zip}i)
      strategy :json do |json, regex|
        json["releases"]&.map do |release|
          match = release.dig("updateTo", "url")&.match(regex)
          next if match.blank?

          "#{match[1]},#{match[2]}"
        end
      end
    end

    auto_updates true
    depends_on macos: :ventura

    app "Claude.app"

    uninstall quit: [
      "com.anthropic.claudefordesktop",
      "com.anthropic.claudefordesktop.helper",
    ]

    zap trash: [
      "~/Library/Application Support/Claude",
      "~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/com.anthropic.claudefordesktop.sfl*",
      "~/Library/Caches/com.anthropic.claudefordesktop",
      "~/Library/Caches/com.anthropic.claudefordesktop.ShipIt",
      "~/Library/HTTPStorages/com.anthropic.claudefordesktop",
      "~/Library/Logs/Claude",
      "~/Library/Preferences/com.anthropic.claudefordesktop.plist",
      "~/Library/Saved Application State/com.anthropic.claudefordesktop.savedState",
    ]
  end
  on_linux do
    version "5.11492.5"
    sha256 arm64_linux:  "fe6cd8a70f96b96eb4e6b647300cfaee6aaff4ce133a0fbbe11c2cdb775f5a6a",
           x86_64_linux: "b96208b207e450b740f7dbe304f6077fed80e7f3d37ddd545991c4e8201564cf"

    url "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_#{version}_#{arch}.deb"

    livecheck do
      url "https://downloads.claude.ai/claude-desktop/apt/stable/dists/stable/main/binary-amd64/Packages"
      regex(%r{^Filename:\s*pool/main/c/claude-desktop/claude-desktop[._-]v?(\d+(?:\.\d+)+)[._-]amd64\.deb}i)
    end

    depends_on formula: "libarchive"

    binary "usr/lib/claude-desktop/claude-desktop"
    artifact "usr/share/applications/com.anthropic.Claude.desktop",
             target: "#{Dir.home}/.local/share/applications/com.anthropic.Claude.desktop"
    artifact "usr/share/icons/hicolor/256x256/apps/claude-desktop.png",
             target: "#{Dir.home}/.local/share/icons/hicolor/256x256/apps/claude-desktop.png"

    preflight_steps do
      # The download is a Debian package: an ar archive wrapping data.tar.xz.
      run "{{HOMEBREW_PREFIX}}/bin/bsdtar",
          args:  ["-xf", "claude-desktop_{{version}}_{{arch}}.deb", "data.tar.xz"],
          chdir: "."
      run "{{HOMEBREW_PREFIX}}/bin/bsdtar", args: ["-xf", "data.tar.xz"], chdir: "."
      remove ["claude-desktop_{{version}}_{{arch}}.deb", "data.tar.xz"]
      # Launchers may not have Homebrew's bin directory on their PATH.
      inreplace "usr/share/applications/com.anthropic.Claude.desktop",
                "Exec=claude-desktop", "Exec={{HOMEBREW_PREFIX}}/bin/claude-desktop"
      mkdir_p ".local/share/applications", base: :home
      mkdir_p ".local/share/icons/hicolor/256x256/apps", base: :home
    end

    zap trash: [
      "~/.cache/Claude",
      "~/.config/Claude",
    ]
  end

  name "Claude"
  desc "Anthropic's official Claude AI desktop app"
  homepage "https://claude.com/download"
end
