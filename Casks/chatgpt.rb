cask "chatgpt" do
  arch arm: "arm64", intel: "x64"

  on_macos do
    livecheck_arch = on_arch_conditional intel: "-x64"

    version "26.1111.71025"
    sha256 arm:   "7edb7f133e41d947a9e11826f3669fd32be2ff6c6bbdaa01e40eb41b9e39e957",
           intel: "c7ebb225169be945fe27c2d9d51547dfa77d58a97b0b81d5c5e814f3925a82d5"

    url "https://persistent.oaistatic.com/codex-app-prod/ChatGPT-darwin-#{arch}-#{version}.zip"

    livecheck do
      url "https://persistent.oaistatic.com/codex-app-prod/appcast#{livecheck_arch}.xml"
      strategy :sparkle, &:short_version
    end

    auto_updates true
    depends_on macos: :ventura

    app "ChatGPT.app"

    uninstall quit: "com.openai.codex"

    zap trash: [
          "/Library/Application Support/CodexComputerUseAuthorizationPlugin",
          "~/Library/Application Scripts/*.com.openai.sky.CUAService",
          "~/Library/Application Support/Codex",
          "~/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.ApplicationRecentDocuments/com.openai.codex.sfl*",
          "~/Library/Application Support/com.openai.codex",
          "~/Library/Application Support/OpenAI/Codex",
          "~/Library/Caches/Codex",
          "~/Library/Caches/com.openai.codex",
          "~/Library/Caches/com.openai.sky.CUAService",
          "~/Library/Group Containers/*.com.openai.sky.CUAService",
          "~/Library/HTTPStorages/com.openai.codex",
          "~/Library/HTTPStorages/com.openai.codex.binarycookies",
          "~/Library/HTTPStorages/com.openai.sky.CUAService",
          "~/Library/HTTPStorages/com.openai.sky.CUAService.binarycookies",
          "~/Library/Logs/com.openai.codex",
          "~/Library/Preferences/com.openai.codex.plist",
          "~/Library/Preferences/com.openai.sky.CUAService.cli.plist",
          "~/Library/Preferences/com.openai.sky.CUAService.plist",
          "~/Library/Saved Application State/com.openai.codex.savedState",
        ],
        rmdir: "~/.codex"
  end
  on_linux do
    deb_arch = on_arch_conditional arm: "arm64", intel: "amd64"

    version "26.1111.71704"
    sha256 arm64_linux:  "f0550dee1f99127d357ad760aef739c557d49bd67728d2f105d00a7a4780f740",
           x86_64_linux: "01eef7c77c835f7e1afb92ba1c29178a4c19d6c66573bdd3b86520e2abf806a4"

    url "https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt/chatgpt_#{version}_#{deb_arch}.deb"

    livecheck do
      url "https://persistent.oaistatic.com/codex-app-prod/linux/deb/dists/stable/main/binary-amd64/Packages"
      regex(%r{^Filename:\s*pool/main/c/chatgpt/chatgpt[._-]v?(\d+(?:\.\d+)+)[._-]amd64\.deb}i)
    end

    depends_on formula: "libarchive"

    binary "usr/lib/chatgpt/codex-launcher", target: "chatgpt"
    artifact "usr/share/applications/chatgpt.desktop",
             target: "#{Dir.home}/.local/share/applications/chatgpt.desktop"
    artifact "usr/share/pixmaps/chatgpt.png",
             target: "#{Dir.home}/.local/share/icons/chatgpt.png"

    preflight_steps do
      # The download is a Debian package: an ar archive wrapping data.tar.xz.
      move "chatgpt_{{version}}_*.deb", "chatgpt.deb", source_glob: true
      run "{{HOMEBREW_PREFIX}}/bin/bsdtar", args: ["-xf", "chatgpt.deb", "data.tar.xz"], chdir: "."
      run "{{HOMEBREW_PREFIX}}/bin/bsdtar", args: ["-xf", "data.tar.xz"], chdir: "."
      remove ["chatgpt.deb", "data.tar.xz"]
      # Launchers may not have Homebrew's bin directory on their PATH.
      inreplace "usr/share/applications/chatgpt.desktop",
                "Exec=chatgpt", "Exec={{HOMEBREW_PREFIX}}/bin/chatgpt"
      mkdir_p ".local/share/applications", base: :home
      mkdir_p ".local/share/icons", base: :home
    end

    zap trash: [
      "~/.cache/Codex",
      "~/.config/Codex",
    ]
  end

  name "ChatGPT"
  desc "OpenAI's official ChatGPT desktop app"
  homepage "https://chatgpt.com/"
end
