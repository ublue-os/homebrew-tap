cask "zed-linux" do
  version "1.18.1"
  sha256 "eea62268d8ec5fd3587df06fa76e072c104cca5e0b0b0abecbc28ae5b87c0bad"

  url "https://github.com/zed-industries/zed/releases/download/v#{version}/zed-linux-x86_64.tar.gz"
  name "Zed"
  desc "High-performance, multiplayer code editor"
  homepage "https://zed.dev/"

  livecheck do
    url :url
    strategy :github_latest
  end

  binary "zed.app/bin/zed"

  postflight_steps do
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons", base: :home
    copy "zed.app/share/applications/dev.zed.Zed.desktop", ".local/share/applications/dev.zed.Zed.desktop",
         target_base: :home
    inreplace ".local/share/applications/dev.zed.Zed.desktop", /^TryExec=.*/, "TryExec={{HOMEBREW_PREFIX}}/bin/zed",
              base: :home
    inreplace ".local/share/applications/dev.zed.Zed.desktop", /^Exec=zed/, "Exec={{HOMEBREW_PREFIX}}/bin/zed",
              base: :home
    inreplace ".local/share/applications/dev.zed.Zed.desktop", /^Icon=.*/, "Icon=zed",
              base: :home
    copy "zed.app/share/icons/hicolor/512x512/apps/zed.png", ".local/share/icons/zed.png",
         target_base: :home
  end

  uninstall_postflight_steps do
    remove ".local/share/applications/dev.zed.Zed.desktop", base: :home
    remove ".local/share/icons/zed.png", base: :home
  end

  zap trash: [
    "#{ENV.fetch("XDG_CACHE_HOME", "#{Dir.home}/.cache")}/zed",
    "#{ENV.fetch("XDG_CONFIG_HOME", "#{Dir.home}/.config")}/zed",
    "#{ENV.fetch("XDG_DATA_HOME", "#{Dir.home}/.local/share")}/zed",
  ]
end
