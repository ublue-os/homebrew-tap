cask "zed-linux" do
  version "1.23.3"
  sha256 "f7191294295699bb5ac810a4c50f8290ad3d0191c3e506114fb14a7236921a61"

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
    # Prepare the launcher in the readable stage, then only write to the user's home.
    run "/bin/sed", args:        ["-e", "s|^TryExec=.*|TryExec={{HOMEBREW_PREFIX}}/bin/zed|",
                                  "-e", "s|^Exec=zed|Exec={{HOMEBREW_PREFIX}}/bin/zed|",
                                  "-e", "s|^Icon=.*|Icon=zed|",
                                  "{{staged_path}}/zed.app/share/applications/dev.zed.Zed.desktop"],
                    stdout_path: "dev.zed.Zed.desktop"
    copy "dev.zed.Zed.desktop", ".local/share/applications/dev.zed.Zed.desktop", target_base: :home
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
