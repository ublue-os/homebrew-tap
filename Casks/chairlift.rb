cask "chairlift" do
  arch arm: "arm64", intel: "amd64"

  version "0.11.1"
  sha256 arm:          "7c3d4461bad3a3ff438709d6ee98c98d680ef3f92ddbb3d204e953de538fccd2",
         intel:        "dc153fe97661bb4a8db2e20353a5cb60290a45d99017df0dc83e58d075713360",
         arm64_linux:  "7c3d4461bad3a3ff438709d6ee98c98d680ef3f92ddbb3d204e953de538fccd2",
         x86_64_linux: "dc153fe97661bb4a8db2e20353a5cb60290a45d99017df0dc83e58d075713360"

  url "https://github.com/frostyard/chairlift/releases/download/v#{version}/chairlift_#{version}_linux_#{arch}.tar.gz"
  name "ChairLift"
  desc "System management tool for bootc-based installations"
  homepage "https://github.com/frostyard/chairlift"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on :linux

  binary "chairlift"
  binary "data/chairlift-wrapper.sh", target: "chairlift-wrapper"

  preflight_steps do
    # Menu launches need the brew environment even when the session PATH lacks it.
    inreplace "data/chairlift-wrapper.sh", "/home/linuxbrew/.linuxbrew/bin/brew", "{{HOMEBREW_PREFIX}}/bin/brew"
    inreplace "data/chairlift-wrapper.sh", "$BREW_PATH shellenv", "\"$BREW_PATH\" shellenv bash"
    inreplace "data/chairlift-wrapper.sh", "exec chairlift", "exec \"{{HOMEBREW_PREFIX}}/bin/chairlift\""
    inreplace "data/org.frostyard.ChairLift.desktop", "Exec=chairlift-wrapper",
              "Exec=\"{{HOMEBREW_PREFIX}}/bin/chairlift-wrapper\""
  end

  postflight_steps do
    mkdir_p ".local/share/applications", base: :home
    mkdir_p ".local/share/icons/hicolor/scalable/apps", base: :home
    mkdir_p ".local/share/icons/hicolor/symbolic/apps", base: :home
    copy "data/org.frostyard.ChairLift.desktop", ".local/share/applications/org.frostyard.ChairLift.desktop",
         target_base: :home
    copy "data/icons/hicolor/scalable/apps/org.frostyard.ChairLift.svg",
         ".local/share/icons/hicolor/scalable/apps/org.frostyard.ChairLift.svg", target_base: :home
    copy "data/icons/hicolor/scalable/apps/org.frostyard.ChairLift-flower.svg",
         ".local/share/icons/hicolor/scalable/apps/org.frostyard.ChairLift-flower.svg", target_base: :home
    copy "data/icons/hicolor/symbolic/apps/org.frostyard.ChairLift-symbolic.svg",
         ".local/share/icons/hicolor/symbolic/apps/org.frostyard.ChairLift-symbolic.svg", target_base: :home
  end

  uninstall_postflight_steps do
    remove [".local/share/applications/org.frostyard.ChairLift.desktop",
            ".local/share/icons/hicolor/scalable/apps/org.frostyard.ChairLift.svg",
            ".local/share/icons/hicolor/scalable/apps/org.frostyard.ChairLift-flower.svg",
            ".local/share/icons/hicolor/symbolic/apps/org.frostyard.ChairLift-symbolic.svg"], base: :home
  end

  # Never link the privileged helper or install PolicyKit policies from a user-writable cask.
  caveats <<~EOS
    ChairLift requires GTK 4 and libadwaita 1 shared libraries from your OS.

    Privileged features require the matching frostyard-chairlift-system-integration
    package from https://github.com/frostyard/chairlift/releases installed by your
    OS administrator or included in your OS image. This cask installs only the GUI
    and desktop assets, not the root-owned helper or PolicyKit policies.
    Bootc staging additionally requires /usr/libexec/bootc-update-stage from your OS.

    Distribution configuration belongs in /etc/chairlift/config.yml; this cask
    does not overwrite it. Upstream's bundled defaults target Snow Linux.

    If the launcher or icons need refreshing after installation or removal, run:
      gtk-update-icon-cache ~/.local/share/icons/hicolor -f -t
      update-desktop-database ~/.local/share/applications
  EOS
end
